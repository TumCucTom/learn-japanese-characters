# Production Readiness Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Harden the iOS-only Maru kana learning app so core learning data, audio, haptics, animation feedback, reset behavior, and widgets are ready for production use.

**Architecture:** Keep the existing SwiftUI + shared model architecture. Add focused services for user preferences and tactile feedback, keep audio in `AudioService`, add missing persistence APIs in `SharedDatabase`, and make WidgetKit timeline selection deterministic/testable through small pure helpers.

**Tech Stack:** SwiftUI, AVFoundation speech synthesis, UIKit haptics, WidgetKit/AppIntents, SQLite.swift, XCTest, XcodeGen.

---

### Task 1: Add Preference-Gated Feedback Services

**Files:**
- Create: `Maru/Services/UserPreferences.swift`
- Create: `Maru/Services/HapticService.swift`
- Modify: `Maru/Services/AudioService.swift`
- Test: `MaruTests/AudioServiceTests.swift`

- [ ] **Step 1: Write failing audio preference test**

Add a test that disables sound and proves `AudioService.playKana(_:)` does not mark playback as active:

```swift
func testPlayKanaDoesNotStartWhenSoundIsDisabled() {
    UserDefaults.standard.set(false, forKey: UserPreferences.soundEffectsKey)

    let kana = SharedKana(
        id: "h_basic_1",
        character: "あ",
        romaji: "a",
        kanaType: .hiragana,
        category: "basic"
    )

    AudioService.shared.playKana(kana)

    XCTAssertFalse(AudioService.shared.isPlaying)
}
```

- [ ] **Step 2: Run test to verify it fails**

Run:

```bash
xcodegen generate
xcodebuild -project Maru.xcodeproj -scheme Maru -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 17 Pro' test -only-testing:MaruTests/AudioServiceTests
```

Expected: the new test fails because `AudioService` currently ignores the sound setting.

- [ ] **Step 3: Implement preferences and feedback services**

Add `UserPreferences` constants/wrappers:

```swift
enum UserPreferences {
    static let hapticFeedbackKey = "hapticFeedback"
    static let soundEffectsKey = "soundEffects"
    static let dailyReminderKey = "dailyReminder"
    static let reminderTimeKey = "reminderTime"

    static var hapticFeedbackEnabled: Bool {
        UserDefaults.standard.object(forKey: hapticFeedbackKey) as? Bool ?? true
    }

    static var soundEffectsEnabled: Bool {
        UserDefaults.standard.object(forKey: soundEffectsKey) as? Bool ?? true
    }
}
```

Add `HapticService` with `selection()`, `success()`, `warning()`, `error()`, and `impact(_:)` methods that no-op when haptics are disabled.

In `AudioService.speak(_:)`, return early with `isPlaying = false` when `UserPreferences.soundEffectsEnabled` is false.

- [ ] **Step 4: Run test to verify it passes**

Run the same AudioService test command. Expected: all `AudioServiceTests` pass.

### Task 2: Wire Haptics, Sound Preferences, and Answer Animation

**Files:**
- Modify: `Maru/ViewModels/PracticeViewModel.swift`
- Modify: `Maru/ViewModels/HomeViewModel.swift`
- Modify: `Maru/ViewModels/WordsViewModel.swift`
- Modify: `Maru/ViewModels/KanaChartViewModel.swift`
- Modify: `Maru/Views/PracticeView.swift`
- Modify: `Maru/Views/HomeView.swift`
- Modify: `Maru/Views/WordsView.swift`
- Modify: `Maru/Views/KanaChartView.swift`
- Test: `MaruTests/PracticeViewModelTests.swift`

- [ ] **Step 1: Write failing practice feedback test**

Add a test showing a correct answer records celebration state and score without allowing double-submit:

```swift
func testCorrectAnswerUpdatesFeedbackOnce() {
    let kana = [
        SharedKana(id: "h_basic_1", character: "あ", romaji: "a", kanaType: .hiragana, category: "basic")
    ]
    let viewModel = PracticeViewModel()

    viewModel.startPracticeSession(kana: kana, exerciseType: .spelling)
    viewModel.typedAnswer = "a"
    viewModel.submitTypedAnswer()
    viewModel.submitTypedAnswer()

    XCTAssertEqual(viewModel.score, 1)
    XCTAssertEqual(viewModel.totalQuestions, 1)
    XCTAssertEqual(viewModel.mascotExpression, .celebrating)
    XCTAssertTrue(viewModel.answerFeedbackID > 0)
}
```

- [ ] **Step 2: Run test to verify it fails**

Run:

```bash
xcodebuild -project Maru.xcodeproj -scheme Maru -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 17 Pro' test -only-testing:MaruTests/PracticeViewModelTests
```

Expected: compile/test failure because `answerFeedbackID` does not exist.

- [ ] **Step 3: Implement interaction feedback**

Add `@Published var answerFeedbackID = 0` and call haptics from view models:
- `selection()` for tab-like/category choices, refreshes, and starting sessions.
- `success()` for correct answers and completing writing.
- `error()` for wrong answers.
- `impact(.light)` for speaker/play/trace actions.

Wrap visible answer and mascot transitions in `withAnimation(.spring(response:dampingFraction:))`, and increment `answerFeedbackID` when an answer is accepted so SwiftUI can animate the feedback surfaces.

- [ ] **Step 4: Run test to verify it passes**

Run the PracticeViewModel test command. Expected: all practice tests pass.

### Task 3: Make Reset Progress Actually Clear Learning Data

