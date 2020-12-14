//
//  ContentView.swift
//  GIFMaker
//
//  Created by Josh Kowarsky on 12/12/20.
//

import SwiftUI
import Combine

struct ContentView: View {
    @ObservedObject var userFileManager: UserFileManager
    private let dropView: DropView
    private var bag = Set<AnyCancellable>()

    init() {
        let ufm = UserFileManager()
        self.userFileManager = ufm
        dropView = DropView(userFileManager: ufm)

        userFileManager
            .$processing
            .sink { [dropView] processing in
                if processing {
                    dropView.scene.beginPopping()
                } else {
                    dropView.scene.stopPopping()
                }
            }.store(in: &bag)
    }

    var body: some View {
        VStack {
            dropView
                .frame(width: 250, height: 200)
                .padding()
            TextField("Input", text: $userFileManager.inputString).padding()
                .onTapGesture {
                    userFileManager.openPanelForFile()
                }
            TextField("Output", text: $userFileManager.outputString).padding()
                .onTapGesture {
                    userFileManager.openPanelForFolder()
                }
            Button("Begin") {
                userFileManager.begin()
            }.padding()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
