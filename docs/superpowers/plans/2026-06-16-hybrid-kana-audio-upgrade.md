# Hybrid Kana Audio Upgrade Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the current mixed native kana audio set with a verified primary Just Gojuon MP3 dataset while keeping explicit speech fallback only for kana without a clean permissive native recording.

**Architecture:** `KanaAudioAssetResolver` remains the single mapping boundary from app kana data to bundled audio assets. Audio files stay offline in `Maru/Resources/Audio`, with `AudioSourceManifest.json` and `AudioLicenses.txt` documenting provenance. Tests enforce resolver coverage, asset presence, and source attribution so missing sounds cannot silently return.

**Tech Stack:** Swift, XCTest, AVFoundation, bundled MP3 resources, XcodeGen/Xcode project resources.

---

### Task 1: Coverage Tests

**Files:**
- Modify: `MaruTests/KanaAudioAssetResolverTests.swift`
- Modify: `Maru/Services/KanaAudioAssetResolver.swift`

- [x] **Step 1: Add failing tests for explicit fallback and manifest provenance**

Add tests that require a public `speechFallbackRomaji` set, verify only `d` and `vu` use fallback, and verify every native audio asset has Just Gojuon provenance in `AudioSourceManifest.json`.

- [x] **Step 2: Run resolver tests and verify they fail**

Run: `xcodebuild test -project Maru.xcodeproj -scheme Maru -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.5' -only-testing:MaruTests/KanaAudioAssetResolverTests`

Expected: fail because `speechFallbackRomaji` is not public yet and the manifest still contains Wikimedia entries.

### Task 2: Resolver and Dataset

**Files:**
- Modify: `Maru/Services/KanaAudioAssetResolver.swift`
- Modify: `Maru/Resources/Audio/*.mp3`
- Modify: `Maru/Resources/Audio/AudioSourceManifest.json`
- Modify: `Maru/Resources/AudioLicenses.txt`

- [x] **Step 1: Expose explicit fallback romaji**

Add `static let speechFallbackRomaji: Set<String> = ["d", "vu"]` and use it in `assetName(for:)`.

- [x] **Step 2: Replace supported audio assets**

Download Just Gojuon MP3s from `https://raw.githubusercontent.com/veardk/just-gojuon/main/public/sounds/{category}/{romaji}.mp3` for the 102 supported asset names already referenced by the project.

- [x] **Step 3: Regenerate manifest**

Record each asset filename, source label, source URL, byte count, and SHA-256 hash in `AudioSourceManifest.json`.

- [x] **Step 4: Update notices**

Update `AudioLicenses.txt` to describe Just Gojuon as the primary bundled kana audio source and keep `d`/`vu` as explicit speech fallback.

### Task 3: Verification and Delivery

**Files:**
- Test: `MaruTests/KanaAudioAssetResolverTests.swift`
- Test: full app scheme

- [x] **Step 1: Run focused tests**

Run: `xcodebuild test -project Maru.xcodeproj -scheme Maru -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.5' -only-testing:MaruTests/KanaAudioAssetResolverTests`

Expected: resolver tests pass.

- [x] **Step 2: Run full tests**

Run: `xcodebuild test -project Maru.xcodeproj -scheme Maru -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.5'`

Expected: full suite passes.

- [x] **Step 3: Run simulator smoke check**

Install and launch `Maru.app` on the iPhone 17 Pro simulator, capture a screenshot, and confirm the app stays responsive. Audio path verification is covered by `AudioServiceTests`, MP3 decoding with `afinfo`, and manifest hash checks.

- [ ] **Step 4: Commit and push**

Commit with author `Thomas Bale <hf23482@bristol.ac.uk>` and co-author `Zippy AI <tomkinsbale@icloud.com>`, then push `codex/production-readiness`.
