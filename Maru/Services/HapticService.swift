import UIKit

@MainActor
final class HapticService {
    static let shared = HapticService()

    private init() {}

    func selection() {
        guard UserPreferences.hapticFeedbackEnabled else { return }
        UISelectionFeedbackGenerator().selectionChanged()
    }

    func success() {
        notify(.success)
    }

    func warning() {
        notify(.warning)
    }

    func error() {
        notify(.error)
    }

    func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .light) {
        guard UserPreferences.hapticFeedbackEnabled else { return }
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }

    private func notify(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        guard UserPreferences.hapticFeedbackEnabled else { return }
        UINotificationFeedbackGenerator().notificationOccurred(type)
    }
}
