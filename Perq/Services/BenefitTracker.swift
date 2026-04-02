import Foundation
import SwiftData
import SwiftUI
import Combine

class BenefitTracker: ObservableObject {
    @Published var upcomingExpirations: [BenefitExpiration] = []

    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        checkForExpiredBenefits()
    }

    func checkForExpiredBenefits() {
        let calendar = Calendar.current
        let now = Date()
        let year = calendar.component(.year, from: now)
        let month = calendar.component(.month, from: now)

        let descriptor = FetchDescriptor<Benefit>()

        do {
            let benefits = try modelContext.fetch(descriptor)
            var expirations: [BenefitExpiration] = []

            for benefit in benefits {
                guard benefit.isActive,
                      benefit.totalAmount != nil,
                      let resetPeriod = benefit.resetPeriod,
                      resetPeriod != .oneTime,
                      resetPeriod != .quadrennial else { continue }

                let (periodId, periodLabel, periodEndDate) = currentPeriodInfo(
                    for: resetPeriod, year: year, month: month,
                    calendar: calendar, now: now
                )

                // Only show if this period hasn't been claimed yet
                guard !benefit.claimedPeriods.contains(periodId) else { continue }

                // Only show if the period ends within the current calendar month
                let periodEndMonth = calendar.component(.month, from: periodEndDate)
                let periodEndYear = calendar.component(.year, from: periodEndDate)
                guard periodEndMonth == month && periodEndYear == year else { continue }

                let daysUntilEnd = calendar.dateComponents([.day], from: now, to: periodEndDate).day ?? 0

                expirations.append(BenefitExpiration(
                    benefit: benefit,
                    periodId: periodId,
                    periodLabel: periodLabel,
                    daysUntilReset: daysUntilEnd,
                    resetDate: periodEndDate
                ))
            }

            upcomingExpirations = expirations.sorted { $0.daysUntilReset < $1.daysUntilReset }
        } catch {
            print("Failed to fetch benefits: \(error)")
        }
    }

    func claimPeriod(benefit: Benefit, periodId: String) {
        benefit.togglePeriod(periodId)
        saveContext()
        checkForExpiredBenefits()
    }

    // MARK: - Period helpers

    private func currentPeriodInfo(
        for period: ResetPeriod, year: Int, month: Int,
        calendar: Calendar, now: Date
    ) -> (id: String, label: String, endDate: Date) {
        let yearStr = String(year)

        switch period {
        case .monthly:
            let id = "\(yearStr)-M\(String(format: "%02d", month))"
            let label = monthName(month) + " \(year)"
            let endDate = endOfMonth(year: year, month: month, calendar: calendar)
            return (id, label, endDate)

        case .quarterly:
            let quarter = (month - 1) / 3 + 1
            let id = "\(yearStr)-Q\(quarter)"
            let label = "Q\(quarter) \(year)"
            let endMonth = quarter * 3
            let endDate = endOfMonth(year: year, month: endMonth, calendar: calendar)
            return (id, label, endDate)

        case .semiAnnual:
            let isFirstHalf = month <= 6
            let id = "\(yearStr)-\(isFirstHalf ? "H1" : "H2")"
            let label = (isFirstHalf ? "First Half" : "Second Half") + " \(year)"
            let endDate = endOfMonth(year: year, month: isFirstHalf ? 6 : 12, calendar: calendar)
            return (id, label, endDate)

        case .annual:
            let id = "\(yearStr)-A"
            let label = "Annual \(year)"
            let endDate = endOfMonth(year: year, month: 12, calendar: calendar)
            return (id, label, endDate)

        default:
            return ("", "", now)
        }
    }

    private func endOfMonth(year: Int, month: Int, calendar: Calendar) -> Date {
        var components = DateComponents(year: year, month: month + 1, day: 1)
        if month == 12 { components = DateComponents(year: year + 1, month: 1, day: 1) }
        return calendar.date(from: components)!.addingTimeInterval(-1)
    }

    private func monthName(_ month: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        return formatter.string(from: Calendar.current.date(from: DateComponents(month: month))!)
    }

    private func saveContext() {
        do {
            try modelContext.save()
        } catch {
            print("Failed to save context: \(error)")
        }
    }
}

// MARK: - Model

struct BenefitExpiration: Identifiable {
    let id = UUID()
    let benefit: Benefit
    let periodId: String
    let periodLabel: String
    let daysUntilReset: Int
    let resetDate: Date

    var urgencyLevel: UrgencyLevel {
        switch daysUntilReset {
        case 0...3:  return .critical
        case 4...7:  return .high
        case 8...14: return .medium
        default:     return .low
        }
    }
}

enum UrgencyLevel {
    case critical, high, medium, low

    var color: Color {
        switch self {
        case .critical: return .perqRose
        case .high: return .perqAmber
        case .medium: return .perqLavender
        case .low: return .perqMint
        }
    }

    var label: String {
        switch self {
        case .critical: return "Last few days"
        case .high: return "This week"
        case .medium: return "2 weeks left"
        case .low: return "This period"
        }
    }
}
