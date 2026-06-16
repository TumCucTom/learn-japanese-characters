# Micro Animations and Haptics Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [x]`) syntax for tracking.

**Goal:** Add a consistent, production-grade motion and haptic language to the Maru learning flow.

**Architecture:** Keep haptics centralized in `HapticService`, expose semantic events for learning actions, and make those events testable through an injectable performer. Add one SwiftUI motion helper file for reusable pulse/shake/spring behavior, then wire it into Home and Practice without changing the app's visual identity or learning rules.

**Tech Stack:** Swift, SwiftUI, UIKit haptics, XCTest, iOS Simulator.

---

### Task 1: Semantic Haptic Service

**Files:**
- Modify: `Maru/Services/HapticService.swift`
- Create: `MaruTests/HapticServiceTests.swift`

- [x] **Step 1: Write failing haptic semantic tests**

Create `MaruTests/HapticServiceTests.swift`:

```swift
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
```

- [x] **Step 2: Run haptic tests and verify red**

Run: `xcodebuild test -project Maru.xcodeproj -scheme Maru -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.5' -only-testing:MaruTests/HapticServiceTests`

Expected: fail because `HapticFeedbackPerforming`, testing performer methods, and semantic haptic methods do not exist.

- [x] **Step 3: Implement minimal haptic seam**

Update `Maru/Services/HapticService.swift` with:

```swift
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
```

Change `HapticService` to store a `feedbackPerformer`, call it from existing `selection`, `notify`, and `impact` methods, then add:

```swift
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
```

- [x] **Step 4: Run haptic tests and verify green**

Run: `xcodebuild test -project Maru.xcodeproj -scheme Maru -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.5' -only-testing:MaruTests/HapticServiceTests`

Expected: pass.

### Task 2: Practice Feedback State

**Files:**
- Modify: `Maru/ViewModels/PracticeViewModel.swift`
- Modify: `MaruTests/PracticeViewModelTests.swift`

- [x] **Step 1: Write failing animation-consumer tests**

Append to `PracticeViewModelTests`:

```swift
func testAnswerFeedbackEventCapturesSelectedAndCorrectAnswer() {
    let rowKana = sampleHiraganaRow()
    let viewModel = PracticeViewModel()
    viewModel.startPracticeSession(kana: rowKana, exerciseType: .multipleChoice)
    let current = try! XCTUnwrap(viewModel.currentKana)
    let wrongAnswer = try! XCTUnwrap(viewModel.choices.first { $0.answer != current.romaji }?.answer)

    viewModel.selectAnswer(wrongAnswer)

    XCTAssertEqual(viewModel.answerFeedback?.selectedAnswer, wrongAnswer)
    XCTAssertEqual(viewModel.answerFeedback?.correctAnswer, current.romaji)
    XCTAssertEqual(viewModel.answerFeedback?.isCorrect, false)
    XCTAssertEqual(viewModel.answerFeedback?.id, viewModel.answerFeedbackID)
}

func testAnswerFeedbackClearsWhenNextQuestionLoads() {
    let rowKana = sampleHiraganaRow()
    let viewModel = PracticeViewModel()
    viewModel.startPracticeSession(kana: rowKana, exerciseType: .multipleChoice)
    let current = try! XCTUnwrap(viewModel.currentKana)

    viewModel.selectAnswer(current.romaji)
    XCTAssertNotNil(viewModel.answerFeedback)

    viewModel.nextQuestion()

    XCTAssertNil(viewModel.answerFeedback)
}
```

- [x] **Step 2: Run practice tests and verify red**

Run: `xcodebuild test -project Maru.xcodeproj -scheme Maru -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.5' -only-testing:MaruTests/PracticeViewModelTests`

Expected: fail because `answerFeedback` does not exist.

- [x] **Step 3: Add feedback event state**

In `PracticeViewModel`, add:

```swift
struct AnswerFeedback: Equatable {
    let id: Int
    let selectedAnswer: String
    let correctAnswer: String
    let isCorrect: Bool
}

@Published var answerFeedback: AnswerFeedback?
```

In `loadCurrentQuestion()` and `resetSession()`, set `answerFeedback = nil`.

In `selectAnswer(_:)`, after incrementing `answerFeedbackID`, set:

```swift
let isAnswerCorrect = answer == current.romaji
answerFeedback = AnswerFeedback(
    id: answerFeedbackID,
    selectedAnswer: answer,
    correctAnswer: current.romaji,
    isCorrect: isAnswerCorrect
)
```

Use `hapticService.answerSubmitted(correct: isAnswerCorrect)` instead of direct success/error haptics.

