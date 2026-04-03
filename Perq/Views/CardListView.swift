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
            // Hidden programmatic navigation link
            NavigationLink(destination: CardDetailView(card: card), isActive: $navigateToDetail) {
                EmptyView()
            }

            // Delete button — only receives hits when revealed
            Button { showDeleteConfirm = true } label: {
                VStack(spacing: 5) {
                    Image(systemName: "trash.fill")
                        .font(.title3)
                    Text("Delete")
                        .font(.caption)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .frame(width: deleteWidth)
                .frame(maxHeight: .infinity)
                .background(Color.perqRose)
                .cornerRadius(16)
            }
            .opacity(isOpen ? 1 : 0)
            .scaleEffect(isOpen ? 1 : 0.85)
            .allowsHitTesting(isOpen)  // ← disabled when hidden so it never blocks taps

            // Card — purely visual, all gestures handled by the ZStack below
            CardRowView(card: card)
                .offset(x: offset)
                .allowsHitTesting(false) // ← prevents the offset view from blocking the delete button
        }
        // All interaction lives on the container so hit-testing areas are consistent
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
                .foregroundColor(.white.opacity(0.55))
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
                        .foregroundColor(.white.opacity(0.55))
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text(card.annualFee == 0 ? "No Annual Fee" : "$\(Int(card.annualFee))/yr")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(card.annualFee == 0 ? .perqMint : .perqGhost)

                    Text("\(card.benefits.count) benefits")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.55))
                }
            }

            if card.totalPotentialValue > 0 {
                VStack(spacing: 6) {
                    HStack {
                        Text("Benefit Value")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.55))
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
