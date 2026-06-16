# Learning UI Reimplementation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Repair the learning experience so quiz modes do not leak answers, practice sessions are focused and bounded, the mascot reacts meaningfully, and the SwiftUI interface feels production-ready on iPhone.

**Architecture:** Keep the app backend-free and preserve the existing SwiftUI structure. Put learning correctness in `PracticeViewModel`, keep practice-flow navigation in `PracticeView`, and polish global visual weight through `LearningTheme` plus focused screen edits.

**Tech Stack:** Swift 5, SwiftUI, XCTest, WidgetKit targets already in `Maru.xcodeproj`.

---

## File Structure

- Modify: `Maru/ViewModels/PracticeViewModel.swift`
  - Owns session sizing, focused distractor pools, answer checking, choice subtitles, and mascot feedback state.
- Modify: `MaruTests/PracticeViewModelTests.swift`
  - Adds regression tests for answer leakage, bounded sessions, scoped row practice, and mixed-mode behavior.
- Modify: `Maru/Views/PracticeView.swift`
  - Fixes drill close behavior, progress display, trace-mode copy, prompt sizing, and visible mascot feedback.
- Modify: `Maru/Views/Components/LearningTheme.swift`
  - Reduces global visual weight: lighter outlines, smaller radius, softer press shadow.
- Modify: `Maru/Views/HomeView.swift`
  - Rebuilds the first screen around compact daily progress, immediate drill action, and no tab overlap.
- Modify: `Maru/Views/WordsView.swift`
  - Aligns word cards with the lighter theme and avoids oversized hero treatment.
- Modify: `Maru/Views/KanaChartView.swift`
  - Aligns chart row/card spacing and drill affordances with the repaired theme.
- Modify: `Maru/Views/Components/KanaCard.swift`
  - Tightens kana tile sizing and typography to reduce clipping/visual heaviness.

## Task 1: Test-First Learning Logic Repair

**Files:**
- Modify: `MaruTests/PracticeViewModelTests.swift`
- Modify: `Maru/ViewModels/PracticeViewModel.swift`

- [ ] **Step 1: Add failing tests for quiz choices and session scope**

Add these tests to `PracticeViewModelTests`:

```swift
func testMultipleChoiceDoesNotRevealPromptCharacterInChoiceSubtitle() {
    let kana = [
        SharedKana(id: "h_basic_1", character: "あ", romaji: "a", kanaType: .hiragana, category: "basic"),
        SharedKana(id: "h_basic_2", character: "い", romaji: "i", kanaType: .hiragana, category: "basic"),
        SharedKana(id: "h_basic_3", character: "う", romaji: "u", kanaType: .hiragana, category: "basic"),
        SharedKana(id: "h_basic_4", character: "え", romaji: "e", kanaType: .hiragana, category: "basic")
    ]
    let viewModel = PracticeViewModel()

    viewModel.startPracticeSession(kana: kana, exerciseType: .multipleChoice)

    XCTAssertFalse(viewModel.choices.contains { $0.sublabel == viewModel.currentKana?.character })
}

func testReadingDoesNotRevealRomajiInChoiceSubtitle() {
    let kana = [
        SharedKana(id: "h_basic_1", character: "あ", romaji: "a", kanaType: .hiragana, category: "basic"),
        SharedKana(id: "h_basic_2", character: "い", romaji: "i", kanaType: .hiragana, category: "basic"),
        SharedKana(id: "h_basic_3", character: "う", romaji: "u", kanaType: .hiragana, category: "basic"),
        SharedKana(id: "h_basic_4", character: "え", romaji: "e", kanaType: .hiragana, category: "basic")
    ]
    let viewModel = PracticeViewModel()

    viewModel.startPracticeSession(kana: kana, exerciseType: .reading)

    XCTAssertFalse(viewModel.choices.contains { $0.sublabel == viewModel.currentKana?.romaji })
}

func testRowSpecificPracticeUsesOnlyProvidedKanaAsChoices() {
    let rowKana = [
        SharedKana(id: "h_basic_1", character: "あ", romaji: "a", kanaType: .hiragana, category: "basic"),
        SharedKana(id: "h_basic_2", character: "い", romaji: "i", kanaType: .hiragana, category: "basic"),
        SharedKana(id: "h_basic_3", character: "う", romaji: "u", kanaType: .hiragana, category: "basic"),
        SharedKana(id: "h_basic_4", character: "え", romaji: "e", kanaType: .hiragana, category: "basic")
    ]
    let viewModel = PracticeViewModel()

    viewModel.startPracticeSession(kana: rowKana, exerciseType: .reading)

    XCTAssertEqual(viewModel.choices.count, 4)
    XCTAssertTrue(Set(viewModel.choices.map(\.id)).isSubset(of: Set(rowKana.map(\.id))))
}

func testMixedModeExcludesTracePractice() {
    let kana = [
        SharedKana(id: "h_basic_1", character: "あ", romaji: "a", kanaType: .hiragana, category: "basic"),
        SharedKana(id: "h_basic_2", character: "い", romaji: "i", kanaType: .hiragana, category: "basic"),
        SharedKana(id: "h_basic_3", character: "う", romaji: "u", kanaType: .hiragana, category: "basic"),
        SharedKana(id: "h_basic_4", character: "え", romaji: "e", kanaType: .hiragana, category: "basic"),
        SharedKana(id: "h_basic_5", character: "お", romaji: "o", kanaType: .hiragana, category: "basic")
    ]
    let viewModel = PracticeViewModel()

    viewModel.startPracticeSession(kana: kana)

    for _ in kana.indices {
        XCTAssertNotEqual(viewModel.exerciseType, .writing)
        viewModel.nextQuestion()
    }
}
```

