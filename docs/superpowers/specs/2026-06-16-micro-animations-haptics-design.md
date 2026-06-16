# Micro Animations and Haptics Design

## Goal

Make Maru feel responsive and production-ready by adding a consistent motion and haptic language across learning actions. Motion should support comprehension and feedback, not decorate every surface.

## Direction

Use a hybrid "paper toy" feel: short, springy moments on learning feedback and taps, with restraint everywhere else. The app keeps its chunky outlined visual style while behaving more like a polished native iOS app.

## Interaction Grammar

- Selection taps use a light haptic tick through `HapticService.selection()`.
- Correct answers use a success haptic and a compact tile pop.
- Wrong answers use a warning haptic and a short shake on the selected tile.
- Session completion uses a success haptic and a small mascot celebration.
- Audio play buttons pulse once after tap so playback feels acknowledged.
- Trace gestures use light haptics at stroke start and stroke completion, with no continuous vibration.

## Motion Rules

- Prompt changes use a small scale/fade transition keyed by the active kana.
- Progress fills animate with a quick spring when the index changes.
- Answer feedback appears with a compact scale/fade transition.
- Continue and Finish buttons slide in after answer feedback.
- Maru idles with a very small bob on stable screens, bounces on success, and tilts on mistakes.
- Reduce Motion disables bobbing, shaking, and large spring movement; it may keep opacity transitions.

## Components

- `HapticService` remains the single haptic boundary and gains semantic helpers for answer correctness, audio taps, trace strokes, and session completion.
- A reusable motion helper or view modifier should provide press/pulse/shake behavior without scattering magic numbers.
- Practice answer state should expose enough information for views to animate the selected choice and mascot without duplicating correctness logic.
- Existing `LearningOutlinedButtonStyle` remains the base button style.

## Testing

- Unit tests should verify semantic haptic routing through injectable feedback where practical.
- View-model tests should verify correct/wrong answer state remains stable for animation consumers.
- Full XCTest should continue to pass.
- Simulator smoke should confirm the practice flow opens and the app remains responsive after answer selection.

## Non-Goals

- No backend or analytics.
- No continuous animations that distract during questions.
- No new visual redesign outside motion and touch feedback.
