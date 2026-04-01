//
//  PerqApp.swift
//  Perq
//
//  Created by Akhil Chamarthy on 3/30/26.
//

import SwiftUI
import SwiftData

@main
struct PerqApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            CreditCard.self,
            Benefit.self,
            CashbackCategory.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(sharedModelContainer)
        }
    }
}
