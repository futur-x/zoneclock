//
//  ContentView.swift
//  zoneclock
//
//  Created by dajoe on 2025/10/2.
//  Modified by Zone Clock CDD System on 2025/1/2.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        #if os(macOS)
        CompactMainView()
        #else
        MainView()
        #endif
    }
}

#Preview {
    ContentView()
}
