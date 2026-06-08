import SwiftUI

// MARK: - SettingsView

struct SettingsView: View {
    @AppStorage("hapticFeedback") private var hapticFeedback = true
    @AppStorage("soundEffects") private var soundEffects = true
    @AppStorage("dailyReminder") private var dailyReminder = false
    @AppStorage("reminderTime") private var reminderTimeInterval: TimeInterval = 32400 // Default 9 AM
    @State private var showResetAlert = false
    @State private var reminderDate: Date = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date()

    private let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    private let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"

    var body: some View {
        NavigationStack {
            List {
                // Haptic feedback toggle
                Section {
                    Toggle(isOn: $hapticFeedback) {
                        SettingsRow(
                            icon: "hand.tap.fill",
                            title: "Haptic Feedback",
                            color: Color(hex: "8B5CF6")
                        )
                    }
                    .toggleStyle(SwitchToggleStyle(tint: Color(hex: "8B5CF6")))
                } header: {
                    Text("Feedback")
                }

                // Sound effects toggle
                Section {
                    Toggle(isOn: $soundEffects) {
                        SettingsRow(
                            icon: "speaker.wave.2.fill",
                            title: "Sound Effects",
                            color: Color(hex: "FF7A1A")
                        )
                    }
                    .toggleStyle(SwitchToggleStyle(tint: Color(hex: "8B5CF6")))
                }

                // Daily reminder toggle with time picker
                Section {
                    Toggle(isOn: $dailyReminder) {
                        SettingsRow(
                            icon: "bell.fill",
                            title: "Daily Reminder",
                            color: Color(hex: "34D399")
                        )
                    }
                    .toggleStyle(SwitchToggleStyle(tint: Color(hex: "8B5CF6")))

                    if dailyReminder {
                        DatePicker(
                            "Reminder Time",
                            selection: $reminderDate,
                            displayedComponents: .hourAndMinute
                        )
                        .datePickerStyle(.compact)
                        .padding(.leading, 44)
                        .onChange(of: reminderDate) { _, newValue in
                            reminderTimeInterval = newValue.timeIntervalSince1970
                        }
                        .onAppear {
                            reminderDate = Date(timeIntervalSince1970: reminderTimeInterval)
                        }
                    }
                } header: {
                    Text("Notifications")
                }

                // Reset progress button
                Section {
                    Button(action: {
                        showResetAlert = true
                    }) {
                        HStack {
                            SettingsRow(
                                icon: "arrow.counterclockwise",
                                title: "Reset Progress",
                                color: Color(hex: "ef4444")
                            )
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(Color(hex: "8c867d"))
                        }
                    }
                } header: {
                    Text("Data")
                } footer: {
                    Text("This will reset all your learning progress. This action cannot be undone.")
                }

                // Version info
                Section {
                    HStack {
                        Text("Version")
                            .font(.system(size: 16, weight: .regular))
                            .foregroundColor(Color(hex: "22211F"))
                        Spacer()
                        Text("\(appVersion) (\(buildNumber))")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(Color(hex: "8c867d"))
                    }
                } header: {
                    Text("About")
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(Color(hex: "f7f5f1"))
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .alert("Reset Progress", isPresented: $showResetAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Reset", role: .destructive) {
                    resetProgress()
                }
            } message: {
                Text("Are you sure you want to reset all your learning progress? This action cannot be undone.")
            }
        }
    }

    private func resetProgress() {
        // Reset UserDefaults
        UserDefaults.standard.removeObject(forKey: "hapticFeedback")
        UserDefaults.standard.removeObject(forKey: "soundEffects")
        UserDefaults.standard.removeObject(forKey: "dailyReminder")
        UserDefaults.standard.removeObject(forKey: "reminderTime")

        // Reset to defaults
        hapticFeedback = true
        soundEffects = true
        dailyReminder = false
        reminderTimeInterval = 32400
        reminderDate = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date()

        // TODO: Reset database progress
        // This would typically call a method on SharedDatabase to clear progress
    }
}

// MARK: - SettingsRow

private struct SettingsRow: View {
    let icon: String
    let title: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(color)
                .frame(width: 28, height: 28)
                .background(color.opacity(0.1))
                .cornerRadius(6)

            Text(title)
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(Color(hex: "22211F"))
        }
    }
}

// MARK: - Previews

#Preview("SettingsView") {
    SettingsView()
}