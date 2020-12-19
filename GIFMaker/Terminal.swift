//
//  Terminal.swift
//  GIFMaker
//
//  Created by Josh Kowarsky on 12/12/20.
//

import Combine
import Cocoa
import Foundation

class Terminal {
    private let process: Process
    let subject = PassthroughSubject<String, Error>()
    private var bag = Set<AnyCancellable>()

    init(launchPath: String, arguments: [String]) {
        process = Process()
        process.arguments = arguments
        process.launchPath = launchPath
        process.standardInput = FileHandle.nullDevice
        attachPipe(to: process)
    }

    func begin() {
        process.launch()
    }

    private func attachPipe(to process: Process) {
        let pipe = Pipe()
        process.standardOutput = pipe
        let outHandle = pipe.fileHandleForReading
        outHandle.waitForDataInBackgroundAndNotify()

        NotificationCenter
            .default
            .publisher(for: .NSFileHandleDataAvailable, object: outHandle)
            .sink { [weak self] completion in
                switch completion {
                case .failure(let error):
                    self?.subject.send(completion: .failure(error))
                case .finished:
                    break
                }
            } receiveValue: { [weak self] notification in
                let data = outHandle.availableData
                if data.count > 0 {
                    if let str = String(data: data, encoding: .utf8) {
                        self?.subject.send(str)
                    }
                    outHandle.waitForDataInBackgroundAndNotify()
                } else {
//                    print("EOF on stdout from process")
                }
            }
            .store(in: &bag)

        NotificationCenter
            .default
            .publisher(for: Process.didTerminateNotification, object: process)
            .sink { [weak self] completion in
                switch completion {
                case .failure(let error):
                    self?.subject.send(completion: .failure(error))
                case .finished:
                    break
                }
            } receiveValue: { [weak self] notification in
                self?.subject.send(completion: .finished)
                self?.bag.removeAll()
            }
            .store(in: &bag)
    }
}

