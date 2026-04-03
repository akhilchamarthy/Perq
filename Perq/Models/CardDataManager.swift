import Foundation
import SwiftData
import Combine

class CardDataManager: ObservableObject {
    @Published var cards: [CreditCard] = []
    
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        loadCards()
    }
    
    func clearAllCards() {
        let descriptor = FetchDescriptor<CreditCard>()
        do {
            let allCards = try modelContext.fetch(descriptor)
            for card in allCards {
                modelContext.delete(card)
            }
            try modelContext.save()
            cards = []
        } catch {
            print("Failed to clear cards: \(error)")
        }
    }
    
    func clearCardsOnFirstLaunch() {
        let hasLaunchedBefore = UserDefaults.standard.bool(forKey: "HasLaunchedBefore")
        if !hasLaunchedBefore {
            clearAllCards()
            UserDefaults.standard.set(true, forKey: "HasLaunchedBefore")
        }
    }
    
    func loadCards() {
        let descriptor = FetchDescriptor<CreditCard>(sortBy: [SortDescriptor(\.dateAdded, order: .reverse)])
        do {
            cards = try modelContext.fetch(descriptor)
        } catch {
            print("Failed to load cards: \(error)")
        }
    }
    
    func addCard(_ card: CreditCard) {
        modelContext.insert(card)
        save()
        loadCards()
    }
    
    func deleteCard(_ card: CreditCard) {
        cards.removeAll { $0.persistentModelID == card.persistentModelID }
        modelContext.delete(card)
        save()
    }

    func replaceCard(_ newCard: CreditCard) {
        if let existing = cards.first(where: { $0.id == newCard.id }) {
            cards.removeAll { $0.persistentModelID == existing.persistentModelID }
            modelContext.delete(existing)
        }
        modelContext.insert(newCard)
        save()
        loadCards()
    }

    func cardExists(id: String) -> Bool {
        cards.contains(where: { $0.id == id })
    }
    
    func updateCard(_ card: CreditCard) {
        save()
        loadCards()
    }
    
    private func save() {
        do {
            try modelContext.save()
        } catch {
            print("Failed to save: \(error)")
        }
    }
    
    func loadCardsFromJSON() {
        guard let url = Bundle.main.url(forResource: "cards", withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            print("Could not load cards.json")
            return
        }
        
        do {
            let cardData = try JSONDecoder().decode(CardDataResponse.self, from: data)
            
            for issuer in cardData.issuers {
                for cardInfo in issuer.cards {
                    let creditCard = CreditCard(
                        id: cardInfo.id,
                        name: cardInfo.name,
                        issuer: issuer.name,
                        network: cardInfo.network,
                        annualFee: cardInfo.annualFee,
                        annualFeeNote: cardInfo.annualFeeNote,
                        cardColor: cardInfo.cardColor,
                        cardImage: cardInfo.cardImage
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
                        benefit.creditCard = creditCard
                        creditCard.benefits.append(benefit)
                    }
                    
                    for cashbackInfo in cardInfo.cashbackCategories {
                        let cashback = CashbackCategory(
                            id: "\(cardInfo.id)_\(cashbackInfo.category.replacingOccurrences(of: " ", with: "_").lowercased())",
                            category: cashbackInfo.category,
                            rate: cashbackInfo.rate,
                            unit: CashbackUnit(rawValue: cashbackInfo.unit) ?? .percentCashback
                        )
                        cashback.creditCard = creditCard
                        creditCard.cashbackCategories.append(cashback)
                    }
                    
                    addCard(creditCard)
                }
            }
        } catch {
            print("Failed to decode JSON: \(error)")
        }
    }
}

struct CardDataResponse: Codable {
    let version: String
    let lastUpdated: String
    let issuers: [Issuer]
    
    enum CodingKeys: String, CodingKey {
        case version
        case lastUpdated = "last_updated"
        case issuers
    }
}

struct Issuer: Codable {
    let id: String
    let name: String
    let cards: [CardInfo]
}

struct CardInfo: Codable {
    let id: String
    let name: String
    let network: String
    let annualFee: Double
    let annualFeeNote: String?
    let cardColor: String
    let cardImage: String?
    let benefits: [BenefitInfo]
    let cashbackCategories: [CashbackInfo]

    enum CodingKeys: String, CodingKey {
        case id, name, network
        case annualFee = "annual_fee"
        case annualFeeNote = "annual_fee_note"
        case cardColor = "card_color"
        case cardImage = "card_image"
        case benefits
        case cashbackCategories = "cashback_categories"
    }
}

struct BenefitInfo: Codable {
    let id: String
    let name: String
    let type: String
    let totalAmount: Double?
    let resetPeriod: String?
    let description: String
    let categoryTag: String
    
    enum CodingKeys: String, CodingKey {
        case id, name, type, description
        case totalAmount = "total_amount"
        case resetPeriod = "reset_period"
        case categoryTag = "category_tag"
    }
}

struct CashbackInfo: Codable {
    let category: String
    let rate: Double
    let unit: String
}
