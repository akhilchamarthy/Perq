import SwiftUI
import SwiftData

struct CardDetailView: View {
    let card: CreditCard
    @State private var selectedTab: Tab = .benefits
    @State private var showingUsageSheet = false
    @State private var selectedBenefit: Benefit?
    @State private var usageAmount = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""

    enum Tab: String, CaseIterable {
        case benefits = "Benefits"
        case cashback = "Cashback"
        case details = "Details"
    }

    var body: some View {
        ZStack {
            Color(hex: "080810").ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    CardHeaderView(card: card)

                    TabSelectorView(selectedTab: $selectedTab)

                    TabContentView(
                        selectedTab: selectedTab,
                        card: card,
                        selectedBenefit: $selectedBenefit,
                        showingUsageSheet: $showingUsageSheet
                    )
                }
                .padding()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color(hex: "080810") ?? .black, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Edit") {
                    // TODO: Implement edit functionality
                }
            }
        }
        .sheet(isPresented: $showingUsageSheet) {
            if let benefit = selectedBenefit {
                NavigationView {
                    VStack(spacing: 24) {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Track Usage")
                                .font(.title2)
                                .fontWeight(.bold)

                            Text(benefit.name)
                                .font(.headline)
                                .foregroundColor(.primary)

                            Text("Current usage: $\(Int(benefit.usedAmount)) of $\(Int(benefit.totalAmount ?? 0))")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        VStack(alignment: .leading, spacing: 20) {
                            Text("Usage Amount")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)

                            TextField("Enter amount", text: $usageAmount)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .keyboardType(.decimalPad)

                            Text("Enter the amount you want to add to your usage for this benefit.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        Button(action: addUsage) {
                            Text("Add Usage")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(12)
                        }
                        .disabled(usageAmount.isEmpty || Double(usageAmount) == nil)
                    }
                    .padding()
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button("Cancel") {
                                showingUsageSheet = false
                                usageAmount = ""
                                selectedBenefit = nil
                            }
                        }
                    }
                }
            }
        }
        .alert("Usage Update", isPresented: $showingAlert) {
            Text(alertMessage)
        } message: {
            Text("OK")
        }
    }

    private func addUsage() {
        guard let amount = Double(usageAmount), amount > 0 else {
            alertMessage = "Please enter a valid amount"
            showingAlert = true
            return
        }

        guard let benefit = selectedBenefit else { return }

        let newTotal = benefit.usedAmount + amount

        if let totalAmount = benefit.totalAmount, newTotal > totalAmount {
            alertMessage = "This would exceed your total benefit amount. Maximum remaining: $\(Int(benefit.remainingAmount))"
            showingAlert = true
            return
        }

        benefit.useAmount(amount)
        usageAmount = ""
        showingUsageSheet = false
        selectedBenefit = nil
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
            .background(RoundedRectangle(cornerRadius: 16).fill(Color(hex: "12121E") ?? Color(.systemBackground)))

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
                            .foregroundColor(.blue)
                    }

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.white.opacity(0.1))
                            RoundedRectangle(cornerRadius: 4)
                                .fill(LinearGradient(
                                    colors: [.green, .blue],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ))
                                .frame(width: geo.size.width * min(card.benefitUsagePercentage, 1.0))
                        }
                    }
                    .frame(height: 8)

                    Text("You've extracted $\(Int(card.totalBenefitValue)) in value from this card's benefits")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(RoundedRectangle(cornerRadius: 16).fill(Color(hex: "12121E") ?? Color(.systemBackground)))
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
                                .fill(selectedTab == tab ? Color.blue : Color.clear)
                        )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(4)
        .background(RoundedRectangle(cornerRadius: 24).fill(Color(hex: "12121E") ?? Color(.systemBackground)))
        .animation(.spring(), value: selectedTab)
    }
}

struct TabContentView: View {
    let selectedTab: CardDetailView.Tab
    let card: CreditCard
    @Binding var selectedBenefit: Benefit?
    @Binding var showingUsageSheet: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            switch selectedTab {
            case .benefits:
                BenefitsView(
                    benefits: card.benefits,
                    selectedBenefit: $selectedBenefit,
                    showingUsageSheet: $showingUsageSheet
                )
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
    @Binding var selectedBenefit: Benefit?
    @Binding var showingUsageSheet: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if benefits.isEmpty {
                Text("No benefits available for this card")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .padding(.top, 20)
            } else {
                ForEach(benefits, id: \.id) { benefit in
                    BenefitRowView(
                        benefit: benefit,
                        selectedBenefit: $selectedBenefit,
                        showingUsageSheet: $showingUsageSheet
                    )
                }
            }
        }
    }
}

struct BenefitRowView: View {
    let benefit: Benefit
    @Binding var selectedBenefit: Benefit?
    @Binding var showingUsageSheet: Bool

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

            if benefit.totalAmount != nil && benefit.totalAmount! > 0 {
                VStack(alignment: .leading, spacing: 10) {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.white.opacity(0.1))
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

                    HStack {
                        Button("Add Usage") {
                            selectedBenefit = benefit
                            showingUsageSheet = true
                        }
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(categoryColor)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Capsule().fill(categoryColor.opacity(0.2)))

                        Spacer()

                        if benefit.resetPeriod != nil {
                            Button("Reset") {
                                benefit.resetUsage()
                            }
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Capsule().fill(Color.secondary.opacity(0.15)))
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(hex: "12121E") ?? Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
    }

    private var typeColor: Color {
        switch benefit.type {
        case .credit: return .green
        case .membership: return .blue
        case .status: return .purple
        }
    }

    private var categoryColor: Color {
        switch benefit.categoryTag {
        case "travel": return .blue
        case "dining": return .orange
        case "shopping": return .purple
        case "wellness": return .green
        case "entertainment": return .pink
        case "other": return .gray
        default: return .primary
        }
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
                .foregroundColor(.blue)
        }
        .padding()
        .background(Color(hex: "12121E") ?? Color(.systemBackground))
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
        .background(RoundedRectangle(cornerRadius: 16).fill(Color(hex: "12121E") ?? Color(.systemBackground)))
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
