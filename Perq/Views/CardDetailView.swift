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

    private var topRewardLabel: String {
        guard let top = card.cashbackCategories.max(by: { $0.rate < $1.rate }) else { return "—" }
        let whole = Int(top.rate)
        switch top.unit {
        case .percentCashback: return "\(whole)%"
        case .pointsPerDollar: return "\(whole)X"
        case .milesPerDollar:  return "\(whole)X"
        }
    }

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
                        .foregroundColor(.white.opacity(0.55))
                    Text(card.annualFee == 0 ? "No Fee" : "$\(Int(card.annualFee))/yr")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(card.annualFee == 0 ? .perqMint : .white)
                }

                Spacer()

                VStack(alignment: .center, spacing: 4) {
                    Text("Benefits")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.55))
                    Text("\(card.benefits.count)")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("Top Reward")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.55))
                    Text(topRewardLabel)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.perqSky)
                }
            }
            .padding()
            .background(RoundedRectangle(cornerRadius: 16).fill(Color.perqElevated))

            if let annualFeeNote = card.annualFeeNote, !annualFeeNote.isEmpty {
                Text(annualFeeNote)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.55))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            // Benefit value progress bar
            if card.totalPotentialValue > 0 {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Benefit Value")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white.opacity(0.55))

                        Spacer()

                        Text("$\(Int(card.totalBenefitValue)) / $\(Int(card.totalPotentialValue))")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
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
                        .foregroundColor(.white.opacity(0.55))
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
                        .foregroundColor(selectedTab == tab ? .white : .white.opacity(0.55))
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
                    .foregroundColor(.white.opacity(0.55))
                    .padding(.top, 8)
            } else {
                // Active benefits
                if active.isEmpty && completed.isEmpty {
                    Text("No benefits available for this card")
                        .font(.body)
                        .foregroundColor(.white.opacity(0.55))
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
                                    .foregroundColor(.white.opacity(0.55))
                                Text("\(completed.count)")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 7)
                                    .padding(.vertical, 2)
                                    .background(Capsule().fill(Color.perqMint.opacity(0.7)))
                                Spacer()
                                Image(systemName: completedExpanded ? "chevron.up" : "chevron.down")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.55))
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
                .foregroundColor(isSelected ? .white : .white.opacity(0.55))
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
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // ── Collapsed row (always visible) ──────────────────────────
            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: 12) {
                    // Category colour dot
                    Circle()
                        .fill(categoryColor)
                        .frame(width: 8, height: 8)

                    VStack(alignment: .leading, spacing: 3) {
                        Text(benefit.name)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.perqGhost)

                        HStack(spacing: 6) {
                            Text(benefit.type.displayName)
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Capsule().fill(typeColor.opacity(0.18)))
                                .foregroundColor(typeColor)

                            if let resetPeriod = benefit.resetPeriod {
                                Text(resetPeriod.displayName)
                                    .font(.caption2)
                                    .foregroundColor(.white.opacity(0.55))
                            }
                        }
                    }

                    Spacer()

                    // Remaining amount or membership indicator
                    if let totalAmount = benefit.totalAmount, totalAmount > 0 {
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("$\(Int(benefit.remainingAmount))")
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(benefit.isCompleted ? .perqMint : .perqGhost)
                            Text("left")
                                .font(.caption2)
                                .foregroundColor(.white.opacity(0.55))
                        }
                    } else {
                        Image(systemName: benefit.isCompleted ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(benefit.isCompleted ? .perqMint : .white.opacity(0.55))
                            .font(.title3)
                    }

                    Image(systemName: "chevron.down")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.55))
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
            }
            .buttonStyle(PlainButtonStyle())

            // Slim progress bar always visible when there's a value
            if let total = benefit.totalAmount, total > 0 {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Rectangle().fill(Color.perqRaised)
                        Rectangle()
                            .fill(LinearGradient(
                                colors: [categoryColor.opacity(0.8), categoryColor],
                                startPoint: .leading,
                                endPoint: .trailing
                            ))
                            .frame(width: geo.size.width * min(benefit.progressPercentage, 1.0))
                    }
                }
                .frame(height: 2)
            }

            // ── Expanded detail ──────────────────────────────────────────
            if isExpanded {
                VStack(alignment: .leading, spacing: 14) {
                    // Description
                    Text(benefit.benefitDescription)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.55))
                        .fixedSize(horizontal: false, vertical: true)

                    // Used / remaining breakdown
                    if let total = benefit.totalAmount, total > 0 {
                        HStack {
                            Label("Used: $\(Int(benefit.usedAmount))", systemImage: "minus.circle")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.55))
                            Spacer()
                            Label("Remaining: $\(Int(benefit.remainingAmount))", systemImage: "plus.circle")
                                .font(.caption)
                                .foregroundColor(categoryColor)
                        }
                    }

                    // Period buttons
                    PeriodButtonsView(benefit: benefit, categoryColor: categoryColor)
                }
                .padding(.horizontal, 14)
                .padding(.top, 10)
                .padding(.bottom, 14)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(Color.perqElevated)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
        .clipped()
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

    // MARK: - Current date components
    private let cal = Calendar.current
    private var now: Date { Date() }
    private var yearString: String { String(cal.component(.year, from: now)) }
    private var currentMonth: Int  { cal.component(.month, from: now) }
    private var currentQuarter: Int { (currentMonth - 1) / 3 + 1 }
    private var currentHalf: Int   { currentMonth <= 6 ? 1 : 2 }

    private var isEnrollmentType: Bool {
        benefit.type == .membership || benefit.type == .status
    }

    // MARK: - Period state

    enum PeriodState { case past, current, future }

    private func monthState(_ m: Int) -> PeriodState {
        m < currentMonth ? .past : m == currentMonth ? .current : .future
    }
    private func quarterState(_ q: Int) -> PeriodState {
        q < currentQuarter ? .past : q == currentQuarter ? .current : .future
    }
    private func halfState(_ h: Int) -> PeriodState {
        h < currentHalf ? .past : h == currentHalf ? .current : .future
    }

    // MARK: - Body

    var body: some View {
        switch benefit.resetPeriod {
        case .monthly:   monthlyButtons
        case .quarterly: quarterlyButtons
        case .semiAnnual: semiAnnualButtons
        default:         singleButton
        }
    }

    // MARK: - Monthly (2 rows of 6)

    private var monthlyButtons: some View {
        let labels = ["Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"]
        return VStack(spacing: 4) {
            HStack(spacing: 4) {
                ForEach(1...6, id: \.self) { m in
                    periodButton(label: labels[m-1],
                                 periodId: "\(yearString)-M\(String(format: "%02d", m))",
                                 state: monthState(m))
                }
            }
            HStack(spacing: 4) {
                ForEach(7...12, id: \.self) { m in
                    periodButton(label: labels[m-1],
                                 periodId: "\(yearString)-M\(String(format: "%02d", m))",
                                 state: monthState(m))
                }
            }
        }
    }

    // MARK: - Quarterly

    private var quarterlyButtons: some View {
        HStack(spacing: 8) {
            ForEach(1...4, id: \.self) { q in
                periodButton(label: "Q\(q)",
                             periodId: "\(yearString)-Q\(q)",
                             state: quarterState(q))
            }
        }
    }

    // MARK: - Semi-annual

    private var semiAnnualButtons: some View {
        HStack(spacing: 8) {
            ForEach([("H1", 1), ("H2", 2)], id: \.0) { label, half in
                periodButton(label: label,
                             periodId: "\(yearString)-\(label)",
                             state: halfState(half))
            }
        }
    }

    // MARK: - Single (annual / one-time / etc.)

    private var singleButton: some View {
        let periodId = "\(yearString)-A"
        let isClaimed = benefit.claimedPeriods.contains(periodId)
        let label = isEnrollmentType
            ? (isClaimed ? "Enrolled"  : "Mark as Enrolled")
            : (isClaimed ? "Claimed"   : "Mark as Claimed")
        return Button { benefit.togglePeriod(periodId) } label: {
            Text(label)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(isClaimed ? .white : .white.opacity(0.7))
                .frame(maxWidth: .infinity)
                .frame(height: 34)
                .background(RoundedRectangle(cornerRadius: 8)
                    .fill(isClaimed ? Color.perqMint : Color.perqRaised))
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - Shared period button

    private func periodButton(label: String, periodId: String, state: PeriodState) -> some View {
        let isClaimed = benefit.claimedPeriods.contains(periodId)
        let isFuture  = state == .future
        let isMissed  = state == .past && !isClaimed

        let bg: Color = {
            if isFuture { return Color.perqRaised.opacity(0.3) }
            if isClaimed { return Color.perqMint }
            if isMissed  { return Color.perqRose.opacity(0.25) }
            return Color.perqRaised
        }()

        let fg: Color = {
            if isFuture  { return .white.opacity(0.2) }
            if isClaimed { return Color.perqInk }
            if isMissed  { return Color.perqRose }
            return .white.opacity(0.7)
        }()

        return Button {
            benefit.togglePeriod(periodId)
        } label: {
            Text(label)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(fg)
                .frame(maxWidth: .infinity)
                .frame(height: 30)
                .background(RoundedRectangle(cornerRadius: 6).fill(bg))
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(isFuture)
    }
}

struct CashbackView: View {
    let categories: [CashbackCategory]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if categories.isEmpty {
                Text("No cashback categories available for this card")
                    .font(.body)
                    .foregroundColor(.white.opacity(0.55))
                    .padding(.top, 20)
            } else {
                ForEach(categories.sorted { $0.rate > $1.rate }, id: \.id) { category in
                    CashbackRowView(category: category)
                }
            }
        }
    }
}

struct CashbackRowView: View {
    let category: CashbackCategory

    private var rateLabel: String {
        let whole = Int(category.rate)
        switch category.unit {
        case .percentCashback:  return "\(whole)% cashback"
        case .pointsPerDollar:  return "\(whole)X points"
        case .milesPerDollar:   return "\(whole)X miles"
        }
    }

    var body: some View {
        HStack {
            Text(category.category)
                .font(.body)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .lineLimit(2)

            Spacer()

            Text(rateLabel)
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
                .foregroundColor(.white.opacity(0.55))

            Spacer()

            Text(value)
                .font(.body)
                .fontWeight(.medium)
                .foregroundColor(.white)
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
