import SwiftUI
import SwiftData
import Combine

struct MainTabView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("isDarkMode") private var isDarkMode = true
    @State private var selectedTab = 0

    @StateObject private var locationManager = LocationManager()
    @StateObject private var recommendationManager = PlaceRecommendationManager()
    @StateObject private var cardDataManager: CardDataManager

    init(modelContext: ModelContext) {
        // We need a CardDataManager at this level so we can pass cards to the recommendation engine
        _cardDataManager = StateObject(wrappedValue: CardDataManager(modelContext: modelContext))
    }

    var body: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .top) {
                Color.perqInk.ignoresSafeArea()

                switch selectedTab {
                case 0:
                    CardListView(modelContext: modelContext, currentPlace: recommendationManager.currentPlace)
                case 1:
                    RemindersView(modelContext: modelContext)
                case 2:
                    AnalyticsView(modelContext: modelContext)
                default:
                    SettingsView(modelContext: modelContext, locationManager: locationManager)
                }

                // Recommendation banner — slides in from the top
                if let rec = recommendationManager.activeRecommendation {
                    VStack {
                        RecommendationBannerView(recommendation: rec) {
                            recommendationManager.dismiss()
                        }
                        .transition(.move(edge: .top).combined(with: .opacity))
                        Spacer()
                    }
                    .zIndex(999)
                    .padding(.top, 8)
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
            locationManager.startMonitoring()
            NotificationManager.shared.requestPermission()
        }
        .onReceive(locationManager.$location.compactMap { $0 }) { location in
            recommendationManager.processLocation(location, cards: cardDataManager.cards)
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.75), value: recommendationManager.activeRecommendation != nil)
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