- [ ] **Step 2: Run tests and verify failure**

Run:

```bash
xcodebuild test -project Maru.xcodeproj -scheme Maru -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.5' -only-testing:MaruTests/PracticeViewModelTests
```

Expected: fails on at least the answer-leak and row-choice tests because existing choice subtitles reveal answers and distractors use the full repository.

- [ ] **Step 3: Implement the minimal learning fix**

In `PracticeViewModel`, add:

```swift
private let standardSessionLength = 15
private let focusedSessionLength = 12
private let mixedExerciseTypes: [ExerciseType] = [.multipleChoice, .listening, .reading, .spelling]
private var activeChoicePool: [SharedKana] = []
```

Then update session start methods to cap normal type sessions, preserve provided row pools, and use `mixedExerciseTypes` when no fixed exercise is selected. Update `generateOptions()` so:

- distractors come from `activeChoicePool` first
- choices are limited to four
- multiple choice shows romaji only
- reading/listening show kana only
- subtitles are nil before answer reveal

- [ ] **Step 4: Run focused tests and verify pass**

Run:

```bash
xcodebuild test -project Maru.xcodeproj -scheme Maru -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.5' -only-testing:MaruTests/PracticeViewModelTests
```

Expected: all `PracticeViewModelTests` pass.

## Task 2: Practice Flow and Mascot Repair

**Files:**
- Modify: `Maru/Views/PracticeView.swift`

- [ ] **Step 1: Make drill close return to setup**

Update `PracticeContentView` to accept `onClose: () -> Void`, pass it from `PracticeView`, and make the xmark set `hasStarted = false` for normal tab practice. Keep row-drill navigation stable by dismissing the navigation destination when launched from `KanaChartView` if needed.

- [ ] **Step 2: Make progress represent current question**

Change:

```swift
return Double(viewModel.currentIndex) / Double(viewModel.practiceSession.count)
```

to:

```swift
return Double(viewModel.currentIndex + 1) / Double(viewModel.practiceSession.count)
```

- [ ] **Step 3: Rename writing mode copy to trace practice**

Change start-mode and prompt labels so the honor-system mode is visibly "Trace" rather than presented as a graded writing quiz.

- [ ] **Step 4: Tighten prompt and action layout**

Reduce mascot and prompt-card heights enough that question, choices, and the continue action can coexist on common iPhone simulator sizes without crowding.

## Task 3: Global Visual Weight Repair

**Files:**
- Modify: `Maru/Views/Components/LearningTheme.swift`
- Modify: `Maru/Views/Components/KanaCard.swift`
- Modify: `Maru/Views/WordsView.swift`
- Modify: `Maru/Views/KanaChartView.swift`

- [ ] **Step 1: Reduce outlines and radii**

Update `LearningTheme.heavyLine` from `3` to about `2`, keep `cardRadius` near `10`, and reduce button shadow offset so controls still feel tactile without overpowering text.

- [ ] **Step 2: Tighten repeated tiles**

Reduce oversized card radii in word cards, chart rows, detail stats, and kana tiles to use `LearningTheme.cardRadius` unless a larger display card genuinely needs a larger radius.

- [ ] **Step 3: Keep text inside controls**

Use `.lineLimit(1)`, `.minimumScaleFactor`, and smaller fixed tile sizes where labels currently risk clipping.

## Task 4: Home Screen Reimplementation

**Files:**
- Modify: `Maru/Views/HomeView.swift`

- [ ] **Step 1: Replace oversized hero with compact daily panel**

Make the first viewport show title, mascot, date/time, progress, and primary Start Drill action without requiring a scroll.

- [ ] **Step 2: Move refresh into a quieter toolbar control**

Keep the refresh button accessible but remove the large floating circular treatment.

- [ ] **Step 3: Remove tab overlap**

Use enough bottom padding or a `safeAreaInset` strategy so bottom content never sits under the tab bar.

- [ ] **Step 4: Reduce decorative noise**

Lower pattern opacity and remove or shrink floating labels that compete with learning content.

## Task 5: Verification and Shipping

**Files:**
- No production files unless verification finds a concrete defect.

- [ ] **Step 1: Run all tests**

Run:

```bash
xcodebuild test -project Maru.xcodeproj -scheme Maru -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.5'
```

Expected: `MaruTests` pass.

- [ ] **Step 2: Run on simulator**

Run:

```bash
xcodebuild build -project Maru.xcodeproj -scheme Maru -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.5'
xcrun simctl install booted build/Debug-iphonesimulator/Maru.app
xcrun simctl launch booted com.maru.app
```

Use the actual derived-data app path from the build log if `build/Debug-iphonesimulator/Maru.app` is not the active path.

- [ ] **Step 3: Capture screenshots**

Capture Home and Practice screenshots with:

```bash
xcrun simctl io booted screenshot /tmp/maru-production-pass-home.png
```

Navigate manually or via UI test to Practice, then capture:

```bash
xcrun simctl io booted screenshot /tmp/maru-production-pass-practice.png
```

- [ ] **Step 4: Commit and push**

Commit with:

```bash
git add docs/superpowers/plans/2026-06-16-learning-ui-reimplementation.md Maru MaruTests
git commit --author="Thomas Bale <hf23482@bristol.ac.uk>" -m "fix: repair learning flow and app UI"
```

Commit body must include:

```text
Co-authored-by: Zippy AI <tomkinsbale@icloud.com>
```

Push:

```bash
git push origin codex/production-readiness
```

## Self-Review

- Spec coverage: learning correctness, mascot feedback, UI polish, simulator verification, commit, and push are covered.
- Placeholder scan: no TBD/TODO/fill-in-later instructions are present.
- Type consistency: all referenced Swift types already exist in the current app.
