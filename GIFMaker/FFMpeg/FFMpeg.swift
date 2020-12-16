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

    private let inputURL: URL
    private let paletteOutputURL: URL
    private let outputURL: URL

    private let fps: Int
    private let scale: Int

    private let flags = "lanczos,palettegen"
    private let flags2 = "lanczos[x];[x][1:v]paletteuse"

    private var pass1Filters: String {
        return "fps=\(fps),scale=\(scale):-1:flags=\(flags)"
    }

    private var pass2Filters: String {
        return "fps=\(fps),scale=\(scale):-1:flags=\(flags2)"
    }

    private var pass1: [String] {
        return [
            "-y",
            "-i", inputURL.absoluteString,
            "-vf", pass1Filters,
            paletteOutputURL.absoluteString
        ]
    }

    private var pass2: [String] {
        return [
            "-y",
            "-i", inputURL.absoluteString,
            "-i", paletteOutputURL.absoluteString,
            "-filter_complex", pass2Filters,
            outputURL.absoluteString
        ]
    }

    private static func tempDirectoryURL(outputURL: URL?) -> URL {
        let fm = FileManager.default
//        return try! fm.url(for: .itemReplacementDirectory, in: .userDomainMask, appropriateFor: outputURL, create: true)
        return fm.urls(for: .downloadsDirectory, in: .userDomainMask).first!
    }

    init(inputURL: URL, outputURL: URL? = nil, fps: Int = 30, scale: Int = 320) {
        print("Starting with \(fps) \(scale)")
        self.inputURL = inputURL
        self.outputURL = outputURL ?? FFMpeg.tempDirectoryURL(outputURL: outputURL).appendingPathComponent("Untitled.gif")
        self.paletteOutputURL = FFMpeg.tempDirectoryURL(outputURL: outputURL).appendingPathComponent("palette.png")

        self.fps = fps
        self.scale = scale
    }

    func begin() -> AnyPublisher<Int32, Terminal.Error> {
        return pass(pass1)
            .flatMap { _ in self.pass(self.pass2) }
            .handleEvents(receiveCompletion: { _ in
                self.cleanup()
            }, receiveCancel: {
                self.cleanup()
            })
            .eraseToAnyPublisher()
    }

    func pass(_ arguments: [String]) -> AnyPublisher<Int32, Terminal.Error> {
        return Terminal.runAndWait(launchPath: launchPath, arguments: arguments)
    }

    func cleanup() {
        let fm = FileManager.default
        let paletteUrl = FFMpeg.tempDirectoryURL(outputURL: outputURL).appendingPathComponent("palette.png")
        if fm.fileExists(atPath: paletteUrl.path) {
            do {
                try fm.removeItem(atPath: paletteUrl.path)
            } catch {
                print("Failed to remove palette")
            }
        }
    }
}
