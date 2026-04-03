import SwiftUI
import UIKit

/// Shows the card's photo if one has been added to the asset catalog,
/// otherwise falls back to the card's brand color gradient.
struct CardArtView: View {
    let imageName: String?
    let cardColor: String
    var cornerRadius: CGFloat = 12

    private var color: Color { Color(hex: cardColor) ?? .gray }

    private var hasImage: Bool {
        guard let name = imageName else { return false }
        return UIImage(named: name) != nil
    }

    var body: some View {
        ZStack {
            if hasImage, let name = imageName {
                // Image only — no background
                Image(name)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else {
                // Gradient fallback when no image is available
                LinearGradient(
                    colors: [color, color.opacity(0.55)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                GeometryReader { geo in
                    Circle()
                        .fill(Color.white.opacity(0.12))
                        .frame(width: geo.size.height * 1.4)
                        .position(x: geo.size.width * 0.9, y: geo.size.height * 0.15)
                    Circle()
                        .fill(Color.white.opacity(0.07))
                        .frame(width: geo.size.height * 0.9)
                        .position(x: geo.size.width * 0.78, y: geo.size.height * 0.82)
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }
}
