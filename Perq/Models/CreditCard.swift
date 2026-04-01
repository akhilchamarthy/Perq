import Foundation
import SwiftData

@Model
final class CreditCard: Identifiable {
    var id: String
    var name: String
    var issuer: String
    var network: String
    var annualFee: Double
    var annualFeeNote: String?
    var cardColor: String
    var dateAdded: Date
    var isActive: Bool
    
    @Relationship(deleteRule: .cascade, inverse: \Benefit.creditCard)
    var benefits: [Benefit] = []
    
    @Relationship(deleteRule: .cascade, inverse: \CashbackCategory.creditCard)
    var cashbackCategories: [CashbackCategory] = []
    
    init(id: String, name: String, issuer: String, network: String, annualFee: Double, annualFeeNote: String? = nil, cardColor: String) {
        self.id = id
        self.name = name
        self.issuer = issuer
        self.network = network
        self.annualFee = annualFee
        self.annualFeeNote = annualFeeNote
        self.cardColor = cardColor
        self.dateAdded = Date()
        self.isActive = true
    }
    
    var totalBenefitValue: Double {
        return benefits.reduce(0) { total, benefit in
            total + (benefit.usedAmount)
        }
    }
    
    var totalPotentialValue: Double {
        return benefits.reduce(0) { total, benefit in
            total + (benefit.totalAmount ?? 0)
        }
    }
    
    var benefitUsagePercentage: Double {
        guard totalPotentialValue > 0 else { return 0 }
        return totalBenefitValue / totalPotentialValue
    }
}

@Model
final class Benefit: Identifiable {
    var id: String
    var name: String
    var type: BenefitType
    var totalAmount: Double?
    var resetPeriod: ResetPeriod?
    var benefitDescription: String
    var categoryTag: String
    var usedAmount: Double
    var lastResetDate: Date?
    var isActive: Bool
    
    var creditCard: CreditCard?
    
    init(id: String, name: String, type: BenefitType, totalAmount: Double? = nil, resetPeriod: ResetPeriod? = nil, benefitDescription: String, categoryTag: String) {
        self.id = id
        self.name = name
        self.type = type
        self.totalAmount = totalAmount
        self.resetPeriod = resetPeriod
        self.benefitDescription = benefitDescription
        self.categoryTag = categoryTag
        self.usedAmount = 0.0
        self.lastResetDate = Date()
        self.isActive = true
    }
    
    var remainingAmount: Double {
        guard let totalAmount = totalAmount else { return 0 }
        return max(0, totalAmount - usedAmount)
    }
    
    var progressPercentage: Double {
        guard let totalAmount = totalAmount, totalAmount > 0 else { return 0 }
        return min(1.0, usedAmount / totalAmount)
    }
    
    func resetUsage() {
        usedAmount = 0.0
        lastResetDate = Date()
    }
    
    func useAmount(_ amount: Double) {
        guard let totalAmount = totalAmount else { return }
        usedAmount = min(totalAmount, usedAmount + amount)
    }
}

@Model
final class CashbackCategory: Identifiable {
    var id: String
    var category: String
    var rate: Double
    var unit: CashbackUnit
    var isActive: Bool
    
    var creditCard: CreditCard?
    
    init(id: String, category: String, rate: Double, unit: CashbackUnit) {
        self.id = id
        self.category = category
        self.rate = rate
        self.unit = unit
        self.isActive = true
    }
}

enum BenefitType: String, CaseIterable, Codable {
    case credit = "credit"
    case membership = "membership"
    case status = "status"
    
    var displayName: String {
        switch self {
        case .credit: return "Credit"
        case .membership: return "Membership"
        case .status: return "Status"
        }
    }
}

enum ResetPeriod: String, CaseIterable, Codable {
    case monthly = "monthly"
    case quarterly = "quarterly"
    case semiAnnual = "semi_annual"
    case annual = "annual"
    case quadrennial = "quadrennial"
    case oneTime = "one_time"
    
    var displayName: String {
        switch self {
        case .monthly: return "Monthly"
        case .quarterly: return "Quarterly"
        case .semiAnnual: return "Semi-Annual"
        case .annual: return "Annual"
        case .quadrennial: return "Every 4 Years"
        case .oneTime: return "One Time"
        }
    }
    
    var description: String {
        switch self {
        case .monthly: return "Resets on the 1st of each calendar month"
        case .quarterly: return "Resets January 1, April 1, July 1, October 1"
        case .semiAnnual: return "Resets January 1 and July 1"
        case .annual: return "Resets on your card anniversary date or January 1 depending on issuer"
        case .quadrennial: return "Resets every 4 years from the date of last use"
        case .oneTime: return "Does not reset — single use benefit"
        }
    }
}

enum CashbackUnit: String, CaseIterable, Codable {
    case percentCashback = "percent_cashback"
    case pointsPerDollar = "points_per_dollar"
    case milesPerDollar = "miles_per_dollar"
    
    var displayName: String {
        switch self {
        case .percentCashback: return "% Cash Back"
        case .pointsPerDollar: return "Points/$"
        case .milesPerDollar: return "Miles/$"
        }
    }
}
