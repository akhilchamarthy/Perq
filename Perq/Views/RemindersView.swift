import SwiftUI
import SwiftData

struct RemindersView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var benefitTracker: BenefitTracker
    @StateObject private var dataManager: CardDataManager

    init(modelContext: ModelContext) {
        self._benefitTracker = StateObject(wrappedValue: BenefitTracker(modelContext: modelContext))
        self._dataManager = StateObject(wrappedValue: CardDataManager(modelContext: modelContext))
    }

    private var totalAnnualFee: Double {
        dataManager.cards.reduce(0) { $0 + $1.annualFee }
    }

    private var totalBenefitsValue: Double {
        dataManager.cards.reduce(0) { $0 + $1.totalPotentialValue }
    }

    private var readyToUseCount: Int {
        dataManager.cards
            .flatMap { $0.benefits }
            .filter { $0.isActive && $0.remainingAmount > 0 }
            .count
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    if !dataManager.cards.isEmpty {
                        RemindersSummaryCard(
                            cardCount: dataManager.cards.count,
                            annualFee: totalAnnualFee,
                            totalBenefits: totalBenefitsValue,
                            readyCount: readyToUseCount
                        )
                    }

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

// MARK: - Summary card

struct RemindersSummaryCard: View {
    let cardCount: Int
    let annualFee: Double
    let totalBenefits: Double
    let readyCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Top row: fee + card count
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Annual Fee Total")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.perqSecondaryText)
                        .textCase(.uppercase)
                        .tracking(0.8)

                    Text("$\(Int(annualFee))")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(.perqGhost)
                }

                Spacer()

                Text("Across \(cardCount) card\(cardCount == 1 ? "" : "s")")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.perqSecondaryText)
                    .padding(.top, 4)
            }

            Divider()
                .background(Color.perqBorderSubtle)

            // Bottom row: benefits available + ready chip
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("$\(Int(totalBenefits)) in total benefits available")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.perqGhost)
                }

                Spacer()

                if readyCount > 0 {
                    HStack(spacing: 5) {
                        Circle()
                            .fill(Color.perqMint)
                            .frame(width: 7, height: 7)
                        Text("\(readyCount) ready")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.perqMint)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.perqMint.opacity(0.12))
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(Color.perqMint.opacity(0.3), lineWidth: 1))
                }
            }
        }
        .padding(18)
        .background(Color.perqElevated)
        .cornerRadius(18)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.perqBorderSubtle, lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 4)
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
                .foregroundColor(.perqSecondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 60)
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
                                    .foregroundColor(.perqSecondaryText)
                            }
                        }
                    }

                    Spacer()

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
                            .foregroundColor(.perqSecondaryText)
                    }
                }

                // Period + amount row
                HStack {
                    Label(expiration.periodLabel, systemImage: "calendar")
                        .font(.caption)
                        .foregroundColor(.perqSecondaryText)

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
                            .foregroundColor(.perqSecondaryText)
                    }
                }

                // Claim button
                Button(action: onClaim) {
                    Text(expiration.benefit.type == .membership || expiration.benefit.type == .status ? "Mark as Enrolled" : "Mark as Claimed")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.perqPrimaryText)
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
