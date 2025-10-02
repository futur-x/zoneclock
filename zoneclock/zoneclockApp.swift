//
//  zoneclockApp.swift
//  zoneclock
//
//  Created by dajoe on 2025/10/2.
//

import SwiftUI

@main
struct zoneclockApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        #if os(macOS)
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .defaultSize(width: 280, height: 500)
        #endif
    }
}