- [x] **Step 4: Run practice tests and verify green**

Run: `xcodebuild test -project Maru.xcodeproj -scheme Maru -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.5' -only-testing:MaruTests/PracticeViewModelTests`

Expected: pass.

### Task 3: Reusable Motion Helpers

**Files:**
- Create: `Maru/Views/Components/LearningMotion.swift`
- Modify: `Maru.xcodeproj/project.pbxproj` if the project does not auto-include the new file

- [x] **Step 1: Add the motion helper**

Create `LearningMotion.swift`:

```swift
import SwiftUI

enum LearningMotion {
    static let quickSpring = Animation.spring(response: 0.22, dampingFraction: 0.74)
    static let feedbackSpring = Animation.spring(response: 0.3, dampingFraction: 0.62)
    static let gentleSpring = Animation.spring(response: 0.38, dampingFraction: 0.78)
    static let quickFade = Animation.easeOut(duration: 0.14)

    static func animation(reduceMotion: Bool, spring: Animation = quickSpring) -> Animation {
        reduceMotion ? quickFade : spring
    }
}

struct PulseOnChangeModifier<Value: Equatable>: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let value: Value
    let scale: CGFloat
    @State private var isPulsing = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(isPulsing && !reduceMotion ? scale : 1)
            .animation(LearningMotion.animation(reduceMotion: reduceMotion, spring: LearningMotion.feedbackSpring), value: isPulsing)
            .onChange(of: value) { _, _ in
                guard !reduceMotion else { return }
                isPulsing = true
                Task { @MainActor in
                    try? await Task.sleep(nanoseconds: 130_000_000)
                    isPulsing = false
                }
            }
    }
}

struct ShakeEffect: GeometryEffect {
    var travel: CGFloat = 7
    var shakes: CGFloat = 3
    var progress: CGFloat

    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(CGAffineTransform(translationX: travel * sin(progress * .pi * shakes), y: 0))
    }
}

struct ShakeOnChangeModifier<Value: Equatable>: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let value: Value
    let isActive: Bool
    @State private var progress: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .modifier(ShakeEffect(progress: reduceMotion ? 0 : progress))
            .onChange(of: value) { _, _ in
                guard isActive, !reduceMotion else { return }
                progress = 0
                withAnimation(.linear(duration: 0.26)) {
                    progress = 1
                }
            }
    }
}

extension View {
    func pulseOnChange<Value: Equatable>(_ value: Value, scale: CGFloat = 1.06) -> some View {
        modifier(PulseOnChangeModifier(value: value, scale: scale))
    }

    func shakeOnChange<Value: Equatable>(_ value: Value, isActive: Bool) -> some View {
        modifier(ShakeOnChangeModifier(value: value, isActive: isActive))
    }
}
```

- [x] **Step 2: Build to verify helper compiles**

Run: `xcodebuild build -project Maru.xcodeproj -scheme Maru -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.5'`

Expected: build succeeds.

### Task 4: Practice Motion Wiring

**Files:**
- Modify: `Maru/Views/PracticeView.swift`
- Modify: `Maru/ViewModels/PracticeViewModel.swift`

- [x] **Step 1: Wire semantic haptics into view-model actions**

In `PracticeViewModel.playCurrentKana()`, replace `hapticService.impact(.light)` with:

```swift
hapticService.audioPlaybackRequested()
```

In `PracticeViewModel.nextQuestion()`, keep `hapticService.selection()`.

In `PracticeViewModel.selectAnswer(_:)`, call:

```swift
hapticService.answerSubmitted(correct: isAnswerCorrect)
```

In the session-complete branch of `loadCurrentQuestion()`, call:

```swift
hapticService.sessionCompleted()
```

- [x] **Step 2: Add reduce-motion-aware state to `PracticeContentView`**

Add:

```swift
@Environment(\.accessibilityReduceMotion) private var reduceMotion
@State private var speakerPulseID = 0
```

Use `LearningMotion.animation(reduceMotion:spring:)` for prompt card, progress fill, feedback, and mascot animations.

- [x] **Step 3: Animate prompt, progress, mascot, and speaker buttons**

Key `promptCard(for:)` by `kana.id`.

Add `.pulseOnChange(viewModel.answerFeedback?.id ?? 0, scale: 1.04)` to the mascot and use existing expression tilt for mistakes.

Wrap speaker button actions as:

```swift
speakerPulseID += 1
viewModel.playCurrentKana()
```

Apply `.pulseOnChange(speakerPulseID, scale: 1.08)` to speaker button labels.

