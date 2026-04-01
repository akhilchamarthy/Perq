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
            .background(Color.perqInk)
            .toolbarBackground(Color.perqInk, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    PerqNavLogo()
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddCard = true }) {
                        Image(systemName: "plus")
                            .font(.title2)
                            .foregroundColor(.perqGhost)
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
                .foregroundColor(.perqLavender.opacity(0.5))

            Text("No Cards Yet")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.perqGhost)

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
                        .foregroundColor(.perqGhost)

                    Text(card.issuer)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text(card.annualFee == 0 ? "No Annual Fee" : "$\(Int(card.annualFee))/yr")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(card.annualFee == 0 ? .perqMint : .perqGhost)

                    Text("\(card.benefits.count) benefits")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            if card.totalPotentialValue > 0 {
                VStack(spacing: 6) {
                    HStack {
                        Text("Benefit Value")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("$\(Int(card.totalBenefitValue)) / $\(Int(card.totalPotentialValue))")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.perqLavender)
                    }
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color.perqRaised)
                            RoundedRectangle(cornerRadius: 3)
                                .fill(LinearGradient.perqMintProgress)
                                .frame(width: geo.size.width * min(card.benefitUsagePercentage, 1.0))
                        }
                    }
                    .frame(height: 6)
                }
            }
        }
        .padding()
        .background(Color.perqElevated)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.4), radius: 8, x: 0, y: 4)
    }
}
