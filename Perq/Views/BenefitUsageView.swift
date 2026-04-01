import SwiftUI
import SwiftData
import UserNotifications

struct BenefitUsageView: View {
    let benefit: Benefit
    @State private var showingUsageSheet = false
    @State private var usageAmount = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Usage Tracking")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    if let resetPeriod = benefit.resetPeriod {
                        Text("Resets \(resetPeriod.displayName.lowercased())")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Button(action: { showingUsageSheet = true }) {
                    Text("Add Usage")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.blue)
                        .cornerRadius(8)
                }
                .disabled(benefit.totalAmount == nil || benefit.totalAmount! <= 0)
            }
            
            if benefit.totalAmount != nil && benefit.totalAmount! > 0 {
                VStack(spacing: 12) {
                    ProgressView(value: benefit.progressPercentage) {
                        Text("")
                    } currentValueLabel: {
                        Text("\(Int(benefit.progressPercentage * 100))% used")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .progressViewStyle(LinearProgressViewStyle(tint: progressColor))
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Used")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Text("$\(Int(benefit.usedAmount))")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("Remaining")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Text("$\(Int(benefit.remainingAmount))")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(benefit.remainingAmount > 0 ? .green : .red)
                        }
                    }
                    
                    if benefit.lastResetDate != nil && benefit.resetPeriod != nil {
                        ResetInfoView(benefit: benefit)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
        }
        .sheet(isPresented: $showingUsageSheet) {
            UsageInputSheet(
                benefit: benefit,
                usageAmount: $usageAmount,
                showingAlert: $showingAlert,
                alertMessage: $alertMessage
            )
        }
        .alert("Usage Update", isPresented: $showingAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
    }
    
    private var progressColor: Color {
        let percentage = benefit.progressPercentage
        if percentage < 0.5 {
            return .green
        } else if percentage < 0.8 {
            return .orange
        } else {
            return .red
        }
    }
}

struct ResetInfoView: View {
    let benefit: Benefit
    
    var body: some View {
        HStack {
            Image(systemName: "clock")
                .font(.caption)
                .foregroundColor(.secondary)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Last reset: \(formatDate(benefit.lastResetDate ?? Date()))")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                if let nextReset = nextResetDate {
                    let daysUntil = daysUntil(nextReset)
                    Text("Next reset: \(formatDate(nextReset)) (\(daysUntil) day\(daysUntil == 1 ? "" : "s"))")
                        .font(.caption2)
                        .foregroundColor(daysUntil <= 7 ? .orange : .secondary)
                }
            }
            
            Spacer()
            
            if daysUntil(nextResetDate ?? Date()) <= 7 {
                Button("Reset Now") {
                    benefit.resetUsage()
                }
                .font(.caption2)
                .foregroundColor(.blue)
            }
        }
    }
    
    private var nextResetDate: Date? {
        guard let lastResetDate = benefit.lastResetDate,
              let resetPeriod = benefit.resetPeriod else { return nil }
        
        let calendar = Calendar.current
        
        switch resetPeriod {
        case .monthly:
            return calendar.date(byAdding: .month, value: 1, to: lastResetDate)
        case .quarterly:
            return calendar.date(byAdding: .month, value: 3, to: lastResetDate)
        case .semiAnnual:
            return calendar.date(byAdding: .month, value: 6, to: lastResetDate)
        case .annual:
            return calendar.date(byAdding: .year, value: 1, to: lastResetDate)
        case .quadrennial:
            return calendar.date(byAdding: .year, value: 4, to: lastResetDate)
        case .oneTime:
            return nil
        }
    }
    
    private func daysUntil(_ date: Date) -> Int {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.day], from: now, to: date)
        return max(0, components.day ?? 0)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: date)
    }
}

struct UsageInputSheet: View {
    let benefit: Benefit
    @Binding var usageAmount: String
    @Binding var showingAlert: Bool
    @Binding var alertMessage: String
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
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
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Usage Amount")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
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
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func addUsage() {
        guard let amount = Double(usageAmount), amount > 0 else {
            alertMessage = "Please enter a valid amount"
            showingAlert = true
            return
        }
        
        let newTotal = benefit.usedAmount + amount
        
        if let totalAmount = benefit.totalAmount, newTotal > totalAmount {
            alertMessage = "This would exceed your total benefit amount. Maximum remaining: $\(Int(benefit.remainingAmount))"
            showingAlert = true
            return
        }
        
        benefit.useAmount(amount)
        usageAmount = ""
        dismiss()
    }
}
