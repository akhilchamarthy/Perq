import SwiftUI
import SwiftData

struct RemindersView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var benefitTracker: BenefitTracker

    init(modelContext: ModelContext) {
        self._benefitTracker = StateObject(wrappedValue: BenefitTracker(modelContext: modelContext))
    }

    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 14) {
                    if benefitTracker.upcomingExpirations.isEmpty {
                        EmptyRemindersView()
                    } else {
                        ForEach(benefitTracker.upcomingExpirations) { expiration in
                            ReminderCardView(
                                expiration: expiration,
                                onClaim: {
                                    benefitTracker.claimPeriod(
                                        benefit: expiration.benefit,
                                        periodId: expiration.periodId
                                    )
                                }
                            )
                        }
                    }
                }
                .padding()
            }
            .background(Color.perqInk)
            .toolbarBackground(Color.perqInk, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    PerqNavLogo()
                }
            }
            .onAppear {
                benefitTracker.checkForExpiredBenefits()
            }
        }
    }
}

// MARK: - Empty state

struct EmptyRemindersView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "bell.badge")
                .font(.system(size: 60))
                .foregroundColor(.perqLavender.opacity(0.5))

            Text("All Caught Up")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.perqGhost)

            Text("No benefits are expiring soon.\nYou'll see unclaimed perks here as they approach their reset date.")
                .font(.body)
                .foregroundColor(.white.opacity(0.55))
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 100)
    }
}

// MARK: - Reminder card

struct ReminderCardView: View {
    let expiration: BenefitExpiration
    let onClaim: () -> Void

    private var cardColor: Color {
        Color(hex: expiration.benefit.creditCard?.cardColor ?? "#808080") ?? .gray
    }

    var body: some View {
        HStack(spacing: 0) {
            // Left urgency accent bar
            RoundedRectangle(cornerRadius: 3)
                .fill(expiration.urgencyLevel.color)
                .frame(width: 4)
                .padding(.vertical, 16)

            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(expiration.benefit.name)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.perqGhost)

                        if let card = expiration.benefit.creditCard {
                            HStack(spacing: 6) {
                                CardArtView(imageName: card.cardImage, cardColor: card.cardColor, cornerRadius: 4)
                                    .frame(width: 32, height: 20)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 4)
                                            .stroke(Color.white.opacity(0.15), lineWidth: 0.5)
                                    )
                                Text(card.name)
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.55))
                            }
                        }
                    }

                    Spacer()

                    // Urgency badge
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(expiration.urgencyLevel.label)
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundColor(expiration.urgencyLevel.color)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(expiration.urgencyLevel.color.opacity(0.15))
                            .clipShape(Capsule())

                        Text(daysLabel)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.55))
                    }
                }

                // Period + amount row
                HStack {
                    Label(expiration.periodLabel, systemImage: "calendar")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.55))

                    Spacer()

                    if let total = expiration.benefit.totalAmount,
                       let period = expiration.benefit.resetPeriod,
                       total > 0 {
                        let perPeriod = total / Double(period.numberOfPeriods)
                        Text("$\(Int(perPeriod))")
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(.perqMint)
                        Text("unclaimed")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.45))
                    }
                }

                // Claim button
                Button(action: onClaim) {
                    Text(expiration.benefit.type == .membership || expiration.benefit.type == .status ? "Mark as Enrolled" : "Mark as Claimed")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(LinearGradient.perqPrimary)
                        .cornerRadius(10)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 16)
        }
        .background(Color.perqElevated)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.35), radius: 8, x: 0, y: 4)
    }

    private var daysLabel: String {
        switch expiration.daysUntilReset {
        case 0: return "Expires today"
        case 1: return "1 day left"
        default: return "\(expiration.daysUntilReset) days left"
        }
    }
}
