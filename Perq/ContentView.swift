//
//  ContentView.swift
//  Perq
//
//  Created by Akhil Chamarthy on 3/30/26.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        MainTabView()
    }
}

#Preview {
    ContentView()
}
