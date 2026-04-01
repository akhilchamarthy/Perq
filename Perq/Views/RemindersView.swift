import SwiftUI
import SwiftData
import UserNotifications

struct RemindersView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var benefitTracker: BenefitTracker
    @State private var showingNotificationSettings = false
    
    init(modelContext: ModelContext) {
        self._benefitTracker = StateObject(wrappedValue: BenefitTracker(modelContext: modelContext))
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    if benefitTracker.upcomingExpirations.isEmpty {
                        EmptyRemindersView()
                    } else {
                        ForEach(benefitTracker.upcomingExpirations) { expiration in
                            ExpirationCardView(expiration: expiration, benefitTracker: benefitTracker)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Reminders")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingNotificationSettings = true }) {
                        Image(systemName: "gear")
                    }
                }
            }
            .sheet(isPresented: $showingNotificationSettings) {
                NotificationSettingsView()
            }
            .onAppear {
                benefitTracker.checkForExpiredBenefits()
            }
        }
    }
}

struct EmptyRemindersView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "bell")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("No Upcoming Expirations")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            Text("You'll see notifications here when your benefits are about to reset")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 100)
    }
}

struct ExpirationCardView: View {
    let expiration: BenefitExpiration
    let benefitTracker: BenefitTracker
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(expiration.benefit.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    if let card = expiration.benefit.creditCard {
                        Text(card.name)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(expiration.urgencyLevel.description)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(expiration.urgencyLevel.color)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(expiration.urgencyLevel.color.opacity(0.1))
                        .cornerRadius(8)
                    
                    Text("\(expiration.daysUntilReset) day\(expiration.daysUntilReset == 1 ? "" : "s")")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                }
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Remaining Benefit")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack {
                    Text("$\(Int(expiration.benefit.remainingAmount))")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(expiration.benefit.remainingAmount > 0 ? .green : .red)
                    
                    Spacer()
                    
                    Text("of $\(Int(expiration.benefit.totalAmount ?? 0))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                ProgressView(value: expiration.benefit.progressPercentage)
                    .progressViewStyle(LinearProgressViewStyle(tint: expiration.urgencyLevel.color))
            }
            
            HStack {
                Button("Use Benefit") {
                    // TODO: Open benefit usage sheet
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                
                Spacer()
                
                Button("Reset Now") {
                    benefitTracker.resetBenefit(expiration.benefit)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        .overlay(
            Rectangle()
                .fill(expiration.urgencyLevel.color)
                .frame(width: 4),
            alignment: .leading
        )
    }
}

struct NotificationSettingsView: View {
    @State private var notificationsEnabled = false
    @State private var advanceReminderDays = 3
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Notification Settings")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Configure when to receive reminders about your benefit expirations")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                VStack(spacing: 20) {
                    Toggle("Enable Notifications", isOn: $notificationsEnabled)
                        .onChange(of: notificationsEnabled) { _, newValue in
                            if newValue {
                                UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
                                        DispatchQueue.main.async {
                                            notificationsEnabled = granted
                                        }
                                    }
                            }
                        }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Advance Reminder")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Picker("Days before reset", selection: $advanceReminderDays) {
                            Text("1 day").tag(1)
                            Text("3 days").tag(3)
                            Text("7 days").tag(7)
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Notification Types")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            NotificationTypeRow(title: "Benefit expiring soon", description: "Get notified when benefits are about to reset", enabled: true)
                            NotificationTypeRow(title: "Usage milestones", description: "Track when you've used 50%, 80% of benefits", enabled: false)
                            NotificationTypeRow(title: "Monthly summary", description: "Get a monthly overview of your benefits", enabled: false)
                        }
                    }
                }
                
                Spacer()
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        // Save settings
                    }
                }
            }
        }
    }
}

struct NotificationTypeRow: View {
    let title: String
    let description: String
    let enabled: Bool
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                    .fontWeight(.medium)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Toggle("", isOn: .constant(enabled))
                .disabled(true)
        }
    }
}
