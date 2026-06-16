import XCTest
import UIKit
@testable import Maru

@MainActor
final class HapticServiceTests: XCTestCase {
    private final class SpyHapticPerformer: HapticFeedbackPerforming {
        enum Event: Equatable {
            case selection
            case notification(UINotificationFeedbackGenerator.FeedbackType)
            case impact(UIImpactFeedbackGenerator.FeedbackStyle)
        }

        private(set) var events: [Event] = []

        func selectionChanged() {
            events.append(.selection)
        }

        func notificationOccurred(_ type: UINotificationFeedbackGenerator.FeedbackType) {
            events.append(.notification(type))
        }

        func impactOccurred(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
            events.append(.impact(style))
        }
    }

    override func tearDown() {
        HapticService.shared.resetFeedbackPerformerForTesting()
        UserDefaults.standard.removeObject(forKey: UserPreferences.hapticFeedbackKey)
        super.tearDown()
    }

    func testAnswerSubmittedUsesSuccessForCorrectAndWarningForWrong() {
        let spy = SpyHapticPerformer()
        HapticService.shared.setFeedbackPerformerForTesting(spy)

        HapticService.shared.answerSubmitted(correct: true)
        HapticService.shared.answerSubmitted(correct: false)

        XCTAssertEqual(spy.events, [.notification(.success), .notification(.warning)])
    }

    func testLearningMicroInteractionsUseLightImpactOrSelection() {
        let spy = SpyHapticPerformer()
        HapticService.shared.setFeedbackPerformerForTesting(spy)

        HapticService.shared.audioPlaybackRequested()
        HapticService.shared.traceStrokeStarted()
        HapticService.shared.traceStrokeCompleted()
        HapticService.shared.sessionCompleted()

        XCTAssertEqual(spy.events, [
            .impact(.light),
            .selection,
            .impact(.light),
            .notification(.success)
        ])
    }

    func testSemanticHapticsRespectUserPreference() {
        UserDefaults.standard.set(false, forKey: UserPreferences.hapticFeedbackKey)
        let spy = SpyHapticPerformer()
        HapticService.shared.setFeedbackPerformerForTesting(spy)

        HapticService.shared.answerSubmitted(correct: true)
        HapticService.shared.audioPlaybackRequested()
        HapticService.shared.traceStrokeStarted()

        XCTAssertTrue(spy.events.isEmpty)
    }
}
