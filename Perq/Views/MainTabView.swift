import SwiftUI
import SwiftData

struct MainTabView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var selectedTab = 0

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                Color(hex: "080810").ignoresSafeArea()
                switch selectedTab {
                case 0:
                    CardListView(modelContext: modelContext)
                case 1:
                    RemindersView(modelContext: modelContext)
                case 2:
                    Text("Analytics")
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                default:
                    Text("Settings")
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }

            // Custom tab bar
            HStack(spacing: 0) {
                TabBarItem(icon: "creditcard", label: "Cards", tag: 0, selectedTab: $selectedTab)
                TabBarItem(icon: "bell", label: "Reminders", tag: 1, selectedTab: $selectedTab)
                TabBarItem(icon: "chart.bar", label: "Analytics", tag: 2, selectedTab: $selectedTab)
                TabBarItem(icon: "gearshape", label: "Settings", tag: 3, selectedTab: $selectedTab)
            }
            .padding(.top, 10)
            .padding(.bottom, 28)
            .background {
                Color(hex: "0D0D1A")
                    .ignoresSafeArea()
                    .overlay(alignment: .top) {
                        Rectangle()
                            .fill(Color.white.opacity(0.08))
                            .frame(height: 1)
                    }
            }
        }
        .ignoresSafeArea(edges: .bottom)
    }
}

struct TabBarItem: View {
    let icon: String
    let label: String
    let tag: Int
    @Binding var selectedTab: Int

    var isSelected: Bool { selectedTab == tag }

    var body: some View {
        Button {
            withAnimation(.spring()) { selectedTab = tag }
        } label: {
            VStack(spacing: 4) {
                Image(systemName: isSelected ? "\(icon).fill" : icon)
                    .font(.system(size: 22))
                Text(label)
                    .font(.caption2)
            }
            .foregroundColor(isSelected ? .perqLavender : .white.opacity(0.4))
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
