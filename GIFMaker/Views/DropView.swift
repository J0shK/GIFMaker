//
//  DropView.swift
//  GIFMaker
//
//  Created by Josh Kowarsky on 12/12/20.
//

import Combine
import SwiftUI

struct DropView: View {
    @State var active = false
    var body: some View {
        ZStack {
            Rectangle()
                .strokeBorder(active ? Color.blue : Color.white, style: StrokeStyle(lineWidth: 2, dash: [10], dashPhase: 0))
            Text("Drop Here")
                .font(.title)
                .foregroundColor(active ? .blue : .white)
        }
        .onDrop(of: [.fileURL], delegate: self)
        .onTapGesture {
            print("Tapped")
            let op = NSOpenPanel()
            op.canChooseFiles = true
            op.begin { response in
                print(response)
                switch(response) {
                case .OK:
                    print(op.url?.absoluteString ?? "no url")
                    guard let url = op.url else { return }
                    let ffmpeg = FFMpeg(inputPath: url.absoluteString)
                    ffmpeg.begin()
                default:
                    print("Default behavior")
                }
            }
        }
    }
}

extension DropView: DropDelegate {
    func dropEntered(info: DropInfo) {
        active = true
    }

    func dropExited(info: DropInfo) {
        active = false
    }

    func performDrop(info: DropInfo) -> Bool {
        let items = info.itemProviders(for: [.fileURL])
        guard let firstItem = items.first else { return false}
        firstItem.loadItem(forTypeIdentifier: "public.file-url", options: nil) { (item, error) in
            guard let data = item as? Data else { return }
            print(String(describing: data))
            let url = NSURL(absoluteURLWithDataRepresentation: data, relativeTo: nil)
            print("\(firstItem.suggestedName ?? "no filename") \(url.absoluteString ?? "NO URL")")
            let ffmpeg = FFMpeg(inputPath: url.absoluteString ?? "")
            ffmpeg.begin()
        }
        return true
    }
}
