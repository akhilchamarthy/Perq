import SwiftUI

// MARK: - Perq Brand Colors

extension Color {

    // MARK: Core Brand
    static let perqViolet      = Color(hex: "#7C3AED")!   // Primary — gradient start
    static let perqCyan        = Color(hex: "#06B6D4")!   // Primary — gradient end
    static let perqLavender    = Color(hex: "#A78BFA")!   // Tinted text, active states
    static let perqSky         = Color(hex: "#22D3EE")!   // Light cyan accent

    // MARK: Backgrounds
    static let perqInk         = Color(hex: "#06040F")!   // Deepest bg (root screens)
    static let perqSurface     = Color(hex: "#0D0C20")!   // Card surfaces
    static let perqElevated    = Color(hex: "#12112A")!   // Elevated cards, stat chips
    static let perqRaised      = Color(hex: "#1A1840")!   // Highest elevation, modals

    // MARK: Semantic
    static let perqMint        = Color(hex: "#4ADE80")!   // Success / remaining value
    static let perqAmber       = Color(hex: "#FBBF24")!   // Warning / expiring soon
    static let perqRose        = Color(hex: "#F87171")!   // Danger / exceeded
    static let perqGhost       = Color(hex: "#E0E7FF")!   // Primary text on dark

    // MARK: Border / Separator
    static let perqBorderSubtle  = Color(hex: "#7C3AED")!.opacity(0.12)
    static let perqBorderAccent  = Color(hex: "#7C3AED")!.opacity(0.35)
}

// MARK: - Brand Gradients

extension LinearGradient {

    /// Violet → Cyan — used on the app icon, card art, and CTAs
    static let perqPrimary = LinearGradient(
        colors: [.perqViolet, .perqCyan],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Softer lavender → sky — used on subtle fills and pill backgrounds
    static let perqSoft = LinearGradient(
        colors: [.perqLavender.opacity(0.25), .perqSky.opacity(0.15)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Progress bar fill
    static let perqProgress = LinearGradient(
        colors: [Color(hex: "#6366F1")!, .perqLavender],
        startPoint: .leading,
        endPoint: .trailing
    )

    /// Mint gradient for high-remaining-value bars
    static let perqMintProgress = LinearGradient(
        colors: [Color(hex: "#059669")!, .perqMint],
        startPoint: .leading,
        endPoint: .trailing
    )

    /// Amber gradient for expiring-soon bars
    static let perqAmberProgress = LinearGradient(
        colors: [Color(hex: "#D97706")!, .perqAmber],
        startPoint: .leading,
        endPoint: .trailing
    )
}

// MARK: - Hex Init (already in your codebase, kept for completeness)

extension Color {
    init?(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:  (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:  (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:  (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: return nil
        }
        self.init(.sRGB,
                  red:     Double(r) / 255,
                  green:   Double(g) / 255,
                  blue:    Double(b) / 255,
                  opacity: Double(a) / 255)
    }
}

// MARK: - Category Colors (benefit tags)

extension Color {
    static func perqCategory(_ tag: String) -> Color {
        switch tag {
        case "travel":        return .perqSky
        case "dining":        return Color(hex: "#FB923C")!   // Orange
        case "shopping":      return .perqLavender
        case "wellness":      return .perqMint
        case "entertainment": return Color(hex: "#F472B6")!   // Pink
        default:              return Color(hex: "#94A3B8")!   // Slate
        }
    }

    static func perqCategoryBackground(_ tag: String) -> Color {
        perqCategory(tag).opacity(0.15)
    }
}
