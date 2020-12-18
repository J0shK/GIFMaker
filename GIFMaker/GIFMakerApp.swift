//
//  GIFMakerApp.swift
//  GIFMaker
//
//  Created by Josh Kowarsky on 12/12/20.
//

import SwiftUI

@main
struct GIFMakerApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(SessionManager())
        }
    }
}
