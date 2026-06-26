import SwiftUI

// MARK: - Perq App Icon Mark
//
// Usage:
//   PerqIcon(size: 60)                        // full icon with gradient bg
//   PerqIcon(size: 32, style: .flat)          // flat transparent bg (nav bar)
//   PerqIcon(size: 24, style: .minimal)       // star-only mark
//
// Drop into Assets.xcassets by rendering at 1024pt with UIGraphicsImageRenderer
// or use the Xcode Simulator screenshot approach.

struct PerqIcon: View {

    enum Style {
        case full       // gradient rounded-rect background
        case flat       // no background, violet/cyan tinted marks
        case minimal    // star mark only, no card detail
    }

    let size: CGFloat
    var style: Style = .full

    // Derived scale — all internal geometry is designed at 96pt base
    private var scale: CGFloat { size / 96 }

    var body: some View {
        ZStack {
            if style == .full {
                RoundedRectangle(cornerRadius: size * 0.25)
                    .fill(LinearGradient.perqPrimary)
            }

            if style != .minimal {
                cardDetail
            }

            starMark
        }
        .frame(width: size, height: size)
    }

    // MARK: - Card body (document rows + checkmark badge)

    private var cardDetail: some View {
        let s = scale
        return ZStack(alignment: .topLeading) {

            // Top label rows (simulates card text)
            VStack(alignment: .leading, spacing: 3 * s) {
                Capsule()
                    .fill(white(0.25))
                    .frame(width: 48 * s, height: 9 * s)

                Capsule()
                    .fill(white(0.15))
                    .frame(width: 33 * s, height: 9 * s)
            }
            .offset(x: 12 * s, y: 22 * s)

            // Card chip area (bottom half)
            RoundedRectangle(cornerRadius: 8 * s)
                .fill(white(0.12))
                .frame(width: 70 * s, height: 26 * s)
                .overlay(alignment: .leading) {
                    VStack(alignment: .leading, spacing: 3 * s) {
                        Capsule()
                            .fill(white(0.55))
                            .frame(width: 30 * s, height: 4 * s)
                        Capsule()
                            .fill(white(0.30))
                            .frame(width: 20 * s, height: 3 * s)
                    }
                    .padding(.leading, 6 * s)
                }
                .overlay(alignment: .trailing) {
                    checkBadge
                        .padding(.trailing, 8 * s)
                }
                .offset(x: 12 * s, y: 56 * s)
        }
        .frame(width: size, height: size, alignment: .topLeading)
    }

    // MARK: - Checkmark circle badge

    private var checkBadge: some View {
        let r = 8.0 * scale
        return ZStack {
            Circle()
                .stroke(white(0.40), lineWidth: 2 * scale)
                .frame(width: r * 2, height: r * 2)

            Path { p in
                let cx = r, cy = r
                p.move(to:    CGPoint(x: cx - 3.2 * scale, y: cy))
                p.addLine(to: CGPoint(x: cx - 0.7 * scale, y: cy + 2.4 * scale))
                p.addLine(to: CGPoint(x: cx + 3.4 * scale, y: cy - 2.6 * scale))
            }
            .stroke(style: StrokeStyle(lineWidth: 2 * scale, lineCap: .round, lineJoin: .round))
            .foregroundColor(.white)
        }
    }

    // MARK: - Star/reward mark (top-right)

    private var starMark: some View {
        let s = scale
        let cx = 72.0 * s
        let cy = 32.0 * s
        let orb = 14.0 * s

        return ZStack {
            // Glowing orb behind star
            Circle()
                .fill(Color.perqCyan.opacity(style == .flat ? 0.5 : 0.30))
                .frame(width: orb * 2, height: orb * 2)

            // 5-point star path
            StarShape(points: 5, innerRatio: 0.45)
                .fill(style == .flat ? Color.perqLavender : Color.white.opacity(0.95))
                .frame(width: orb * 1.5, height: orb * 1.5)
        }
        .frame(width: size, height: size, alignment: .topLeading)
        .offset(x: cx - orb, y: cy - orb)
    }

    private func white(_ opacity: Double) -> Color {
        style == .flat
            ? Color.perqLavender.opacity(opacity * 2)
            : Color.white.opacity(opacity)
    }
}