**Files:**
- Modify: `Shared/SharedDatabase.swift`
- Modify: `Maru/Views/SettingsView.swift`
- Test: `MaruTests/SharedDatabaseTests.swift`

- [ ] **Step 1: Write failing database reset test**

Add:

```swift
func testDeleteAllProgressRemovesSavedProgress() throws {
    let progress = SharedProgress(
        id: "h_basic_1",
        mistakeCount: 1,
        correctCount: 4,
        lastPracticed: Date(),
        masteryLevel: .learning
    )

    try SharedDatabase.shared.insertOrUpdateProgress(progress)
    XCTAssertNotNil(try SharedDatabase.shared.getProgress(forKanaId: progress.id))

    try SharedDatabase.shared.deleteAllProgress()

    XCTAssertNil(try SharedDatabase.shared.getProgress(forKanaId: progress.id))
}
```

- [ ] **Step 2: Run test to verify it fails**

Run:

```bash
xcodegen generate
xcodebuild -project Maru.xcodeproj -scheme Maru -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 17 Pro' test -only-testing:MaruTests/SharedDatabaseTests
```

Expected: compile failure because `deleteAllProgress()` does not exist.

- [ ] **Step 3: Implement reset**

Add `func deleteAllProgress() throws` to `SharedDatabase` using `progressTable.delete()`. In `SettingsView.resetProgress()`, use `UserPreferences` keys and call `try? SharedDatabase.shared.deleteAllProgress()`.

- [ ] **Step 4: Run test to verify it passes**

Run the SharedDatabase test command. Expected: all reset tests pass.

### Task 4: Make Widgets Teach Throughout the Day and Honor Configuration

**Files:**
- Modify: `MaruWidget/WidgetProvider.swift`
- Modify: `MaruWidget/DailyKanaWidget.swift`
- Modify: `MaruWidget/FlashcardWidget.swift`
- Modify: `MaruWidget/LockScreenWidget.swift`
- Test: `MaruTests/WidgetScheduleTests.swift`

- [ ] **Step 1: Write failing widget helper tests**

Add tests for pure helper functions:

```swift
func testWidgetFiltersKanaByConfiguredType() {
    let kana = [
        SharedKana(id: "h_basic_1", character: "あ", romaji: "a", kanaType: .hiragana, category: "basic"),
        SharedKana(id: "k_basic_1", character: "ア", romaji: "a", kanaType: .katakana, category: "basic")
    ]

    let filtered = WidgetDailyKanaService.filter(kana, for: .katakana)

    XCTAssertEqual(filtered.map(\.id), ["k_basic_1"])
}

func testWidgetRefreshesEveryFourHours() {
    let base = Date(timeIntervalSince1970: 1_800_000_000)

    let next = WidgetTimelineSchedule.nextRefresh(after: base)

    XCTAssertEqual(next.timeIntervalSince(base), 14_400, accuracy: 1)
}
```

- [ ] **Step 2: Run test to verify it fails**

Run:

```bash
xcodegen generate
xcodebuild -project Maru.xcodeproj -scheme Maru -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 17 Pro' test -only-testing:MaruTests/WidgetScheduleTests
```

Expected: compile failure because helper functions do not exist or are not exposed to the app test target.

- [ ] **Step 3: Implement widget selection and timelines**

Add `WidgetTimelineSchedule.nextRefresh(after:)` returning `date + 4 hours`.
Change provider methods to pass `configuration.kanaType` into selection.
Add `WidgetDailyKanaService.filter(_:for:)` and `getDailyCharacter(kanaType:)` / `getFlashcardKana(kanaType:)`.
Use `.after(WidgetTimelineSchedule.nextRefresh(after: Date()))` for daily, flashcard, and lock screen timelines.
Update widget copy from “Daily” to “Today”/“Now” so four-hour rotation is truthful.

- [ ] **Step 4: Run widget tests**

Run the WidgetSchedule test command. Expected: all widget tests pass.

### Task 5: Production Verification, Simulator Run, Commit, Push

**Files:**
- Generated: `Maru.xcodeproj/project.pbxproj`

- [ ] **Step 1: Generate project**

Run:

```bash
xcodegen generate
```

Expected: project generated without errors.

- [ ] **Step 2: Run full unit tests**

Run:

```bash
xcodebuild -project Maru.xcodeproj -scheme Maru -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 17 Pro' test -only-testing:MaruTests -quiet
```

Expected: exit code 0.

- [ ] **Step 3: Build app**

Run:

```bash
xcodebuild -project Maru.xcodeproj -scheme Maru -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build -quiet
```

Expected: exit code 0.

- [ ] **Step 4: Install and launch simulator build**

Run:

```bash
xcrun simctl install booted /Users/tom/Library/Developer/Xcode/DerivedData/Maru-dwvnerdwjqrgjzghafmkvbdkynnd/Build/Products/Debug-iphonesimulator/Maru.app
xcrun simctl launch booted com.maru.app
```

Expected: app launches on the booted simulator.

- [ ] **Step 5: Commit and push**

Run:

```bash
git add Maru MaruWidget Shared MaruTests Maru.xcodeproj docs/superpowers/plans/2026-06-13-production-readiness.md
git commit --author="Thomas Bale <hf23482@bristol.ac.uk>" -m "feat: harden production learning experience" -m "Wire sound and haptic preferences, improve answer feedback, fix progress reset, and rotate configured widgets throughout the day." -m "Co-Authored-By: Zippy AI <tomkinsbale@icloud.com>"
git push -u origin codex/production-readiness
```

Expected: branch pushed successfully.
