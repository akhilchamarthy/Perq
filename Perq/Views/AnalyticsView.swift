import SwiftUI
import SwiftData

struct AnalyticsView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var dataManager: CardDataManager

    init(modelContext: ModelContext) {
        self._dataManager = StateObject(wrappedValue: CardDataManager(modelContext: modelContext))
    }

    private var topPerCategory: [(categoryKey: String, displayName: String, rate: Double, unit: CashbackUnit, card: CreditCard)] {
        var best: [String: (rate: Double, unit: CashbackUnit, card: CreditCard)] = [:]

        for card in dataManager.cards {
            for cat in card.cashbackCategories {
                let key = cat.categoryKey ?? "other"
                if let existing = best[key] {
                    if cat.rate > existing.rate {
                        best[key] = (cat.rate, cat.unit, card)
                    }
                } else {
                    best[key] = (cat.rate, cat.unit, card)
                }
            }
        }

        return best
            .map { (categoryKey: $0.key, displayName: categoryDisplayName(for: $0.key), rate: $0.value.rate, unit: $0.value.unit, card: $0.value.card) }
            .sorted { $0.rate > $1.rate }
    }

    private func categoryDisplayName(for key: String) -> String {
        switch key {
        case "travel":      return "Travel"
        case "dining":      return "Dining"
        case "groceries":   return "Groceries"
        case "streaming":   return "Streaming"
        case "gas":         return "Gas & Transit"
        case "ride_share":  return "Ride Share"
        case "other":       return "All Other Purchases"
        default:            return key.replacingOccurrences(of: "_", with: " ").capitalized
        }
    }

    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 10) {
                    if topPerCategory.isEmpty {
                        emptyState
                    } else {
                        Text("Best Rate Per Category")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.perqGhost)
                            .padding(.bottom, 2)

                        ForEach(topPerCategory, id: \.categoryKey) { entry in
                            CategoryBestRow(
                                categoryKey: entry.categoryKey,
                                category: entry.displayName,
                                rate: entry.rate,
                                unit: entry.unit,
                                card: entry.card
                            )
                        }
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
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 56))
                .foregroundColor(.perqLavender.opacity(0.5))
            Text("No Cards Yet")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.perqGhost)
            Text("Add cards to see your best cashback rates")
                .font(.body)
                .foregroundColor(.perqSecondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 100)
    }
}

// MARK: - Row

struct CategoryBestRow: View {
    let categoryKey: String
    let category: String
    let rate: Double
    let unit: CashbackUnit
    let card: CreditCard

    private var icon: String {
        switch categoryKey {
        case "travel":      return "airplane"
        case "dining":      return "fork.knife"
        case "groceries":   return "cart.fill"
        case "streaming":   return "play.tv.fill"
        case "gas":         return "fuelpump.fill"
        case "ride_share":  return "car.fill"
        default:            return "creditcard.fill"
        }
    }

    private var iconColor: Color {
        switch categoryKey {
        case "travel":      return .perqLavender
        case "dining":      return Color(hex: "#FB923C")!
        case "groceries":   return .perqMint
        case "streaming":   return Color(hex: "#F472B6")!
        case "gas":         return .perqAmber
        case "ride_share":  return .perqSky
        default:            return .perqSecondaryText
        }
    }

    private var rateNumber: String {
        let s = rate == Double(Int(rate)) ? "\(Int(rate))" : String(format: "%.1f", rate)
        switch unit {
        case .percentCashback: return "\(s)%"
        case .pointsPerDollar: return "\(s)×"
        case .milesPerDollar:  return "\(s)×"
        }
    }

    private var rateUnit: String {
        switch unit {
        case .percentCashback: return "back"
        case .pointsPerDollar: return "points"
        case .milesPerDollar:  return "miles"
        }
    }

    private var rateColor: Color {
        switch unit {
        case .percentCashback: return .perqMint
        case .pointsPerDollar: return .perqSky
        case .milesPerDollar:  return .perqLavender
        }
    }

    var body: some View {
        HStack(spacing: 14) {
            // Category icon
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 48, height: 48)
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(iconColor)
            }

            // Title + card name
            VStack(alignment: .leading, spacing: 3) {
                Text(category)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.perqGhost)
                Text(card.name)
                    .font(.caption)
                    .foregroundColor(.perqSecondaryText)
            }

            Spacer()

            // Rate
            VStack(alignment: .trailing, spacing: 1) {
                Text(rateNumber)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(rateColor)
                Text(rateUnit)
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundColor(rateColor.opacity(0.7))
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color.perqElevated)
        .cornerRadius(14)
    }
}
