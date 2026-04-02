import SwiftUI
import SwiftData

// MARK: - Issuer branding

private struct IssuerStyle {
    let color: Color
    let initials: String
}

private func issuerStyle(for id: String) -> IssuerStyle {
    switch id {
    case "amex":            return IssuerStyle(color: Color(hex: "#006FCF")!, initials: "AMEX")
    case "chase":           return IssuerStyle(color: Color(hex: "#117ACA")!, initials: "CHASE")
    case "citi":            return IssuerStyle(color: Color(hex: "#003D99")!, initials: "CITI")
    case "capital_one":     return IssuerStyle(color: Color(hex: "#C41230")!, initials: "CAP ONE")
    case "wells_fargo":     return IssuerStyle(color: Color(hex: "#CC0000")!, initials: "WELLS")
    case "bank_of_america": return IssuerStyle(color: Color(hex: "#E31837")!, initials: "BOFA")
    case "discover":        return IssuerStyle(color: Color(hex: "#F4793B")!, initials: "DISC")
    default:                return IssuerStyle(color: .perqSurface, initials: String(id.prefix(5).uppercased()))
    }
}

// MARK: - Main view

struct AddCardView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let dataManager: CardDataManager

    @State private var selectedIssuer: Issuer?
    @State private var selectedCard: CardInfo?
    @State private var customCardName = ""
    @State private var customAnnualFee = ""
    @State private var isCustomCard = false
    @State private var pendingCard: CreditCard?
    @State private var showingReplaceAlert = false

    var body: some View {
        NavigationView {
            ZStack {
                Color.perqInk.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 28) {
                        if !isCustomCard {
                            IssuerGridView(
                                selectedIssuer: $selectedIssuer,
                                selectedCard: $selectedCard
                            )
                        } else {
                            CustomCardForm(
                                cardName: $customCardName,
                                annualFee: $customAnnualFee
                            )
                        }

                        if selectedCard != nil || (isCustomCard && !customCardName.isEmpty) {
                            addButton
                        }
                    }
                    .padding()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.perqInk, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Add Card")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.perqGhost)
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.perqLavender)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(isCustomCard ? "Browse" : "Custom") {
                        isCustomCard.toggle()
                        selectedIssuer = nil
                        selectedCard = nil
                    }
                    .font(.subheadline)
                    .foregroundColor(.perqLavender)
                }
            }
            .alert("Card Already in Wallet", isPresented: $showingReplaceAlert) {
                Button("Replace", role: .destructive) {
                    if let card = pendingCard {
                        dataManager.replaceCard(card)
                        dismiss()
                    }
                }
                Button("Cancel", role: .cancel) {
                    pendingCard = nil
                }
            } message: {
                Text("This card is already in your wallet. Replacing it will reset all tracked benefits and claimed periods.")
            }
        }
    }

    private var addButton: some View {
        Button(action: addCard) {
            Text("Add Card")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(LinearGradient.perqPrimary)
                .cornerRadius(14)
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    private func addCard() {
        let card = buildCard()
        guard let card else { return }

        if dataManager.cardExists(id: card.id) {
            pendingCard = card
            showingReplaceAlert = true
        } else {
            dataManager.addCard(card)
            dismiss()
        }
    }

    private func buildCard() -> CreditCard? {
        if isCustomCard {
            return CreditCard(
                id: UUID().uuidString,
                name: customCardName,
                issuer: "Custom",
                network: "Unknown",
                annualFee: Double(customAnnualFee) ?? 0,
                cardColor: "#808080"
            )
        } else if let cardInfo = selectedCard, let issuer = selectedIssuer {
            let card = CreditCard(
                id: cardInfo.id,
                name: cardInfo.name,
                issuer: issuer.name,
                network: cardInfo.network,
                annualFee: cardInfo.annualFee,
                annualFeeNote: cardInfo.annualFeeNote,
                cardColor: cardInfo.cardColor
            )
            for benefitInfo in cardInfo.benefits {
                let benefit = Benefit(
                    id: benefitInfo.id,
                    name: benefitInfo.name,
                    type: BenefitType(rawValue: benefitInfo.type) ?? .credit,
                    totalAmount: benefitInfo.totalAmount,
                    resetPeriod: benefitInfo.resetPeriod != nil ? ResetPeriod(rawValue: benefitInfo.resetPeriod!) : nil,
                    benefitDescription: benefitInfo.description,
                    categoryTag: benefitInfo.categoryTag
                )
                benefit.creditCard = card
                card.benefits.append(benefit)
            }
            for cashbackInfo in cardInfo.cashbackCategories {
                let cashback = CashbackCategory(
                    id: "\(cardInfo.id)_\(cashbackInfo.category.replacingOccurrences(of: " ", with: "_").lowercased())",
                    category: cashbackInfo.category,
                    rate: cashbackInfo.rate,
                    unit: CashbackUnit(rawValue: cashbackInfo.unit) ?? .percentCashback
                )
                cashback.creditCard = card
                card.cashbackCategories.append(cashback)
            }
            return card
        }
        return nil
    }
}

// MARK: - Issuer grid

struct IssuerGridView: View {
    @Binding var selectedIssuer: Issuer?
    @Binding var selectedCard: CardInfo?
    @State private var issuers: [Issuer] = []

    private let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Select Bank")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.perqGhost)

            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(issuers, id: \.id) { issuer in
                    IssuerTile(
                        issuer: issuer,
                        isSelected: selectedIssuer?.id == issuer.id
                    ) {
                        withAnimation(.spring(response: 0.3)) {
                            selectedIssuer = issuer
                            selectedCard = nil
                        }
                    }
                }
            }

            if let issuer = selectedIssuer {
                CardPickerView(
                    issuer: issuer,
                    selectedCard: $selectedCard
                )
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .onAppear { issuers = loadIssuers() }
    }

    private func loadIssuers() -> [Issuer] {
        guard let url = Bundle.main.url(forResource: "cards", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode(CardDataResponse.self, from: data) else { return [] }
        return decoded.issuers
    }
}

// MARK: - Issuer tile

struct IssuerTile: View {
    let issuer: Issuer
    let isSelected: Bool
    let onTap: () -> Void

    private var style: IssuerStyle { issuerStyle(for: issuer.id) }

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(LinearGradient(
                            colors: [style.color, style.color.opacity(0.65)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(height: 52)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.15), lineWidth: 1)
                        )

                    Text(style.initials)
                        .font(.system(size: 12, weight: .black))
                        .foregroundColor(.white)
                        .tracking(0.8)
                }

                Text(issuer.name)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : .white.opacity(0.6))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 8)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? style.color.opacity(0.18) : Color.perqElevated)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(
                                isSelected ? style.color : Color.white.opacity(0.07),
                                lineWidth: isSelected ? 1.5 : 1
                            )
                    )
            )
            .shadow(color: isSelected ? style.color.opacity(0.35) : .clear, radius: 8, x: 0, y: 3)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Card picker

