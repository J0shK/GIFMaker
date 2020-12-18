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
    private var bag = Set<AnyCancellable>()

    var body: some View {
        VStack(spacing: 1) {
            DropView(processing: $sessionManager.processing, scene: sessionManager.scene) { [sessionManager] info in
                sessionManager.performDrop(info)
            }
            .frame(width: 250, height: 200)
            .padding(EdgeInsets(top: 16, leading: 16, bottom: 8, trailing: 16))
            DisclosureButton(title: "Advanced Options", isOpen: $sessionManager.advancedMode)
                .padding()
            if sessionManager.advancedMode {
                InputView(inputString: sessionManager.inputString, outputString: sessionManager.outputString) {
                    sessionManager.openFile()
                } saveFile: {
                    sessionManager.saveFile()
                } clearInput: {
                    sessionManager.inputURL = nil
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
                        guard let url = sessionManager.inputURL else { return }
                        sessionManager.begin(with: url)
                    }
                }
                .disabled(sessionManager.inputURL == nil)
                .padding()
            }
            Button("View") {
                guard let url = sessionManager.outputURL else { return }
                SaveOpenManager.openFolder(at: url)
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(SessionManager())
            .frame(maxWidth: 300)
    }
}
