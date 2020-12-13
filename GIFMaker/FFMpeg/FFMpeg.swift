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
    private let passLogFilePath = "\(NSTemporaryDirectory())\(NSUUID().uuidString)_passlog"
    private var bag = Set<AnyCancellable>()

    private let inputPath: String
    private let outputPath: String

    private var pass1: [String] {
        return [
            "-y",
            "-i", inputPath,
            "-pass", "1",
            "-passlogfile", passLogFilePath,
//            "-vcodec", "libx264",
//            "-b:v", "1500k",
//            "-c:a", "aac",
            "-f", "mov",
            "/dev/null"
        ]
    }

    private var pass2: [String] {
        return [
            "-y",
            "-i", inputPath,
            "-pass", "2",
            "-passlogfile", passLogFilePath,
//            "-vcodec", "libx264",
//            "-b:v", "1500k",
//            "-c:a", "aac",
            "-pix_fmt", "yuv420p", // Necessary to allow playback in OS X Finder and QT Player
            outputPath
        ]
    }

    init(inputPath: String, outputPath: String? = nil) {
        self.inputPath = inputPath
        if let outputPath = outputPath {
            self.outputPath = outputPath
        } else {
            let fm = FileManager.default
            guard let url = fm.urls(for: .downloadsDirectory, in: .userDomainMask).first else {
                self.outputPath = ""
                return
            }
            self.outputPath = url.absoluteString.appending("test.gif")
        }
    }

    func begin() {
        pass(pass1)
            .flatMap { _ in self.pass(self.pass2) }
            .subscribe(on: DispatchQueue.global(qos: .background))
            .sink { completed in
                switch(completed) {
                case .finished:
                    print("Completed")
                case .failure(let error):
                    print("FFMpeg error: \(error)")
                }
                self.cleanup()
            } receiveValue: { status in
                print(status)
            }
            .store(in: &bag)

    }

    func stop() {
        bag.removeAll()
        cleanup()
    }

    func pass(_ arguments: [String]) -> AnyPublisher<Int32, Terminal.Error> {
        return Terminal.runAndWait(launchPath: launchPath, arguments: arguments)
    }

    func cleanup() {
        // Clean up ffmpeg pass log files, there should be two of them.
        let fm = FileManager.default
        if fm.fileExists(atPath: "\(passLogFilePath)-0.log") {
            do {
                try fm.removeItem(atPath: "\(passLogFilePath)-0.log")
            } catch {
                print("Failed to remove '-0.log' file.")
            }
        }
        if fm.fileExists(atPath: "\(passLogFilePath)-0.log.mbtree") {
            do {
                try fm.removeItem(atPath: "\(passLogFilePath)-0.log.mbtree")
            } catch {
                print("Failed to remove '-0.log.mbtree' file.")
            }
        }
    }
}