// MARK: - Star Shape

struct StarShape: Shape {
    let points: Int
    var innerRatio: CGFloat = 0.4

    func path(in rect: CGRect) -> Path {
        let cx = rect.midX
        let cy = rect.midY
        let outerR = min(rect.width, rect.height) / 2
        let innerR = outerR * innerRatio
        let step = CGFloat.pi * 2 / CGFloat(points)
        let offset = -CGFloat.pi / 2

        var path = Path()
        for i in 0 ..< points * 2 {
            let angle = offset + CGFloat(i) * step / 2
            let r = i.isMultiple(of: 2) ? outerR : innerR
            let x = cx + r * cos(angle)
            let y = cy + r * sin(angle)
            if i == 0 { path.move(to: CGPoint(x: x, y: y)) }
            else       { path.addLine(to: CGPoint(x: x, y: y)) }
        }
        path.closeSubpath()
        return path
    }
}

// MARK: - Wordmark

struct PerqWordmark: View {
    enum ColorScheme { case dark, light, gradient }

    var scheme: ColorScheme = .dark
    var fontSize: CGFloat = 32

    var body: some View {
        Text("perq")
            .font(.system(size: fontSize, weight: .bold, design: .default))
            .tracking(-0.5)
            .foregroundStyle(foreground)
    }

    private var foreground: AnyShapeStyle {
        switch scheme {
        case .dark:
            return AnyShapeStyle(Color.white)
        case .light:
            return AnyShapeStyle(Color.perqInk)
        case .gradient:
            return AnyShapeStyle(LinearGradient(
                colors: [.perqLavender, .perqSky],
                startPoint: .leading,
                endPoint: .trailing
            ))
        }
    }
}

// MARK: - Full Lockup (icon + wordmark side by side)

struct PerqLockup: View {
    var iconSize: CGFloat = 44
    var iconStyle: PerqIcon.Style = .full
    var wordmarkScheme: PerqWordmark.ColorScheme = .dark
    var spacing: CGFloat = 12

    var body: some View {
        HStack(spacing: spacing) {
            PerqIcon(size: iconSize, style: iconStyle)
            PerqWordmark(
                scheme: wordmarkScheme,
                fontSize: iconSize * 0.70
            )
        }
    }
}

// MARK: - Tagline

struct PerqTagline: View {
    var body: some View {
        Text("YOUR PERKS, TRACKED")
            .font(.system(size: 10, weight: .regular))
            .tracking(3.5)
            .foregroundColor(.white.opacity(0.35))
    }
}

// MARK: - Splash / Onboarding Hero

struct PerqHero: View {
    var body: some View {
        VStack(spacing: 16) {
            PerqIcon(size: 96, style: .full)

            VStack(spacing: 6) {
                PerqWordmark(scheme: .dark, fontSize: 42)
                PerqTagline()
            }
        }
    }
}

// MARK: - Navigation Bar Logo (compact)

struct PerqNavLogo: View {
    var body: some View {
        HStack(spacing: 8) {
            PerqIcon(size: 28, style: .flat)
            PerqWordmark(scheme: .gradient, fontSize: 20)
        }
    }
}

// MARK: - Previews

#Preview("Full icon sizes") {
    HStack(spacing: 20) {
        PerqIcon(size: 96)
        PerqIcon(size: 60)
        PerqIcon(size: 44)
        PerqIcon(size: 32)
        PerqIcon(size: 20)
    }
    .padding(24)
    .background(Color.perqInk)
}

#Preview("Icon styles") {
    HStack(spacing: 24) {
        PerqIcon(size: 64, style: .full)
        PerqIcon(size: 64, style: .flat)
        PerqIcon(size: 64, style: .minimal)
    }
    .padding(24)
    .background(Color.perqSurface)
}

#Preview("Lockup variants") {
    VStack(spacing: 32) {
        PerqHero()
        PerqLockup()
        PerqNavLogo()
    }
    .padding(32)
    .background(Color.perqInk)
}

#Preview("On light background") {
    VStack(spacing: 20) {
        PerqLockup(iconStyle: .full, wordmarkScheme: .light)
    }
    .padding(32)
    .background(Color.white)
}
