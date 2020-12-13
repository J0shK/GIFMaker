//
//  Terminal.swift
//  GIFMaker
//
//  Created by Josh Kowarsky on 12/12/20.
//

import Combine
import Cocoa
import Foundation

struct Terminal {
    enum Error: Swift.Error {
        case fail
    }

    static func run(launchPath: String, arguments: [String]) -> Process {
        let process = Process()
        let pipe = Pipe()
        process.standardOutput = pipe
        process.arguments = arguments
        process.launchPath = launchPath
        process.standardInput = FileHandle.nullDevice
        process.launch()
        return process
    }

    static func runAndWait(launchPath: String, arguments: [String]) -> AnyPublisher<Int32, Error> {
        return Future { observer in
            let process = Terminal.run(launchPath: launchPath, arguments: arguments)
            process.waitUntilExit()
            let status = process.terminationStatus
            if status == 0 {
                observer(.success(status))
            } else {
                observer(.failure(.fail))
            }
        }.eraseToAnyPublisher()
    }
}

extension Process: Cancellable {
    public func cancel() {
        terminate()
    }
}

