import SwiftUI
import SwiftData
import CoreLocation

struct SettingsView: View {
    @AppStorage("isDarkMode") private var isDarkMode = true
    @StateObject private var dataManager: CardDataManager
    @State private var showResetAlert = false

    private let locationManager: LocationManager

    init(modelContext: ModelContext, locationManager: LocationManager) {
        self._dataManager = StateObject(wrappedValue: CardDataManager(modelContext: modelContext))
        self.locationManager = locationManager
    }

    private var totalAnnualFee: Double {
        dataManager.cards.reduce(0) { $0 + $1.annualFee }
    }

    private var totalBenefits: Double {
        dataManager.cards.reduce(0) { $0 + $1.totalPotentialValue }
    }

    private var locationStatusLabel: String {
        switch locationManager.authorizationStatus {
        case .authorizedAlways:    return "Always"
        case .authorizedWhenInUse: return "While Using"
        case .denied:              return "Denied"
        case .restricted:          return "Restricted"
        default:                   return "Not Set"
        }
    }

    private var locationStatusSubtitle: String {
        switch locationManager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            return "Suggests the best card where you are"
        default:
            return "Enable in Settings for card recommendations"
        }
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    SettingsProfileCard(
                        cardCount: dataManager.cards.count,
                        annualFee: totalAnnualFee,
                        totalBenefits: totalBenefits
                    )

                    SettingsSection(title: "Appearance") {
                        SettingsToggleRow(
                            icon: isDarkMode ? "moon.fill" : "sun.max.fill",
                            iconColor: isDarkMode ? .perqLavender : .perqAmber,
                            title: "Dark Mode",
                            subtitle: nil,
                            isOn: $isDarkMode
                        )
                    }

                    SettingsSection(title: "Location") {
                        SettingsInfoRow(
                            icon: "location.fill",
                            iconColor: .perqSky,
                            title: "Location Access",
                            value: locationStatusLabel,
                            subtitle: locationStatusSubtitle
                        )
                    }

                    SettingsSection(title: "Data") {
                        Button {
                            showResetAlert = true
                        } label: {
                            HStack(spacing: 14) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.perqRose.opacity(0.15))
                                        .frame(width: 36, height: 36)
                                    Image(systemName: "trash.fill")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.perqRose)
                                }
                                Text("Reset All Data")
                                    .font(.body)
                                    .foregroundColor(.perqRose)
                                Spacer()
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding()
            }
            .background(Color.perqInk)
            .toolbarBackground(Color.perqInk, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    PerqNavLogo()
                }
            }
            .alert("Reset All Data?", isPresented: $showResetAlert) {
                Button("Reset", role: .destructive) {
                    dataManager.clearAllCards()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will permanently remove all cards, benefits, and tracked data. This cannot be undone.")
            }
        }
    }
}

// MARK: - Profile card

struct SettingsProfileCard: View {
    let cardCount: Int
    let annualFee: Double
    let totalBenefits: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(LinearGradient.perqPrimary)
                        .frame(width: 52, height: 52)
                    Image(systemName: "person.fill")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(.white)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text("\(cardCount) Card\(cardCount == 1 ? "" : "s")")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.perqGhost)
                    Text("$\(Int(totalBenefits)) in annual benefits")
                        .font(.subheadline)
                        .foregroundColor(.perqSecondaryText)
                }

                Spacer()
            }

            Divider()
                .background(Color.perqBorderSubtle)

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Annual Fees")
                        .font(.caption)
                        .foregroundColor(.perqSecondaryText)
                    Text("$\(Int(annualFee))")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.perqGhost)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text("Benefits Value")
                        .font(.caption)
                        .foregroundColor(.perqSecondaryText)
                    Text("$\(Int(totalBenefits))")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.perqMint)
                }
            }
        }
        .padding(18)
        .background(Color.perqElevated)
        .cornerRadius(18)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.perqBorderSubtle, lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 4)
    }
}

// MARK: - Section container

struct SettingsSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title.uppercased())
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.perqSecondaryText)
                .padding(.horizontal, 4)

            VStack(spacing: 0) {
                content
            }
            .background(Color.perqElevated)
            .cornerRadius(16)
        }
    }
}

// MARK: - Info row (read-only value on right)

struct SettingsInfoRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let value: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(iconColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                    .foregroundColor(.perqGhost)
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.perqSecondaryText)
            }

            Spacer()

            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.perqSecondaryText)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

// MARK: - Toggle row

struct SettingsToggleRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String?
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(iconColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                    .foregroundColor(.perqGhost)
                if let sub = subtitle {
                    Text(sub)
                        .font(.caption)
                        .foregroundColor(.perqSecondaryText)
                }
            }

            Spacer()

            Toggle("", isOn: $isOn)
                .tint(.perqLavender)
                .labelsHidden()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}
