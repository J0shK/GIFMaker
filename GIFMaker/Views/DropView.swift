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
    @State private var active = false
    private let scene: GameScene
    @Binding private var processing: Bool
    @Binding private var progress: CGFloat
    @Binding private var stage: FFMpeg.Output.Stage
    private var performDrop: ((DropInfo) -> Void)?

    init(processing: Binding<Bool>, progress: Binding<CGFloat>, stage: Binding<FFMpeg.Output.Stage>, scene: GameScene, performDrop: ((DropInfo) -> Void)? = nil) {
        _processing = processing
        _progress = progress
        _stage = stage
        self.scene = scene
        self.performDrop = performDrop
        scene.size = CGSize(width: 250, height: 200)
        scene.scaleMode = .aspectFit
    }

    var body: some View {
        ZStack {
            SpriteView(scene: scene)
            Rectangle()
                .strokeBorder(active ? Color.blue : Color.white, style: StrokeStyle(lineWidth: 2, dash: [10], dashPhase: 0))
            VStack {
                Text(processing ? (stage == .processing ? "Converting..." : "Pre-Processing...") : "Drop Here")
                    .font(.title)
                    .foregroundColor(active ? .blue : .white)
                if processing {
                    Text("\(Int(progress * 100))%")
                        .font(.title3)
                        .foregroundColor(active ? .blue : .white)
                }
            }
        }
        .onDrop(of: [.fileURL], delegate: self)
    }
}

extension DropView: DropDelegate {
    func dropEntered(info: DropInfo) {
        guard !processing else { return }
        active = true
        scene.beginPopping(size: .large)
    }

    func dropExited(info: DropInfo) {
        guard !processing else { return }
        active = false
        scene.stopPopping()
    }

    func performDrop(info: DropInfo) -> Bool {
        guard !processing else { return false }
        performDrop?(info)
        return true
    }
}


struct DropView_Previews: PreviewProvider {
    static var previews: some View {
        DropView(processing: .constant(false), progress: .constant(1), stage: .constant(.none), scene: GameScene())
            .frame(width: 250, height: 200)
    }
}
