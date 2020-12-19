//
//  FFMpeg.swift
//  GIFMaker
//
//  Created by Josh Kowarsky on 12/12/20.
//

import Combine
import Foundation

class FFMpeg {
    private let launchPath = Bundle.main.path(forResource: "ffmpeg", ofType: "")!

    private var pass1: Terminal?
    private var pass2: Terminal?

    private let inputURL: URL
    private let paletteOutputURL: URL
    private let outputURL: URL

    private let fps: Int
    private let scale: Int

    private let flags = "lanczos,palettegen"
    private let flags2 = "lanczos[x];[x][1:v]paletteuse"

    private let subject = PassthroughSubject<Output?, Error>()
    private var bag = Set<AnyCancellable>()

    var publisher: AnyPublisher<Output?, Error> {
        return subject
            .handleEvents(receiveSubscription: { _ in
                self.begin()
            }, receiveCancel: {
                self.bag.removeAll()
                self.cleanup()
            })
            .eraseToAnyPublisher()
    }

    private var pass1Filters: String {
        return "fps=\(fps),scale=\(scale):-1:flags=\(flags)"
    }

    private var pass2Filters: String {
        return "fps=\(fps),scale=\(scale):-1:flags=\(flags2)"
    }

    private var pass1Arguments: [String] {
        return [
            "-y",
            "-progress", "pipe:1",
            "-i", inputURL.absoluteString,
            "-vf", pass1Filters,
            paletteOutputURL.absoluteString
        ]
    }

    private var pass2Arguments: [String] {
        return [
            "-y",
            "-progress", "pipe:1",
            "-i", inputURL.absoluteString,
            "-i", paletteOutputURL.absoluteString,
            "-filter_complex", pass2Filters,
            outputURL.absoluteString
        ]
    }

    private static var tempDirectoryURL: URL {
        let fm = FileManager.default
        return fm.urls(for: .cachesDirectory, in: .userDomainMask).first!
    }

    init(inputURL: URL, outputURL: URL, fps: Int = 30, scale: Int = 320) {
        self.inputURL = inputURL
        self.outputURL = outputURL
        self.paletteOutputURL = FFMpeg.tempDirectoryURL.appendingPathComponent("palette.png")

        self.fps = fps
        self.scale = scale
    }

    func begin() {
        pass1 = Terminal(
            launchPath: launchPath,
            arguments: pass1Arguments
        )
        pass2 = Terminal(
            launchPath: launchPath,
            arguments: pass2Arguments
        )

        pass1?
            .publisher
            .sink { completion in
                switch completion {
                case .failure(let error):
                    self.subject.send(completion: .failure(error))
                case .finished:
                    self.pass2?
                        .publisher
                        .sink { completion in
                            switch completion {
                            case .failure(let error):
                                self.subject.send(completion: .failure(error))
                            case .finished:
                                self.cleanup()
                                self.subject.send(completion: .finished)
                            }
                        } receiveValue: { value in
                            self.subject.send(self.parse(value, stage: .processing))
                        }
                        .store(in: &self.bag)
                }
            } receiveValue: { value in
                self.subject.send(self.parse(value, stage: .preprocessing))
            }
            .store(in: &self.bag)
    }

    private func parse(_ value: String, stage: Output.Stage) -> Output? {
        var dict = [String: String]()
        let lines = value.components(separatedBy: "\n")
        for line in lines {
            let keyvals = line.components(separatedBy: "=")
            if let key = keyvals.first,
               let val = keyvals.last {
                dict[key.trimmingCharacters(in: .whitespacesAndNewlines)] = val.trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        dict[Output.CodingKeys.stage.rawValue] = stage.rawValue
        do {
            let data = try JSONSerialization.data(withJSONObject: dict, options: .fragmentsAllowed)
            let progressObj = try JSONDecoder().decode(Output.self, from: data)
            return progressObj
        } catch {
            print("Data parse error: \(error)")
            return nil
        }
    }


    func cleanup() {
        let fm = FileManager.default
        let paletteUrl = FFMpeg.tempDirectoryURL.appendingPathComponent("palette.png")
        if fm.fileExists(atPath: paletteUrl.path) {
            do {
                try fm.removeItem(atPath: paletteUrl.path)
            } catch {
                print("Failed to remove palette")
            }
        }
    }
}
