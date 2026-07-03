import SwiftUI
import SwiftData
import CoreLocation

struct MainTabView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("isDarkMode") private var isDarkMode = true
    @State private var selectedTab = 0

    @StateObject private var locationManager = LocationManager()
    @StateObject private var recommendationManager = PlaceRecommendationManager()
    @StateObject private var cardDataManager: CardDataManager

    init(modelContext: ModelContext) {
        _cardDataManager = StateObject(wrappedValue: CardDataManager(modelContext: modelContext))
    }

    @MainActor
    private func loadLocation() async {
        let loc = await locationManager.fetchCurrentLocation()
        await recommendationManager.refresh(at: loc, cards: cardDataManager.cards)
    }

    var body: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .top) {
                Color.perqInk.ignoresSafeArea()

                switch selectedTab {
                case 0:
                    CardListView(
                        modelContext: modelContext,
                        currentPlace: recommendationManager.currentPlace,
                        onRefresh: {
                            let loc = await locationManager.fetchCurrentLocation()
                            await recommendationManager.refresh(at: loc, cards: cardDataManager.cards)
                        }
                    )
                case 1:
                    RemindersView(modelContext: modelContext)
                case 2:
                    AnalyticsView(modelContext: modelContext)
                default:
                    SettingsView(modelContext: modelContext, locationManager: locationManager)
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
                Color.perqSurface
                    .ignoresSafeArea()
                    .overlay(alignment: .top) {
                        Rectangle()
                            .fill(Color.perqBorderSubtle)
                            .frame(height: 1)
                    }
            }
        }
        .ignoresSafeArea(edges: .bottom)
        .preferredColorScheme(isDarkMode ? .dark : .light)
        .onAppear {
            locationManager.requestPermission()
            NotificationManager.shared.requestPermission()
            Task { await loadLocation() }
        }
        .onChange(of: locationManager.authorizationStatus) { status in
            if status == .authorizedWhenInUse || status == .authorizedAlways {
                Task { await loadLocation() }
            }
        }
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
            .foregroundColor(isSelected ? .perqLavender : .perqSecondaryText)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
