import SwiftUI
import SwiftData

struct CardDetailView: View {
    let card: CreditCard
    @State private var selectedTab: Tab = .benefits

    enum Tab: String, CaseIterable {
        case benefits = "Benefits"
        case cashback = "Cashback"
        case details = "Details"
    }

    var body: some View {
        ZStack {
            Color.perqInk.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    CardHeaderView(card: card)

                    TabSelectorView(selectedTab: $selectedTab)

                    TabContentView(selectedTab: selectedTab, card: card)
                }
                .padding()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.perqInk, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Edit") {
                    // TODO: Implement edit functionality
                }
            }
        }
    }
}

struct CardHeaderView: View {
    let card: CreditCard

    private var cardColor: Color { Color(hex: card.cardColor) ?? .blue }

    var body: some View {
        VStack(spacing: 16) {
            // Gradient card art
            ZStack {
                LinearGradient(
                    colors: [cardColor, cardColor.opacity(0.5)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                GeometryReader { geo in
                    Circle()
                        .fill(Color.white.opacity(0.12))
                        .frame(width: 150, height: 150)
                        .position(x: geo.size.width * 0.88, y: geo.size.height * 0.2)

                    Circle()
                        .fill(Color.white.opacity(0.08))
                        .frame(width: 90, height: 90)
                        .position(x: geo.size.width * 0.78, y: geo.size.height * 0.72)
                }

                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(card.network.uppercased())
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.white.opacity(0.85))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Capsule().fill(Color.white.opacity(0.2)))
                        Spacer()
                    }

                    Spacer()

                    Text(card.name)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)

                    Text(card.issuer)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                }
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 160)
            .clipShape(RoundedRectangle(cornerRadius: 20))

            // Stats row
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Annual Fee")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(card.annualFee == 0 ? "No Fee" : "$\(Int(card.annualFee))/yr")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(card.annualFee == 0 ? .green : .primary)
                }

                Spacer()

                VStack(alignment: .center, spacing: 4) {
                    Text("Benefits")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(card.benefits.count)")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("Rewards")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(card.cashbackCategories.count) cats")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                }
            }
            .padding()
            .background(RoundedRectangle(cornerRadius: 16).fill(Color.perqElevated))

            if let annualFeeNote = card.annualFeeNote, !annualFeeNote.isEmpty {
                Text(annualFeeNote)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            // Benefit value progress bar
            if card.totalPotentialValue > 0 {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Benefit Value")
                            .font(.subheadline)
                            .fontWeight(.semibold)

                        Spacer()

                        Text("$\(Int(card.totalBenefitValue)) / $\(Int(card.totalPotentialValue))")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.perqLavender)
                    }

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.white.opacity(0.1))
                            RoundedRectangle(cornerRadius: 4)
                                .fill(LinearGradient.perqMintProgress)
                                .frame(width: geo.size.width * min(card.benefitUsagePercentage, 1.0))
                        }
                    }
                    .frame(height: 8)

                    Text("You've extracted $\(Int(card.totalBenefitValue)) in value from this card's benefits")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(RoundedRectangle(cornerRadius: 16).fill(Color.perqElevated))
            }
        }
    }
}

struct TabSelectorView: View {
    @Binding var selectedTab: CardDetailView.Tab

    var body: some View {
        HStack(spacing: 4) {
            ForEach(CardDetailView.Tab.allCases, id: \.self) { tab in
                Button(action: { selectedTab = tab }) {
                    Text(tab.rawValue)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(selectedTab == tab ? .white : .secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(selectedTab == tab ? Color.perqViolet : Color.clear)
                        )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(4)
        .background(RoundedRectangle(cornerRadius: 24).fill(Color.perqElevated))
        .animation(.spring(), value: selectedTab)
    }
}

struct TabContentView: View {
    let selectedTab: CardDetailView.Tab
    let card: CreditCard

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            switch selectedTab {
            case .benefits:
                BenefitsView(benefits: card.benefits)
            case .cashback:
                CashbackView(categories: card.cashbackCategories)
            case .details:
                DetailsView(card: card)
            }
        }
    }
}

struct BenefitsView: View {
    let benefits: [Benefit]
    @State private var selectedFilter: BenefitType? = nil
    @State private var completedExpanded: Bool = true

