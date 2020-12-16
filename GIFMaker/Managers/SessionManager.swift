//
//  SessionManager.swift
//  GIFMaker
//
//  Created by Josh Kowarsky on 12/13/20.
//

import AVFoundation
import Combine
import SwiftUI

enum GIFDimensions: String, Identifiable, CaseIterable {
    case small
    case medium
    case large

    var value: Int {
        switch self {
        case .small:
            return 320
        case .medium:
            return 720
        case .large:
            return 1080
        }
    }

    var id: Int {
        return value
    }
}

enum FPS: Identifiable, CaseIterable {
    case low
    case medium
    case high

    var value: Int {
        switch self {
        case .low:
            return 10
        case .medium:
            return 15
        case .high:
            return 30
        }
    }

    var id: Int {
        return value
    }
}

class SessionManager: NSObject, ObservableObject {
    @Published var inputURL: URL?
    @Published var outputURL: URL?
    @Published var dimensions: GIFDimensions = .small
    @Published var fps: FPS = .high
    @Published var processing: Bool = false

    private var bag = Set<AnyCancellable>()

    var inputString: String? {
        get {
            return inputURL?.path
        }
        set {
            inputURL = URL(string: newValue ?? "")
        }
    }

    var outputString: String? {
        get {
            return outputURL?.path
        }
        set {
            outputURL = URL(string: newValue ?? "")
        }
    }

    func performDrop(_ info: DropInfo) {
        SaveOpenManager
            .handle(dropInfo: info)
            .receive(on: RunLoop.main)
            .sink { [weak self] fileInfo in
                self?.inputURL = fileInfo?.url
            }
            .store(in: &bag)
    }

    func openFile() {
        SaveOpenManager
            .openFile()
            .receive(on: RunLoop.main)
            .sink { [weak self] fileInfo in
                self?.inputURL = fileInfo?.url
            }
            .store(in: &bag)
    }

    func saveFile() {
        SaveOpenManager
            .saveFile()
            .receive(on: RunLoop.main)
            .sink { [weak self] url in
                self?.outputURL = url
            }
            .store(in: &bag)
    }

    func begin() {
        guard let url = inputURL else { return }
        processing = true
        let ffmpeg = FFMpeg(inputURL: url, outputURL: outputURL, fps: fps.value, scale: dimensions.value)
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
