import SwiftUI

struct SettingsView: View {
    @AppStorage("isDarkMode") private var isDarkMode = true

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {

                    // Appearance
                    SettingsSection(title: "Appearance") {
                        SettingsToggleRow(
                            icon: isDarkMode ? "moon.fill" : "sun.max.fill",
                            iconColor: isDarkMode ? .perqLavender : .perqAmber,
                            title: "Dark Mode",
                            isOn: $isDarkMode
                        )
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
        }
    }
}

// MARK: - Section container

struct SettingsSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title.uppercased())
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.perqSecondaryText)
                .padding(.horizontal, 4)

            VStack(spacing: 0) {
                content
            }
            .background(Color.perqElevated)
            .cornerRadius(16)
        }
    }
}

// MARK: - Toggle row

struct SettingsToggleRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(iconColor)
            }

            Text(title)
                .font(.body)
                .foregroundColor(.perqGhost)

            Spacer()

            Toggle("", isOn: $isOn)
                .tint(.perqLavender)
                .labelsHidden()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}
