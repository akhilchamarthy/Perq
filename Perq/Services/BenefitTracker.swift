import Foundation
import SwiftData
import UserNotifications
import SwiftUI
import Combine

class BenefitTracker: ObservableObject {
    @Published var upcomingExpirations: [BenefitExpiration] = []
    
    private let modelContext: ModelContext
    private let notificationManager = NotificationManager()
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        checkForExpiredBenefits()
        schedulePeriodicChecks()
    }
    
    func checkForExpiredBenefits() {
        let calendar = Calendar.current
        let now = Date()
        
        let descriptor = FetchDescriptor<Benefit>(
            sortBy: [SortDescriptor(\.lastResetDate, order: .forward)]
        )
        
        do {
            let benefits = try modelContext.fetch(descriptor)
            var expirations: [BenefitExpiration] = []
            
            for benefit in benefits {
                if benefit.isActive && 
                   benefit.totalAmount != nil && 
                   benefit.totalAmount! > 0 &&
                   benefit.resetPeriod != nil {
                    
                    if let lastResetDate = benefit.lastResetDate,
                       let resetPeriod = benefit.resetPeriod,
                       let nextResetDate = calculateNextResetDate(from: lastResetDate, period: resetPeriod) {
                        
                        let daysUntilReset = calendar.dateComponents([.day], from: now, to: nextResetDate).day ?? 0
                        
                        if daysUntilReset <= 7 {
                            let expiration = BenefitExpiration(
                                benefit: benefit,
                                daysUntilReset: daysUntilReset,
                                resetDate: nextResetDate
                            )
                            expirations.append(expiration)
                            
                            if daysUntilReset <= 3 {
                                scheduleNotification(for: benefit, daysUntilReset: daysUntilReset)
                            }
                        }
                    }
                }
            }
            
            upcomingExpirations = expirations.sorted { $0.daysUntilReset < $1.daysUntilReset }
        } catch {
            print("Failed to fetch benefits: \(error)")
        }
    }
    
    func resetBenefit(_ benefit: Benefit) {
        benefit.resetUsage()
        saveContext()
        checkForExpiredBenefits()
    }
    
    func useBenefit(_ benefit: Benefit, amount: Double) {
        benefit.useAmount(amount)
        saveContext()
        checkForExpiredBenefits()
    }
    
    private func calculateNextResetDate(from date: Date, period: ResetPeriod) -> Date? {
        let calendar = Calendar.current
        
        switch period {
        case .monthly:
            return calendar.date(byAdding: .month, value: 1, to: date)
        case .quarterly:
            return calendar.date(byAdding: .month, value: 3, to: date)
        case .semiAnnual:
            return calendar.date(byAdding: .month, value: 6, to: date)
        case .annual:
            return calendar.date(byAdding: .year, value: 1, to: date)
        case .quadrennial:
            return calendar.date(byAdding: .year, value: 4, to: date)
        case .oneTime:
            return nil
        }
    }
    
    private func scheduleNotification(for benefit: Benefit, daysUntilReset: Int) {
        let title = "Benefit Reset Soon"
        let body = "\(benefit.name) will reset in \(daysUntilReset) day\(daysUntilReset == 1 ? "" : "s"). $\(Int(benefit.remainingAmount)) remaining."
        
        notificationManager.scheduleNotification(
            identifier: "benefit_\(benefit.id)",
            title: title,
            body: body,
            scheduledDate: Date().addingTimeInterval(TimeInterval(daysUntilReset * 24 * 60 * 60))
        )
    }
    
    private func schedulePeriodicChecks() {
        Timer.scheduledTimer(withTimeInterval: 3600, repeats: true) { _ in
            self.checkForExpiredBenefits()
        }
    }
    
    private func saveContext() {
        do {
            try modelContext.save()
        } catch {
            print("Failed to save context: \(error)")
        }
    }
}

struct BenefitExpiration: Identifiable {
    let id = UUID()
    let benefit: Benefit
    let daysUntilReset: Int
    let resetDate: Date
    
    var urgencyLevel: UrgencyLevel {
        switch daysUntilReset {
        case 0...1: return .critical
        case 2...3: return .high
        case 4...7: return .medium
        default: return .low
        }
    }
}

enum UrgencyLevel {
    case critical, high, medium, low
    
    var color: Color {
        switch self {
        case .critical: return .red
        case .high: return .orange
        case .medium: return .yellow
        case .low: return .green
        }
    }
    
    var description: String {
        switch self {
        case .critical: return "Expires today!"
        case .high: return "Expires soon"
        case .medium: return "Expires this week"
        case .low: return "Expires later"
        }
    }
}

class NotificationManager {
    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted {
                print("Notification permission granted")
            } else {
                print("Notification permission denied")
            }
        }
    }
    
    func scheduleNotification(identifier: String, title: String, body: String, scheduledDate: Date) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: scheduledDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error)")
            }
        }
    }
    
    func cancelNotification(identifier: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
    }
}
