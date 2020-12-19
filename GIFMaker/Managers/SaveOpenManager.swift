//
//  SaveOpenManager.swift
//  GIFMaker
//
//  Created by Josh Kowarsky on 12/15/20.
//

import AVFoundation
import Cocoa
import Combine
import SwiftUI

struct FileInfo {
    let url: URL
    let videoInfo: VideoInfo
}

struct VideoInfo {
    let size: CGSize
    let duration: CMTime
}

struct SaveOpenManager {
    static func openFile() -> AnyPublisher<FileInfo?, Never> {
        let op = NSOpenPanel()
        op.canChooseFiles = true
        return op
            .begin()
            .map { [op] response in
                switch(response) {
                case .OK:
                    guard let url = op.url, let videoInfo = SaveOpenManager.getVideoDetails(from: url) else { return nil }
                    return FileInfo(url: url, videoInfo: videoInfo)
                default:
                    return nil
                }
            }
            .eraseToAnyPublisher()
    }

    static func openFolder(at url: URL) {
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }

    static func saveFile(suggestedName: String = "Untitled.gif") -> AnyPublisher<URL?, Never> {
        let sp = NSSavePanel()
        sp.nameFieldStringValue = suggestedName
        return sp
            .begin()
            .map { [sp] response in
                switch(response) {
                case .OK:
                    return sp.url
                default:
                    return nil
                }
            }
            .eraseToAnyPublisher()
    }

    static func handle(dropInfo: DropInfo) -> AnyPublisher<FileInfo?, Never> {
        return Future { observer in
            let items = dropInfo.itemProviders(for: [.fileURL])
            guard let firstItem = items.first, let firstIdentifier = firstItem.registeredTypeIdentifiers.first else { return }
            firstItem.loadItem(forTypeIdentifier: firstIdentifier, options: nil) { (item, error) in
                guard let data = item as? Data else { return }
                guard let url = URL(dataRepresentation: data, relativeTo: nil, isAbsolute: true), let videoInfo = SaveOpenManager.getVideoDetails(from: url) else { return }
                observer(.success(FileInfo(url: url, videoInfo: videoInfo)))
            }
        }
        .eraseToAnyPublisher()
    }

    private static func getVideoDetails(from url: URL) -> VideoInfo? {
        let video = AVAsset(url: url)
        guard let track = video.tracks(withMediaType: .video).first else { return nil }
        let naturalSize = track.naturalSize.applying(track.preferredTransform)
        let size = CGSize(width: abs(naturalSize.width), height: abs(naturalSize.height))
        return VideoInfo(size: size, duration: video.duration)
    }
}

extension NSSavePanel {
    func begin() -> AnyPublisher<NSApplication.ModalResponse, Never> {
        return Future { [weak self] observer in
            self?.begin { response in
                observer(.success(response))
            }
        }.eraseToAnyPublisher()
    }
}
