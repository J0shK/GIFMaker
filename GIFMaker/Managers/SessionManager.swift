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
    @Published var inputFile: FileInfo?
    @Published var outputURL: URL?
    @Published var dimensions: GIFDimensions = .small
    @Published var fps: FPS = .high
    @Published var processing: Bool = false
    @Published var stage: FFMpeg.Output.Stage = .none
    @Published var progress: CGFloat = 0
    @Published var advancedMode: Bool = false
    var scene = GameScene()
    private var ffmpeg: FFMpeg?
    private var bag = Set<AnyCancellable>()

    override init() {
        super.init()
        _processing
            .projectedValue
            .sink { [scene] processing in
                if processing {
                    scene.beginPopping(size: .large)
                } else {
                    scene.stopPopping()
                }
            }
            .store(in: &bag)

        _inputFile
            .projectedValue
            .sink { [weak self] fileInfo in
                guard let self = self else { return }
                if let url = fileInfo?.url {
                    if self.advancedMode {
                        self.scene.beginPopping(size: .small)
                    } else {
                        self.begin(with: url)
                    }
                } else {
                    self.scene.stopPopping()
                }
            }
            .store(in: &bag)
    }

    var inputPath: String? {
        get {
            return inputFile?.url.path
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
                self?.inputFile = fileInfo
            }
            .store(in: &bag)
    }

    func openFile() {
        SaveOpenManager
            .openFile()
            .receive(on: RunLoop.main)
            .sink { [weak self] fileInfo in
                self?.inputFile = fileInfo
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

    func begin(with url: URL) {
        guard let outputURL = outputURL else {
            SaveOpenManager
                .saveFile()
                .receive(on: RunLoop.main)
                .sink { [weak self] outputURL in
                    guard let outputURL = outputURL else { return }
                    self?.outputURL = outputURL
                    self?.begin(with: url)
                }
                .store(in: &bag)
            return
        }
        processing = true

        ffmpeg = FFMpeg(
            inputURL: url,
            outputURL: outputURL,
            fps: fps.value,
            scale: dimensions.value
        )

        ffmpeg?
            .subject
            .receive(on: RunLoop.main)
            .handleEvents(receiveCancel: {
                self.processing = false
                self.progress = 0
                self.stage = .none
            })
            .sink { completion in
                switch(completion) {
                case .failure(let error):
                    print(error)
                case .finished:
                    print("Session: Receive finished")
                    break
                }
                self.processing = false
                self.progress = 0
                self.stage = .none
            } receiveValue: { output in
                self.stage = output?.stage ?? .none
                guard let videoInfo = self.inputFile?.videoInfo else { return }
                let duration = CMTimeGetSeconds(videoInfo.duration)
                let outTimeMs = Double(output?.outTimeMs ?? "0") ?? 0
                let outTimeSeconds = outTimeMs / 1000000
                let progressPerc = outTimeSeconds / duration
                self.progress = CGFloat(progressPerc)
            }
            .store(in: &bag)

        ffmpeg?.begin()
    }

    func cancel() {
        bag.removeAll()
    }
}
