import UserNotifications

class NotificationManager {
    static let shared = NotificationManager()
    private init() {}

    // MARK: - Permission

    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            if let error { print("Notification permission error: \(error)") }
        }
    }

    // MARK: - Send recommendation notification

    func sendRecommendation(_ recommendation: PlaceRecommendation) {
        let content = UNMutableNotificationContent()
        content.title = recommendation.placeName
        content.body = "Use your \(recommendation.card.name) — earn \(rateLabel(recommendation))"
        content.sound = .default
        // Category icon emoji prefix for quick scanning
        content.subtitle = categoryEmoji(recommendation.categoryKey)

        // Fire immediately (1-second minimum for UNTimeIntervalNotificationTrigger)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "perq-rec-\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error { print("Failed to schedule notification: \(error)") }
        }
    }

    // MARK: - Helpers

    private func rateLabel(_ rec: PlaceRecommendation) -> String {
        let r = rec.rate
        let str = r == Double(Int(r)) ? "\(Int(r))" : String(format: "%.1f", r)
        switch rec.unit {
        case .percentCashback: return "\(str)% cash back"
        case .pointsPerDollar: return "\(str)X points"
        case .milesPerDollar:  return "\(str)X miles"
        }
    }

    private func categoryEmoji(_ key: String) -> String {
        switch key {
        case "dining":      return "🍽️ Dining"
        case "groceries":   return "🛒 Groceries"
        case "gas":         return "⛽️ Gas"
        case "travel":      return "✈️ Travel"
        case "ride_share":  return "🚗 Ride Share"
        case "streaming":   return "📺 Streaming"
        default:            return "💳 Purchase"
        }
    }
}