struct CardPickerView: View {
    let issuer: Issuer
    @Binding var selectedCard: CardInfo?

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Select Card")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.perqGhost)

                Spacer()

                Text(issuer.name)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.5))
            }

            LazyVStack(spacing: 14) {
                ForEach(issuer.cards, id: \.id) { card in
                    MiniCardPreview(
                        card: card,
                        isSelected: selectedCard?.id == card.id
                    ) {
                        withAnimation(.spring(response: 0.25)) {
                            selectedCard = card
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Mini card visual

struct MiniCardPreview: View {
    let card: CardInfo
    let isSelected: Bool
    let onTap: () -> Void

    private var cardColor: Color { Color(hex: card.cardColor) ?? .gray }

    var body: some View {
        Button(action: onTap) {
            ZStack(alignment: .topLeading) {
                // Background gradient
                LinearGradient(
                    colors: [cardColor, cardColor.opacity(0.55)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                // Decorative circles
                GeometryReader { geo in
                    Circle()
                        .fill(Color.white.opacity(0.10))
                        .frame(width: 110, height: 110)
                        .position(x: geo.size.width * 0.88, y: -10)
                    Circle()
                        .fill(Color.white.opacity(0.06))
                        .frame(width: 70, height: 70)
                        .position(x: geo.size.width * 0.78, y: geo.size.height * 0.85)
                }

                // Card content
                VStack(alignment: .leading) {
                    // Top row
                    HStack {
                        Text(card.network.uppercased())
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundColor(.white.opacity(0.9))
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(Capsule().fill(Color.white.opacity(0.2)))

                        Spacer()

                        if isSelected {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.white)
                                .font(.headline)
                                .transition(.scale.combined(with: .opacity))
                        }
                    }

                    Spacer()

                    // Bottom row
                    VStack(alignment: .leading, spacing: 4) {
                        Text(card.name)
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)

                        HStack {
                            Text(card.annualFee == 0 ? "No Annual Fee" : "$\(Int(card.annualFee))/yr")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.8))

                            Spacer()

                            Text("\(card.benefits.count) benefits")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.75))
                        }
                    }
                }
                .padding(14)
            }
            .frame(height: 140)
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .strokeBorder(
                        isSelected ? Color.white : Color.white.opacity(0.08),
                        lineWidth: isSelected ? 2 : 1
                    )
            )
            .shadow(
                color: cardColor.opacity(isSelected ? 0.55 : 0.2),
                radius: isSelected ? 14 : 6,
                x: 0, y: 4
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Custom card form

struct CustomCardForm: View {
    @Binding var cardName: String
    @Binding var annualFee: String

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Custom Card")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.perqGhost)

            VStack(alignment: .leading, spacing: 8) {
                Text("Card Name")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white.opacity(0.7))

                TextField("e.g. My Visa Signature", text: $cardName)
                    .foregroundColor(.white)
                    .padding(12)
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color.perqElevated))
                    .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(Color.perqBorderSubtle, lineWidth: 1))
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Annual Fee")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white.opacity(0.7))

                HStack {
                    Text("$")
                        .foregroundColor(.white.opacity(0.5))
                    TextField("0", text: $annualFee)
                        .foregroundColor(.white)
                        .keyboardType(.decimalPad)
                }
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 10).fill(Color.perqElevated))
                .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(Color.perqBorderSubtle, lineWidth: 1))
            }

            Text("Benefits and cashback categories can be added after creating the card.")
                .font(.caption)
                .foregroundColor(.white.opacity(0.4))
        }
    }
}
