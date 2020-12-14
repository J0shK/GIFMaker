//
//  DropView.swift
//  GIFMaker
//
//  Created by Josh Kowarsky on 12/12/20.
//

import Combine
import SpriteKit
import SwiftUI

struct DropView: View {
    @ObservedObject var userFileManager: UserFileManager
    @State var active = false
    let scene = GameScene()

    init(userFileManager: UserFileManager) {
        self.userFileManager = userFileManager
        scene.size = CGSize(width: 250, height: 200)
        scene.scaleMode = .aspectFit
    }

    var body: some View {
        ZStack {
            SpriteView(scene: scene)
            Rectangle()
                .strokeBorder(active ? Color.blue : Color.white, style: StrokeStyle(lineWidth: 2, dash: [10], dashPhase: 0))
            Text(userFileManager.processing ? "Processing..." : "Drop Here")
                .font(.title)
                .foregroundColor(active ? .blue : .white)
        }
        .onDrop(of: [.fileURL], delegate: self)
        .onTapGesture {
            print("Tapped")
//            userFileManager.openPanelForFile()
        }
    }
}

extension DropView: DropDelegate {
    func dropEntered(info: DropInfo) {
        guard !userFileManager.processing else { return }
        active = true
        scene.beginPopping()
    }

    func dropExited(info: DropInfo) {
        guard !userFileManager.processing else { return }
        active = false
        scene.stopPopping()
    }

    func performDrop(info: DropInfo) -> Bool {
        guard !userFileManager.processing else { return false }
        userFileManager.handle(dropInfo: info)
        return true
    }
}


struct DropView_Previews: PreviewProvider {
    static var previews: some View {
        DropView(userFileManager: UserFileManager())
    }
}
