//
//  ContentView.swift
//  GIFMaker
//
//  Created by Josh Kowarsky on 12/12/20.
//

import SwiftUI
import Combine

struct ContentView: View {
    @EnvironmentObject var sessionManager: SessionManager
    @Binding var advancedMode: Bool
    private var bag = Set<AnyCancellable>()

    init(advancedMode: Binding<Bool>) {
        _advancedMode = advancedMode
    }

    var body: some View {
        VStack(spacing: 1) {
            DropView(processing: $sessionManager.processing, progress: $sessionManager.progress, stage: $sessionManager.stage, scene: sessionManager.scene) { [sessionManager] info in
                sessionManager.performDrop(info)
            }
            .frame(width: 250, height: 200)
            .padding([.top, .horizontal])
            DisclosureButton(title: "Configure", isOpen: $advancedMode)
                .padding()
            if advancedMode {
                InputView(inputString: sessionManager.inputPath, outputString: sessionManager.outputString) {
                    sessionManager.openFile()
                } saveFile: {
                    sessionManager.saveFile()
                } clearInput: {
                    sessionManager.inputFile = nil
                } clearOutput: {
                    sessionManager.outputURL = nil
                }
                .frame(maxWidth: 300)

                ConfigView(selectedSize: $sessionManager.dimensions, selectedFPS: $sessionManager.fps)
                    .padding()

                Button(sessionManager.processing ? "Stop" : "Begin") {
                    if sessionManager.processing {
                        sessionManager.cancel()
                    } else {
                        guard let url = sessionManager.inputFile?.url else { return }
                        sessionManager.begin(with: url)
                    }
                }
                .disabled(sessionManager.inputFile == nil)
                .padding()
            }
//            Button("View") {
//                guard let url = sessionManager.outputURL else { return }
//                SaveOpenManager.openFolder(at: url)
//            }
        }.fixedSize()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(advancedMode: .constant(true))
            .environmentObject(SessionManager())
    }
}
