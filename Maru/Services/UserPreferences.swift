import Foundation

enum UserPreferences {
    static let hapticFeedbackKey = "hapticFeedback"
    static let soundEffectsKey = "soundEffects"
    static let dailyReminderKey = "dailyReminder"
    static let reminderTimeKey = "reminderTime"

    static var hapticFeedbackEnabled: Bool {
        bool(for: hapticFeedbackKey, defaultValue: true)
    }

    static var soundEffectsEnabled: Bool {
        bool(for: soundEffectsKey, defaultValue: true)
    }

    private static func bool(for key: String, defaultValue: Bool) -> Bool {
        guard UserDefaults.standard.object(forKey: key) != nil else {
            return defaultValue
        }
        return UserDefaults.standard.bool(forKey: key)
    }
}