Animate progress capsule width with:

```swift
.animation(LearningMotion.animation(reduceMotion: reduceMotion, spring: LearningMotion.gentleSpring), value: progressFraction)
```

- [x] **Step 4: Animate selected choices**

Pass `answerFeedback: viewModel.answerFeedback` into `ChoiceTile`.

Inside `ChoiceTile`, compute:

```swift
private var isSelectedWrong: Bool {
    answerFeedback?.selectedAnswer == choice.answer && answerFeedback?.isCorrect == false
}

private var shouldPopCorrect: Bool {
    answerFeedback?.correctAnswer == choice.answer && answerFeedback?.isCorrect == true
}
```

Apply:

```swift
.pulseOnChange(answerFeedback?.id ?? 0, scale: shouldPopCorrect ? 1.05 : 1)
.shakeOnChange(answerFeedback?.id ?? 0, isActive: isSelectedWrong)
```

- [x] **Step 5: Add trace haptics**

In `KanaTracePad`, add `@State private var hasStartedCurrentStroke = false`.

In `DragGesture.onChanged`, when `hasStartedCurrentStroke == false`, call:

```swift
HapticService.shared.traceStrokeStarted()
hasStartedCurrentStroke = true
```

In `onEnded`, after saving a non-empty stroke, call:

```swift
HapticService.shared.traceStrokeCompleted()
hasStartedCurrentStroke = false
```

- [x] **Step 6: Build practice wiring**

Run: `xcodebuild build -project Maru.xcodeproj -scheme Maru -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.5'`

Expected: build succeeds.

### Task 5: Home Motion Wiring

**Files:**
- Modify: `Maru/Views/HomeView.swift`

- [x] **Step 1: Add reduced-motion-aware entrance and taps**

Add `@Environment(\.accessibilityReduceMotion) private var reduceMotion` and `@State private var refreshPulseID = 0`.

Pulse the refresh icon by incrementing `refreshPulseID` before `viewModel.refreshWordCloud()`, then apply `.pulseOnChange(refreshPulseID, scale: 1.12)` to the icon.

Apply `.animation(LearningMotion.animation(reduceMotion: reduceMotion, spring: LearningMotion.gentleSpring), value: viewModel.hiraganaProgress)` and equivalent for katakana progress strips.

- [x] **Step 2: Add word tap haptic**

Before `viewModel.playWord(word)`, call:

```swift
HapticService.shared.audioPlaybackRequested()
```

- [x] **Step 3: Build home wiring**

Run: `xcodebuild build -project Maru.xcodeproj -scheme Maru -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.5'`

Expected: build succeeds.

### Task 6: Verification and Commit

**Files:**
- Test: full scheme
- Commit: all changed source, tests, spec, and plan files

- [x] **Step 1: Run focused tests**

Run: `xcodebuild test -project Maru.xcodeproj -scheme Maru -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.5' -only-testing:MaruTests/HapticServiceTests -only-testing:MaruTests/PracticeViewModelTests`

Expected: pass.

- [x] **Step 2: Run full tests**

Run: `xcodebuild test -project Maru.xcodeproj -scheme Maru -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.5'`

Expected: pass.

- [x] **Step 3: Run simulator smoke**

Install and launch the built app:

```bash
xcrun simctl install BC5E3CEF-D406-4DDC-A5E2-B6F92C208545 /Users/tom/Library/Developer/Xcode/DerivedData/Maru-dwvnerdwjqrgjzghafmkvbdkynnd/Build/Products/Debug-iphonesimulator/Maru.app
xcrun simctl launch BC5E3CEF-D406-4DDC-A5E2-B6F92C208545 com.maru.app
xcrun simctl io BC5E3CEF-D406-4DDC-A5E2-B6F92C208545 screenshot /tmp/maru-motion-haptics.png
```

Expected: app launches and screenshot shows the home screen.

- [x] **Step 4: Commit and push**

Run:

```bash
git add Maru/Services/HapticService.swift Maru/ViewModels/PracticeViewModel.swift Maru/Views/Components/LearningMotion.swift Maru/Views/PracticeView.swift Maru/Views/HomeView.swift MaruTests/HapticServiceTests.swift MaruTests/PracticeViewModelTests.swift docs/superpowers/plans/2026-06-16-micro-animations-haptics.md
git commit --author="Thomas Bale <hf23482@bristol.ac.uk>" -m "feat: add learning motion and haptics" -m "Co-authored-by: Zippy AI <tomkinsbale@icloud.com>"
git push origin codex/production-readiness
```

Expected: commit and push succeed.
