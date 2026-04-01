import SwiftUI
import SwiftData

struct CardListView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var dataManager: CardDataManager
    @State private var showingAddCard = false

    init(modelContext: ModelContext) {
        self._dataManager = StateObject(wrappedValue: CardDataManager(modelContext: modelContext))
    }

    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 16) {
                    if dataManager.cards.isEmpty {
                        EmptyStateView()
                    } else {
                        ForEach(dataManager.cards) { card in
                            NavigationLink(destination: CardDetailView(card: card)) {
                                CardRowView(card: card)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
                .padding()
            }
            .background(Color(hex: "080810") ?? .black)
            .toolbarBackground(Color(hex: "080810") ?? .black, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .navigationTitle("My Cards")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddCard = true }) {
                        Image(systemName: "plus")
                            .font(.title2)
                            .foregroundColor(.primary)
                    }
                }
            }
            .sheet(isPresented: $showingAddCard) {
                AddCardView(dataManager: dataManager)
            }
            .onAppear {
                dataManager.clearCardsOnFirstLaunch()
            }
        }
    }
}

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "creditcard")
                .font(.system(size: 60))
                .foregroundColor(.gray)

            Text("No Cards Yet")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)

            Text("Add your first credit card to start tracking benefits and rewards")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 100)
    }
}

struct CardRowView: View {
    let card: CreditCard

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(hex: card.cardColor) ?? .gray)
                    .frame(width: 40, height: 25)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text(card.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)

                    Text(card.issuer)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text(card.annualFee == 0 ? "No Annual Fee" : "$\(Int(card.annualFee))/yr")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(card.annualFee == 0 ? .green : .primary)

                    Text("\(card.benefits.count) benefits")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            if !card.benefits.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(card.benefits.prefix(3)) { benefit in
                            BenefitTagView(benefit: benefit)
                        }

                        if card.benefits.count > 3 {
                            Text("+\(card.benefits.count - 3) more")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Capsule().fill(Color.gray.opacity(0.2)))
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(hex: "12121E") ?? Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
    }
}

struct BenefitTagView: View {
    let benefit: Benefit

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(benefit.name)
                .font(.caption)
                .fontWeight(.medium)
                .lineLimit(1)

            if let totalAmount = benefit.totalAmount {
                Text("$\(Int(totalAmount))")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Capsule().fill(categoryColor.opacity(0.2)))
        .foregroundColor(categoryColor)
    }

    private var categoryColor: Color {
        switch benefit.categoryTag {
        case "travel": return .blue
        case "dining": return .orange
        case "shopping": return .purple
        case "wellness": return .green
        case "entertainment": return .pink
        case "other": return .gray
        default: return .primary
        }
    }
}

extension Color {
    init?(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: return nil
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
