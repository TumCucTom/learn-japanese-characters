import UIKit

@MainActor
protocol HapticFeedbackPerforming: AnyObject {
    func selectionChanged()
    func notificationOccurred(_ type: UINotificationFeedbackGenerator.FeedbackType)
    func impactOccurred(_ style: UIImpactFeedbackGenerator.FeedbackStyle)
}

@MainActor
private final class UIKitHapticFeedbackPerformer: HapticFeedbackPerforming {
    func selectionChanged() {
        UISelectionFeedbackGenerator().selectionChanged()
    }

    func notificationOccurred(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        UINotificationFeedbackGenerator().notificationOccurred(type)
    }

    func impactOccurred(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }
}

@MainActor
final class HapticService {
    static let shared = HapticService()

    private var feedbackPerformer: HapticFeedbackPerforming

    private init() {
        self.feedbackPerformer = UIKitHapticFeedbackPerformer()
    }

    func selection() {
        guard UserPreferences.hapticFeedbackEnabled else { return }
        feedbackPerformer.selectionChanged()
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
        feedbackPerformer.impactOccurred(style)
    }

    func answerSubmitted(correct: Bool) {
        correct ? success() : warning()
    }

    func audioPlaybackRequested() {
        impact(.light)
    }

    func traceStrokeStarted() {
        selection()
    }

    func traceStrokeCompleted() {
        impact(.light)
    }

    func sessionCompleted() {
        success()
    }

    func setFeedbackPerformerForTesting(_ performer: HapticFeedbackPerforming) {
        feedbackPerformer = performer
    }

    func resetFeedbackPerformerForTesting() {
        feedbackPerformer = UIKitHapticFeedbackPerformer()
    }

    private func notify(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        guard UserPreferences.hapticFeedbackEnabled else { return }
        feedbackPerformer.notificationOccurred(type)
    }
}
