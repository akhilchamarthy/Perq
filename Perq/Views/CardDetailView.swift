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
        ScrollView {
            VStack(spacing: 0) {
                CardHeaderView(card: card)
                
                TabSelectorView(selectedTab: $selectedTab)
                
                TabContentView(
                        selectedTab: selectedTab,
                        card: card,
                        selectedBenefit: $selectedBenefit,
                        showingUsageSheet: $showingUsageSheet
                    )
            }
        }
        .padding()
        .background(Color(.systemGroupedBackground))
        .navigationBarTitleDisplayMode(.inline)
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
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(hex: card.cardColor) ?? .gray)
                    .frame(width: 60, height: 40)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.3), lineWidth: 2)
                    )
                    .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(card.name)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text(card.issuer)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text(card.network.uppercased())
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(4)
                }
                
                Spacer()
            }
            
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
                
                VStack(alignment: .trailing, spacing: 4) {
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
                    Text("Cashback Categories")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(card.cashbackCategories.count)")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                }
            }
            
            if let annualFeeNote = card.annualFeeNote, !annualFeeNote.isEmpty {
                Text(annualFeeNote)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 4)
            }
            
            // Benefit Value Bar
            if card.totalPotentialValue > 0 {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Benefit Value")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Text("$\(Int(card.totalBenefitValue)) / $\(Int(card.totalPotentialValue))")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.blue)
                    }
                    
                    ProgressView(value: card.benefitUsagePercentage) {
                        Text("")
                    } currentValueLabel: {
                        Text("\(Int(card.benefitUsagePercentage * 100))%")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .progressViewStyle(LinearProgressViewStyle(tint: .green))
                    
                    Text("You've extracted $\(Int(card.totalBenefitValue)) in value from this card's benefits")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 8)
                .padding(.horizontal, 4)
            }
        }
        .padding()
        .background(Color(.systemBackground))
    }
}

struct TabSelectorView: View {
    @Binding var selectedTab: CardDetailView.Tab
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(CardDetailView.Tab.allCases, id: \.self) { tab in
                Button(action: { selectedTab = tab }) {
                    Text(tab.rawValue)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(selectedTab == tab ? .blue : .secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            selectedTab == tab ? Color.blue.opacity(0.1) : Color.clear
                        )
                        .overlay(
                            Rectangle()
                                .fill(Color.blue)
                                .frame(height: 2)
                                .opacity(selectedTab == tab ? 1 : 0),
                            alignment: .bottom
                        )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .background(Color(.systemBackground))
        .border(Color(.separator), width: 0.5)
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
        .padding()
        .background(Color(.systemGroupedBackground))
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
                VStack(alignment: .leading, spacing: 4) {
                    Text(benefit.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    HStack {
                        Text(benefit.type.displayName)
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(typeColor.opacity(0.1))
                            .foregroundColor(typeColor)
                            .cornerRadius(4)
                        
                        if let resetPeriod = benefit.resetPeriod {
                            Text(resetPeriod.displayName)
                                .font(.caption)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.gray.opacity(0.1))
                                .foregroundColor(.secondary)
                                .cornerRadius(4)
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
                VStack(alignment: .leading, spacing: 12) {
                    ProgressView(value: benefit.progressPercentage) {
                        Text("")
                    } currentValueLabel: {
                        Text("\(Int(benefit.progressPercentage * 100))%")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .progressViewStyle(LinearProgressViewStyle(tint: categoryColor))
                    
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
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        
                        Spacer()
                        
                        if benefit.resetPeriod != nil {
                            Button("Reset") {
                                benefit.resetUsage()
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
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
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

struct DetailsView: View {
    let card: CreditCard
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            DetailRow(title: "Card Name", value: card.name)
            DetailRow(title: "Issuer", value: card.issuer)
            DetailRow(title: "Network", value: card.network.uppercased())
            DetailRow(title: "Annual Fee", value: card.annualFee == 0 ? "No Fee" : "$\(Int(card.annualFee))/yr")
            DetailRow(title: "Date Added", value: dateFormatter.string(from: card.dateAdded))
            DetailRow(title: "Status", value: card.isActive ? "Active" : "Inactive")
        }
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
        .padding(.vertical, 8)
    }
}

private let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .none
    return formatter
}()
