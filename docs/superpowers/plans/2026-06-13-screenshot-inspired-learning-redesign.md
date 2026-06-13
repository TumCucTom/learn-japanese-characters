# Screenshot-Inspired Learning Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Redesign the iOS app around the referenced MARU screenshots while keeping original branding, mascot details, and the existing widget-first differentiator.

**Architecture:** Keep the existing SwiftUI/MVVM structure. Add a small row-based learning helper that can be unit-tested, then update views/components to use bold outlined learning cards, row unlock states, richer mascot reactions, and MARU-like drill layouts without reusing copied assets.

**Tech Stack:** SwiftUI, WidgetKit, SQLite.swift, XcodeGen, XCTest.

---

## File Structure

- Modify `project.yml` to add a `MaruTests` target.
- Create `MaruTests/KanaLearningPathTests.swift` for red-green coverage of row grouping and unlock status.
- Create `Shared/KanaLearningPath.swift` for row-based kana grouping/unlock logic.
- Modify `Maru/Views/Components/MaruMascot.swift` for original red domed mascot with more visible expressions.
- Modify `Maru/Views/HomeView.swift` for hero mascot, date/time panel, progress bars, and floating word chips.
- Modify `Maru/Views/KanaChartView.swift` for row-by-row chart with locked/unlocked/mastered states and drill/unlock actions.
- Modify `Maru/Views/PracticeView.swift` for screenshot-inspired full-screen drill modes.
- Modify `Maru/ViewModels/PracticeViewModel.swift` to support choose/listening/typing/vocab-like modes in one compact session model.
- Modify widget views to align with the bold card/mascot visual language.

## Tasks

- [ ] Add unit tests for `KanaLearningPath.rows(for:)` and `KanaLearningPath.status(for:progressMap:)`, verify they fail because the helper does not exist.
- [ ] Implement `KanaLearningPath` with deterministic basic-row grouping and conservative unlock rules.
- [ ] Regenerate the Xcode project and verify tests pass.
- [ ] Redesign mascot and shared card styling with original red domed character, thick outlines, blush, and expression states.
- [ ] Redesign Home and Chart around learning progression: hero mascot, floating chips, row progress, row unlock chart.
- [ ] Redesign Practice around the reference mechanics: choose/listening/typing/vocabulary card layouts, immediate mascot feedback, and bold answer states.
- [ ] Refresh widget styling to match the new learning cards.
- [ ] Build, test, install, and launch on the iPhone 17 Pro simulator.
- [ ] Commit the completed redesign with Thomas Bale authorship and Zippy AI co-author.
