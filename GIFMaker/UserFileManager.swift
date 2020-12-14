//
//  UserFileManager.swift
//  GIFMaker
//
//  Created by Josh Kowarsky on 12/13/20.
//

import Combine
import SwiftUI

class UserFileManager: ObservableObject {
    @Published var inputURL: URL?
    @Published var outputURL: URL?

    @Published var inputString: String = ""
    @Published var outputString: String = ""

    @Published var processing: Bool = false

    private var bag = Set<AnyCancellable>()

    func openPanelForFile() {
        let op = NSOpenPanel()
        op.canChooseFiles = true
        op.begin { [weak self] response in
            switch(response) {
            case .OK:
                guard let url = op.url else { return }
                DispatchQueue.main.async {
                    self?.inputURL = url
                    self?.inputString = url.absoluteString
                }
            default:
                print("Default behavior")
            }
        }
    }

    func openPanelForFolder() {
        let op = NSOpenPanel()
        op.canChooseFiles = false
        op.canChooseDirectories = true
        op.begin { [weak self] response in
            switch(response) {
            case .OK:
                guard let url = op.url else { return }
                DispatchQueue.main.async {
                    self?.outputURL = url
                    self?.outputString = url.absoluteString
                }
            default:
                print("Default behavior")
            }
        }
    }

    func handle(dropInfo: DropInfo) {
        let items = dropInfo.itemProviders(for: [.fileURL])
        for item in items {
            for identifier in item.registeredTypeIdentifiers {
                item.loadItem(forTypeIdentifier: identifier, options: nil) { [weak self] (item, error) in
                    guard let data = item as? Data else { return }
                    guard let url = URL(dataRepresentation: data, relativeTo: nil, isAbsolute: true) else { return }
                    DispatchQueue.main.async {
                        self?.inputURL = url
                        self?.inputString = url.absoluteString
                    }
                }
            }
        }
    }

    func begin() {
        guard let url = inputURL else { return }
        processing = true
        let ffmpeg = FFMpeg(inputURL: url, outputURL: outputURL)
        ffmpeg
            .begin()
            .receive(on: RunLoop.main)
            .sink { _ in
                self.processing = false
            } receiveValue: { _ in
                //
            }
            .store(in: &bag)
    }
}
