import SwiftUI
import SwiftData

struct MainTabView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            CardListView(modelContext: modelContext)
                .tabItem {
                    Label("Cards", systemImage: "creditcard")
                }
                .tag(0)
            
            RemindersView(modelContext: modelContext)
                .tabItem {
                    Label("Reminders", systemImage: "bell")
                }
                .tag(1)
            
            Text("Analytics View")
                .tabItem {
                    Label("Analytics", systemImage: "chart.bar")
                }
                .tag(2)
            
            Text("Settings View")
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(3)
        }
        .accentColor(.blue)
    }
}
