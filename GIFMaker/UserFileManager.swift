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

    var inputString: String {
        get {
            return inputURL?.absoluteString ?? ""
        }
        set {
            inputURL = URL(string: newValue)
        }
    }
    var outputString: String {
        get {
            return outputURL?.absoluteString ?? ""
        }
        set {
            outputURL = URL(string: newValue)
        }
    }

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
            .handleEvents(receiveCancel: {
                self.processing = false
            })
            .sink { _ in
                self.processing = false
            } receiveValue: { _ in
                //
            }
            .store(in: &bag)
    }

    func cancel() {
        bag.removeAll()
    }
}
