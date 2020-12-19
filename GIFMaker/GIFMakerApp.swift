//
//  GIFMakerApp.swift
//  GIFMaker
//
//  Created by Josh Kowarsky on 12/12/20.
//

import SwiftUI

@main
struct GIFMakerApp: App {
    @ObservedObject var manager = SessionManager()
    var body: some Scene {
        WindowGroup {
            ContentView(advancedMode: $manager.advancedMode)
                .environmentObject(manager)
        }
    }
}
