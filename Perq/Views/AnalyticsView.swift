import SwiftUI
import SwiftData

struct AnalyticsView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var dataManager: CardDataManager

    init(modelContext: ModelContext) {
        self._dataManager = StateObject(wrappedValue: CardDataManager(modelContext: modelContext))
    }

    // For each unique category_key, keep only the card offering the highest rate
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
                        // Section title
                        Text("Best Rate Per Category")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.perqGhost)
                            .padding(.bottom, 2)

                        ForEach(topPerCategory, id: \.categoryKey) { entry in
                            CategoryBestRow(
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
    let category: String
    let rate: Double
    let unit: CashbackUnit
    let card: CreditCard

    private var rateLabel: String {
        let rateStr = rate == Double(Int(rate)) ? "\(Int(rate))" : String(format: "%.1f", rate)
        switch unit {
        case .percentCashback: return "\(rateStr)%"
        case .pointsPerDollar: return "\(rateStr)X pts"
        case .milesPerDollar:  return "\(rateStr)X mi"
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
        HStack(spacing: 12) {
            // Rate badge
            Text(rateLabel)
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundColor(rateColor)
                .frame(width: 60, alignment: .center)
                .padding(.vertical, 6)
                .background(rateColor.opacity(0.12))
                .clipShape(Capsule())

            // Category name
            Text(category)
                .font(.subheadline)
                .foregroundColor(.perqGhost)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            Spacer()

            // Card chip
            CardArtView(imageName: card.cardImage, cardColor: card.cardColor, cornerRadius: 4)
                .frame(width: 38, height: 24)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
                )
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color.perqElevated)
        .cornerRadius(14)
    }
}
