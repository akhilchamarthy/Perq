import SwiftUI
import SwiftData

struct AddCardView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    let dataManager: CardDataManager
    
    @State private var selectedIssuer: Issuer?
    @State private var selectedCard: CardInfo?
    @State private var customCardName = ""
    @State private var customAnnualFee = ""
    @State private var isCustomCard = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    if !isCustomCard {
                        IssuerSelectionView(
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
                        Button(action: addCard) {
                            Text("Add Card")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(12)
                        }
                        .padding(.horizontal)
                    }
                }
                .padding()
            }
            .navigationTitle("Add Card")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(isCustomCard ? "Browse Cards" : "Custom Card") {
                        isCustomCard.toggle()
                        selectedIssuer = nil
                        selectedCard = nil
                    }
                    .font(.caption)
                }
            }
        }
    }
    
    private func addCard() {
        let card: CreditCard
        
        if isCustomCard {
            card = CreditCard(
                id: UUID().uuidString,
                name: customCardName,
                issuer: "Custom",
                network: "Unknown",
                annualFee: Double(customAnnualFee) ?? 0,
                cardColor: "#808080"
            )
        } else if let cardInfo = selectedCard, let issuer = selectedIssuer {
            card = CreditCard(
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
        } else {
            return
        }
        
        dataManager.addCard(card)
        dismiss()
    }
}

struct IssuerSelectionView: View {
    @Binding var selectedIssuer: Issuer?
    @Binding var selectedCard: CardInfo?
    @State private var issuers: [Issuer] = []
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Select Issuer")
                .font(.headline)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 12) {
                ForEach(issuers, id: \.id) { issuer in
                    Button(action: { 
                        selectedIssuer = issuer
                        selectedCard = nil
                    }) {
                        VStack(spacing: 8) {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.blue.opacity(0.1))
                                .frame(width: 60, height: 40)
                                .overlay(
                                    Text(issuer.name.prefix(3))
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .foregroundColor(.blue)
                                )
                            
                            Text(issuer.name)
                                .font(.caption)
                                .foregroundColor(.primary)
                                .lineLimit(1)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(selectedIssuer?.id == issuer.id ? Color.blue.opacity(0.1) : Color.clear)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(selectedIssuer?.id == issuer.id ? Color.blue : Color.clear, lineWidth: 2)
                            )
                    )
                }
            }
            
            if let issuer = selectedIssuer {
                CardSelectionView(
                    issuer: issuer,
                    selectedCard: $selectedCard
                )
            }
        }
        .onAppear {
            issuers = loadIssuers()
        }
    }
    
    private func loadIssuers() -> [Issuer] {
        guard let url = Bundle.main.url(forResource: "cards", withExtension: "json") else {
            print("Could not find cards.json file")
            return []
        }
        
        do {
            let data = try Data(contentsOf: url)
            let cardData = try JSONDecoder().decode(CardDataResponse.self, from: data)
            print("Successfully loaded \(cardData.issuers.count) issuers")
            return cardData.issuers
        } catch {
            print("Failed to load or decode cards.json: \(error)")
            return []
        }
    }
}

struct CardSelectionView: View {
    let issuer: Issuer
    @Binding var selectedCard: CardInfo?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Select Card")
                .font(.headline)
                .fontWeight(.semibold)
            
            LazyVStack(spacing: 12) {
                ForEach(issuer.cards, id: \.id) { card in
                    Button(action: { selectedCard = card }) {
                        HStack(spacing: 12) {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(hex: card.cardColor) ?? .gray)
                                .frame(width: 50, height: 32)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                )
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(card.name)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.primary)
                                
                                Text(card.annualFee == 0 ? "No Annual Fee" : "$\(Int(card.annualFee))/yr")
                                    .font(.caption)
                                    .foregroundColor(card.annualFee == 0 ? .green : .secondary)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 2) {
                                Text("\(card.benefits.count)")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.blue)
                                
                                Text("benefits")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(selectedCard?.id == card.id ? Color.blue.opacity(0.1) : Color(.systemBackground))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(selectedCard?.id == card.id ? Color.blue : Color(.separator), lineWidth: selectedCard?.id == card.id ? 2 : 1)
                                )
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }
}

struct CustomCardForm: View {
    @Binding var cardName: String
    @Binding var annualFee: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Custom Card Details")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Card Name")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                TextField("Enter card name", text: $cardName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Annual Fee")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                TextField("0", text: $annualFee)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.decimalPad)
            }
            
            Text("You can add benefits and cashback categories after creating the card.")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.top, 8)
        }
    }
}
