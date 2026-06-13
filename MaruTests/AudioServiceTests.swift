import XCTest
@testable import Maru

@MainActor
final class AudioServiceTests: XCTestCase {
    override func tearDown() {
        AudioService.shared.stop()
        UserDefaults.standard.removeObject(forKey: UserPreferences.soundEffectsKey)
        super.tearDown()
    }

    func testPlayKanaMarksAudioServiceAsPlayingImmediately() {
        let kana = SharedKana(
            id: "h_basic_1",
            character: "あ",
            romaji: "a",
            kanaType: .hiragana,
            category: "basic"
        )

        AudioService.shared.playKana(kana)

        XCTAssertTrue(AudioService.shared.isPlaying)
    }

    func testPlayKanaUsesNativeAudioAssetWhenAvailable() {
        let kana = SharedKana(
            id: "h_basic_1",
            character: "あ",
            romaji: "a",
            kanaType: .hiragana,
            category: "basic"
        )

        AudioService.shared.playKana(kana)

        XCTAssertEqual(AudioService.shared.lastPlaybackSource, .nativeKanaAsset)
    }

    func testPlayKanaFallsBackToSpeechWhenNativeAudioIsUnavailable() {
        let kana = SharedKana(
            id: "h_dakuten_iteration_1",
            character: "ゞ",
            romaji: "d",
            kanaType: .hiragana,
            category: "dakuten"
        )

        AudioService.shared.playKana(kana)

        XCTAssertEqual(AudioService.shared.lastPlaybackSource, .speechFallback)
    }

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
        XCTAssertEqual(AudioService.shared.lastPlaybackSource, .none)
    }

    func testApplyCurrentPreferencesStopsActivePlaybackWhenSoundIsDisabled() {
        let kana = SharedKana(
            id: "h_basic_1",
            character: "あ",
            romaji: "a",
            kanaType: .hiragana,
            category: "basic"
        )

        AudioService.shared.playKana(kana)
        XCTAssertTrue(AudioService.shared.isPlaying)

        UserDefaults.standard.set(false, forKey: UserPreferences.soundEffectsKey)
        AudioService.shared.applyCurrentPreferences()

        XCTAssertFalse(AudioService.shared.isPlaying)
    }
}
