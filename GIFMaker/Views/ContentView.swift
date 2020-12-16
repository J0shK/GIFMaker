//
//  ContentView.swift
//  GIFMaker
//
//  Created by Josh Kowarsky on 12/12/20.
//

import SwiftUI
import Combine

struct ContentView: View {
    @ObservedObject var sessionManager: SessionManager
    private var dropView: DropView
    private var bag = Set<AnyCancellable>()
    @State private var isOpen: Bool = false

    init() {
        let sessionManager = SessionManager()
        self.sessionManager = sessionManager
        dropView = DropView(processing: sessionManager.processing) { [sessionManager] info in
            sessionManager.performDrop(info)
        }
        sessionManager
            .$processing
            .sink { [dropView] processing in
                if processing {
                    dropView.scene.beginPopping(size: .large)
                } else {
                    dropView.scene.stopPopping()
                }
            }.store(in: &bag)

        sessionManager
            .$inputURL
            .sink { [dropView] url in
                if url != nil {
                    dropView.scene.beginPopping(size: .small)
                } else {
                    dropView.scene.stopPopping()
                }
            }
            .store(in: &bag)
    }

    var body: some View {
        VStack(spacing: 1) {
            dropView
                .frame(width: 250, height: 200)
                .padding(EdgeInsets(top: 16, leading: 16, bottom: 8, trailing: 16))
            DisclosureButton(title: "Advanced Options") {
                isOpen.toggle()
            }.padding()
            if isOpen {
                InputView(inputString: sessionManager.inputString, outputString: sessionManager.outputString) {
                    sessionManager.openFile()
                } saveFile: {
                    sessionManager.saveFile()
                } clearInput: {
                    sessionManager.inputURL = nil
                } clearOutput: {
                    sessionManager.outputURL = nil
                }.frame(maxWidth: 300)

                ConfigView(selectedSize: $sessionManager.dimensions, selectedFPS: $sessionManager.fps).padding()

                Button(sessionManager.processing ? "Stop" : "Begin") {
                    if sessionManager.processing {
                        sessionManager.cancel()
                    } else {
                        sessionManager.begin()
                    }
                }.disabled(sessionManager.inputURL == nil)
                .padding()
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .frame(maxWidth: 300)
    }
}


struct DisclosureButton: View {
    @State var open: Bool = false
    let title: String
    let action: () -> Void
    var body: some View {
        Button(action: {
            open.toggle()
            action()
        }, label: {
            HStack {
                Image(systemName: open ? "arrowtriangle.down.fill" : "arrowtriangle.right.fill")
                Text(title)
                Spacer()
            }
        }).buttonStyle(PlainButtonStyle()).frame(maxWidth: .infinity)
    }
}

struct DisclosureButton_Previews: PreviewProvider {
    static var previews: some View {
        DisclosureButton(title: "Toggle") {
            //
        }
    }
}
