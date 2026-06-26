import SwiftUI
import UIKit

// MARK: - Adaptive color helper

private func adaptive(dark darkHex: String, light lightHex: String) -> Color {
    Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? uiColor(hex: darkHex)
            : uiColor(hex: lightHex)
    })
}

private func uiColor(hex: String) -> UIColor {
    let h = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
    var int: UInt64 = 0
    Scanner(string: h).scanHexInt64(&int)
    let r = Double(int >> 16 & 0xFF) / 255
    let g = Double(int >> 8  & 0xFF) / 255
    let b = Double(int        & 0xFF) / 255
    return UIColor(red: r, green: g, blue: b, alpha: 1)
}

// MARK: - Perq Brand Colors

extension Color {

    // MARK: Core Brand (same in both modes)
    static let perqViolet   = Color(hex: "#7C3AED")!
    static let perqCyan     = Color(hex: "#06B6D4")!
    static let perqLavender = Color(hex: "#A78BFA")!
    static let perqSky      = Color(hex: "#22D3EE")!

    // MARK: Semantic Accent (same in both modes)
    static let perqMint  = Color(hex: "#4ADE80")!
    static let perqAmber = Color(hex: "#FBBF24")!
    static let perqRose  = Color(hex: "#F87171")!

    // MARK: Backgrounds — adaptive
    static var perqInk: Color      { adaptive(dark: "#06040F", light: "#F2F2F7") }
    static var perqSurface: Color  { adaptive(dark: "#0D0C20", light: "#E5E5EA") }
    static var perqElevated: Color { adaptive(dark: "#12112A", light: "#FFFFFF") }
    static var perqRaised: Color   { adaptive(dark: "#1A1840", light: "#F0F0F5") }

    // MARK: Text — adaptive
    /// Primary text: white on dark, near-black on light
    static var perqGhost: Color {
        adaptive(dark: "#E0E7FF", light: "#1C1C2E")
    }
    /// Strong primary text (e.g. values, headlines)
    static var perqPrimaryText: Color {
        Color(UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(white: 1.0, alpha: 1.0)
                : UIColor(red: 0.11, green: 0.11, blue: 0.18, alpha: 1.0)
        })
    }
    /// Muted secondary text
    static var perqSecondaryText: Color {
        Color(UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(white: 1.0, alpha: 0.55)
                : UIColor(white: 0.0, alpha: 0.45)
        })
    }

    // MARK: Borders — adaptive
    static var perqBorderSubtle: Color {
        Color(UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(red: 0.486, green: 0.227, blue: 0.929, alpha: 0.12)
                : UIColor(white: 0.0, alpha: 0.08)
        })
    }
    static var perqBorderAccent: Color {
        Color(UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(red: 0.486, green: 0.227, blue: 0.929, alpha: 0.35)
                : UIColor(red: 0.486, green: 0.227, blue: 0.929, alpha: 0.45)
        })
    }
}

// MARK: - Brand Gradients

extension LinearGradient {

    static let perqPrimary = LinearGradient(
        colors: [.perqViolet, .perqCyan],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let perqSoft = LinearGradient(
        colors: [.perqLavender.opacity(0.25), .perqSky.opacity(0.15)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let perqProgress = LinearGradient(
        colors: [Color(hex: "#6366F1")!, .perqLavender],
        startPoint: .leading,
        endPoint: .trailing
    )

    static let perqMintProgress = LinearGradient(
        colors: [Color(hex: "#059669")!, .perqMint],
        startPoint: .leading,
        endPoint: .trailing
    )

    static let perqAmberProgress = LinearGradient(
        colors: [Color(hex: "#D97706")!, .perqAmber],
        startPoint: .leading,
        endPoint: .trailing
    )
}

// MARK: - Hex Init

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

// MARK: - Category Colors

extension Color {
    static func perqCategory(_ tag: String) -> Color {
        switch tag {
        case "travel":        return .perqSky
        case "dining":        return Color(hex: "#FB923C")!
        case "shopping":      return .perqLavender
        case "wellness":      return .perqMint
        case "entertainment": return Color(hex: "#F472B6")!
        default:              return Color(hex: "#94A3B8")!
        }
    }

    static func perqCategoryBackground(_ tag: String) -> Color {
        perqCategory(tag).opacity(0.15)
    }
}
