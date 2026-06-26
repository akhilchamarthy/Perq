import SwiftUI
import SwiftData

struct CardListView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var dataManager: CardDataManager
    @State private var showingAddCard = false

    let currentPlace: PlaceRecommendation?

    init(modelContext: ModelContext, currentPlace: PlaceRecommendation?) {
        self._dataManager = StateObject(wrappedValue: CardDataManager(modelContext: modelContext))
        self.currentPlace = currentPlace
    }

    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 16) {
                    if let place = currentPlace {
                        LocationHighlightSection(recommendation: place)
                    }

                    if dataManager.cards.isEmpty {
                        EmptyStateView()
                    } else {
                        ForEach(dataManager.cards) { card in
                            SwipeableCardRow(card: card) {
                                dataManager.deleteCard(card)
                            }
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

// MARK: - Location highlight

struct LocationHighlightSection: View {
    let recommendation: PlaceRecommendation

    private var categoryName: String {
        switch recommendation.categoryKey {
        case "dining":      return "Dining"
        case "groceries":   return "Grocery Store"
        case "gas":         return "Gas Station"
        case "travel":      return "Travel"
        case "ride_share":  return "Ride Share"
        case "streaming":   return "Streaming"
        default:            return "Retail"
        }
    }

    private var categoryIcon: String {
        switch recommendation.categoryKey {
        case "dining":      return "fork.knife"
        case "groceries":   return "cart.fill"
        case "gas":         return "fuelpump.fill"
        case "travel":      return "airplane"
        case "ride_share":  return "car.fill"
        case "streaming":   return "play.tv.fill"
        default:            return "bag.fill"
        }
    }

    private var rateLabel: String {
        let r = recommendation.rate
        let s = r == Double(Int(r)) ? "\(Int(r))" : String(format: "%.1f", r)
        switch recommendation.unit {
        case .percentCashback: return "\(s)% back"
        case .pointsPerDollar: return "\(s)× points"
        case .milesPerDollar:  return "\(s)× miles"
        }
    }

    private var rateColor: Color {
        switch recommendation.unit {
        case .percentCashback: return .perqMint
        case .pointsPerDollar: return .perqSky
        case .milesPerDollar:  return .perqLavender
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // "You're at" header
            HStack(spacing: 5) {
                Image(systemName: "location.fill")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.perqMint)
                Text("You're at")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.perqMint)
                    .textCase(.uppercase)
                    .tracking(1)
            }

            // Place name
            Text(recommendation.placeName)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.perqGhost)

            // Category row
            HStack(spacing: 6) {
                Image(systemName: categoryIcon)
                    .font(.system(size: 13))
                Text(categoryName)
                    .font(.subheadline)
            }
            .foregroundColor(.perqSecondaryText)

            Divider()
                .background(Color.perqBorderSubtle)

            // Best card row
            HStack(spacing: 12) {
                CardArtView(
                    imageName: recommendation.card.cardImage,
                    cardColor: recommendation.card.cardColor,
                    cornerRadius: 6
                )
                .frame(width: 52, height: 33)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.white.opacity(0.12), lineWidth: 0.5)
                )

                VStack(alignment: .leading, spacing: 2) {
                    Text(recommendation.card.name)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.perqGhost)
                    Text(recommendation.card.issuer)
                        .font(.caption)
                        .foregroundColor(.perqSecondaryText)
                }

                Spacer()

                Text(rateLabel)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(rateColor)
            }
        }
        .padding(18)
        .background(Color.perqElevated)
        .cornerRadius(18)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.perqMint.opacity(0.25), lineWidth: 1)
        )
        .shadow(color: Color.perqMint.opacity(0.08), radius: 12, x: 0, y: 4)
    }
}

// MARK: - Swipeable wrapper

struct SwipeableCardRow: View {
    let card: CreditCard
    let onDelete: () -> Void

    @State private var offset: CGFloat = 0
    @State private var showDeleteConfirm = false
    @State private var navigateToDetail = false

    private let deleteWidth: CGFloat = 80
    private var isOpen: Bool { offset < -8 }

    var body: some View {
        ZStack(alignment: .trailing) {
            NavigationLink(destination: CardDetailView(card: card), isActive: $navigateToDetail) {
                EmptyView()
            }

            Button { showDeleteConfirm = true } label: {
                VStack(spacing: 5) {
                    Image(systemName: "trash.fill")
                        .font(.title3)
                    Text("Delete")
                        .font(.caption)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.perqPrimaryText)
                .frame(width: deleteWidth)
                .frame(maxHeight: .infinity)
                .background(Color.perqRose)
                .cornerRadius(16)
            }
            .opacity(isOpen ? 1 : 0)
            .scaleEffect(isOpen ? 1 : 0.85)
            .allowsHitTesting(isOpen)

            CardRowView(card: card)
                .offset(x: offset)
                .allowsHitTesting(false)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            if isOpen {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) { offset = 0 }
            } else {
                navigateToDetail = true
            }
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 20, coordinateSpace: .local)
                .onChanged { value in
                    let drag = value.translation.width
                    guard drag < 0 || offset < 0 else { return }
                    offset = drag < 0 ? max(-deleteWidth, drag) : min(0, offset + drag)
                }
                .onEnded { value in
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        offset = value.translation.width < -40 ? -deleteWidth : 0
                    }
                }
        )
        .alert("Delete \(card.name)?", isPresented: $showDeleteConfirm) {
            Button("Delete", role: .destructive) {
                onDelete()
            }
            Button("Cancel", role: .cancel) {
                withAnimation(.spring(response: 0.3)) { offset = 0 }
            }
        } message: {
            Text("This will permanently remove the card and all its benefits. This cannot be undone.")
        }
    }
}

// MARK: - Empty state

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
                .foregroundColor(.perqSecondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 100)
    }
}

// MARK: - Card row

struct CardRowView: View {
    let card: CreditCard

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                CardArtView(imageName: card.cardImage, cardColor: card.cardColor, cornerRadius: 8)
                    .frame(width: 54, height: 34)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.white.opacity(0.15), lineWidth: 0.5)
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text(card.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.perqGhost)

                    Text(card.issuer)
                        .font(.caption)
                        .foregroundColor(.perqSecondaryText)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text(card.annualFee == 0 ? "No Annual Fee" : "$\(Int(card.annualFee))/yr")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(card.annualFee == 0 ? .perqMint : .perqGhost)

                    Text("\(card.benefits.count) benefits")
                        .font(.caption)
                        .foregroundColor(.perqSecondaryText)
                }
            }

            if card.totalPotentialValue > 0 {
                VStack(spacing: 6) {
                    HStack {
                        Text("Benefit Value")
                            .font(.caption)
                            .foregroundColor(.perqSecondaryText)
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
