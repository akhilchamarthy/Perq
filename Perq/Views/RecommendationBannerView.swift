import SwiftUI

struct RecommendationBannerView: View {
    let recommendation: PlaceRecommendation
    let onDismiss: () -> Void

    private var rateLabel: String {
        let r = recommendation.rate
        let str = r == Double(Int(r)) ? "\(Int(r))" : String(format: "%.1f", r)
        switch recommendation.unit {
        case .percentCashback: return "\(str)% back"
        case .pointsPerDollar: return "\(str)X points"
        case .milesPerDollar:  return "\(str)X miles"
        }
    }

    private var rateColor: Color {
        switch recommendation.unit {
        case .percentCashback: return .perqMint
        case .pointsPerDollar: return .perqSky
        case .milesPerDollar:  return .perqLavender
        }
    }

    private var categoryIcon: String {
        switch recommendation.categoryKey {
        case "dining":      return "fork.knife"
        case "groceries":   return "cart.fill"
        case "gas":         return "fuelpump.fill"
        case "travel":      return "airplane"
        case "ride_share":  return "car.fill"
        case "streaming":   return "play.tv.fill"
        default:            return "creditcard.fill"
        }
    }

    var body: some View {
        HStack(spacing: 14) {
            // Category icon bubble
            Image(systemName: categoryIcon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(rateColor)
                .frame(width: 40, height: 40)
                .background(rateColor.opacity(0.15))
                .clipShape(Circle())

            // Text
            VStack(alignment: .leading, spacing: 3) {
                Text(recommendation.placeName)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.perqPrimaryText)
                    .lineLimit(1)

                Text("Use this card for ")
                    .font(.caption)
                    .foregroundColor(.perqSecondaryText)
                + Text(rateLabel)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(rateColor)
            }

            Spacer(minLength: 8)

            // Card image chip
            CardArtView(
                imageName: recommendation.card.cardImage,
                cardColor: recommendation.card.cardColor,
                cornerRadius: 5
            )
            .frame(width: 54, height: 34)
            .overlay(
                RoundedRectangle(cornerRadius: 5)
                    .stroke(Color.white.opacity(0.12), lineWidth: 0.5)
            )

            // Dismiss button
            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.perqSecondaryText)
                    .frame(width: 24, height: 24)
                    .background(Color.perqGhost.opacity(0.12))
                    .clipShape(Circle())
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.perqElevated)
                .shadow(color: .black.opacity(0.3), radius: 16, x: 0, y: 6)
        )
        .padding(.horizontal, 12)
    }
}