    private var filtered: [Benefit] {
        guard let filter = selectedFilter else { return benefits }
        return benefits.filter { $0.type == filter }
    }

    private var active: [Benefit] { filtered.filter { !$0.isCompleted } }
    private var completed: [Benefit] { filtered.filter { $0.isCompleted } }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Filter chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    filterChip(label: "All", filter: nil)
                    filterChip(label: "Credits", filter: .credit)
                    filterChip(label: "Memberships", filter: .membership)
                    filterChip(label: "Status", filter: .status)
                }
            }

            if filtered.isEmpty {
                Text("No benefits for this filter")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .padding(.top, 8)
            } else {
                // Active benefits
                if active.isEmpty && completed.isEmpty {
                    Text("No benefits available for this card")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .padding(.top, 8)
                } else {
                    ForEach(active, id: \.id) { benefit in
                        BenefitRowView(benefit: benefit)
                    }

                    // Completed section
                    if !completed.isEmpty {
                        Button {
                            withAnimation(.spring(response: 0.3)) {
                                completedExpanded.toggle()
                            }
                        } label: {
                            HStack {
                                Text("Completed")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.secondary)
                                Text("\(completed.count)")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 7)
                                    .padding(.vertical, 2)
                                    .background(Capsule().fill(Color.green.opacity(0.7)))
                                Spacer()
                                Image(systemName: completedExpanded ? "chevron.up" : "chevron.down")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .buttonStyle(PlainButtonStyle())

                        if completedExpanded {
                            ForEach(completed, id: \.id) { benefit in
                                BenefitRowView(benefit: benefit)
                                    .opacity(0.6)
                            }
                        }
                    }
                }
            }
        }
    }

    private func filterChip(label: String, filter: BenefitType?) -> some View {
        let isSelected = selectedFilter == filter
        return Button { selectedFilter = filter } label: {
            Text(label)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(isSelected ? .white : .secondary)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(
                    Capsule().fill(isSelected ? Color.perqViolet : Color.perqRaised)
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct BenefitRowView: View {
    let benefit: Benefit

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text(benefit.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)

                    HStack {
                        Text(benefit.type.displayName)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Capsule().fill(typeColor.opacity(0.2)))
                            .foregroundColor(typeColor)

                        if let resetPeriod = benefit.resetPeriod {
                            Text(resetPeriod.displayName)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Capsule().fill(Color.gray.opacity(0.2)))
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Spacer()

                if let totalAmount = benefit.totalAmount {
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("$\(Int(benefit.remainingAmount))")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)

                        Text("of $\(Int(totalAmount))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Text(benefit.benefitDescription)
                .font(.body)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            if let total = benefit.totalAmount, total > 0 {
                VStack(alignment: .leading, spacing: 6) {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.perqRaised)
                            RoundedRectangle(cornerRadius: 4)
                                .fill(LinearGradient(
                                    colors: [categoryColor.opacity(0.8), categoryColor],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ))
                                .frame(width: geo.size.width * min(benefit.progressPercentage, 1.0))
                        }
                    }
                    .frame(height: 8)

                    HStack {
                        Text("Used: $\(Int(benefit.usedAmount))")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Spacer()

                        Text("Remaining: $\(Int(benefit.remainingAmount))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            PeriodButtonsView(benefit: benefit, categoryColor: categoryColor)
        }
        .padding()
        .background(Color.perqElevated)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
    }

    private var typeColor: Color {
        switch benefit.type {
        case .credit: return .perqMint
        case .membership: return .perqSky
        case .status: return .perqLavender
        }
    }

    private var categoryColor: Color {
        Color.perqCategory(benefit.categoryTag)
    }
}

struct PeriodButtonsView: View {
    let benefit: Benefit
    let categoryColor: Color

    private var yearString: String {
        String(Calendar.current.component(.year, from: Date()))
    }

    var body: some View {
        switch benefit.resetPeriod {
        case .monthly:
            monthlyButtons
        case .quarterly:
            quarterlyButtons
        case .semiAnnual:
            semiAnnualButtons
        default:
            singleButton
        }
    }

    private var monthlyButtons: some View {
        let monthLabels = ["Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"]
        return VStack(spacing: 4) {
            HStack(spacing: 4) {
                ForEach(1...6, id: \.self) { month in
                    periodButton(
                        label: monthLabels[month - 1],
                        periodId: "\(yearString)-M\(String(format: "%02d", month))"
                    )
                }
            }
            HStack(spacing: 4) {
                ForEach(7...12, id: \.self) { month in
                    periodButton(
                        label: monthLabels[month - 1],
                        periodId: "\(yearString)-M\(String(format: "%02d", month))"
                    )
                }
            }
        }
    }

    private var quarterlyButtons: some View {
        HStack(spacing: 8) {
            ForEach(1...4, id: \.self) { quarter in
                periodButton(
                    label: "Q\(quarter)",
                    periodId: "\(yearString)-Q\(quarter)"
                )
            }
        }
    }

    private var semiAnnualButtons: some View {
        HStack(spacing: 8) {
            ForEach(["H1", "H2"], id: \.self) { half in
                periodButton(
                    label: half,
                    periodId: "\(yearString)-\(half)"
                )
            }
        }
    }

    private var singleButton: some View {
        let periodId = "\(yearString)-A"
        let isClaimed = benefit.claimedPeriods.contains(periodId)
        return Button {
            benefit.togglePeriod(periodId)
        } label: {
            Text(isClaimed ? "Claimed" : "Mark as Claimed")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(isClaimed ? .white : .secondary)
                .frame(maxWidth: .infinity)
                .frame(height: 34)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isClaimed ? Color.perqMint : Color.perqRaised)
                )
        }
        .buttonStyle(PlainButtonStyle())
    }

    private func periodButton(label: String, periodId: String) -> some View {
        let isClaimed = benefit.claimedPeriods.contains(periodId)
        return Button {
            benefit.togglePeriod(periodId)
        } label: {
            Text(label)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(isClaimed ? Color.perqInk : .secondary)
                .frame(maxWidth: .infinity)
                .frame(height: 30)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(isClaimed ? Color.perqMint : Color.perqRaised)
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct CashbackView: View {
    let categories: [CashbackCategory]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if categories.isEmpty {
                Text("No cashback categories available for this card")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .padding(.top, 20)
            } else {
                ForEach(categories, id: \.id) { category in
                    CashbackRowView(category: category)
                }
            }
        }
    }
}

struct CashbackRowView: View {
    let category: CashbackCategory

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(category.category)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .lineLimit(2)

                Text(category.unit.displayName)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Text("\(category.rate, specifier: "%.1f")\(category.unit == .percentCashback ? "%" : "")")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.perqSky)
        }
        .padding()
        .background(Color.perqElevated)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
    }
}

struct DetailsView: View {
    let card: CreditCard

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            DetailRow(title: "Card Name", value: card.name)
            Divider().background(Color.white.opacity(0.08))
            DetailRow(title: "Issuer", value: card.issuer)
            Divider().background(Color.white.opacity(0.08))
            DetailRow(title: "Network", value: card.network.uppercased())
            Divider().background(Color.white.opacity(0.08))
            DetailRow(title: "Annual Fee", value: card.annualFee == 0 ? "No Fee" : "$\(Int(card.annualFee))/yr")
            Divider().background(Color.white.opacity(0.08))
            DetailRow(title: "Date Added", value: dateFormatter.string(from: card.dateAdded))
            Divider().background(Color.white.opacity(0.08))
            DetailRow(title: "Status", value: card.isActive ? "Active" : "Inactive")
        }
        .padding(.horizontal)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color.perqElevated))
    }
}

struct DetailRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(title)
                .font(.body)
                .foregroundColor(.secondary)

            Spacer()

            Text(value)
                .font(.body)
                .fontWeight(.medium)
                .foregroundColor(.primary)
        }
        .padding(.vertical, 12)
    }
}

private let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .none
    return formatter
}()
