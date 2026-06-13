import XCTest
@testable import Maru

final class KanaAudioAssetResolverTests: XCTestCase {
    func testResolvesDirectKanaRomajiToNativeAudioAssetName() {
        XCTAssertEqual(
            KanaAudioAssetResolver.assetName(for: kana(romaji: "a")),
            "kana_native_a"
        )
        XCTAssertEqual(
            KanaAudioAssetResolver.assetName(for: kana(romaji: "ka")),
            "kana_native_ka"
        )
    }

    func testMapsHepburnCombinationRomajiToBundledAudioAssetNames() {
        XCTAssertEqual(
            KanaAudioAssetResolver.assetName(for: kana(romaji: "sha")),
            "kana_native_sya"
        )
        XCTAssertEqual(
            KanaAudioAssetResolver.assetName(for: kana(romaji: "chu")),
            "kana_native_cyu"
        )
        XCTAssertEqual(
            KanaAudioAssetResolver.assetName(for: kana(romaji: "jo")),
            "kana_native_zyo"
        )
    }

    func testReturnsNilForKanaThatShouldUseSpeechFallback() {
        XCTAssertNil(KanaAudioAssetResolver.assetName(for: kana(romaji: "d")))
        XCTAssertNil(KanaAudioAssetResolver.assetName(for: kana(romaji: "vu")))
    }

    func testBundleContainsEveryResolvedNativeKanaAudioAsset() throws {
        let url = try XCTUnwrap(Bundle.main.url(forResource: "kana_data", withExtension: "json"))
        let data = try Data(contentsOf: url)
        let allKana = try JSONDecoder().decode([SharedKana].self, from: data)

        let assetNames = Set(allKana.compactMap(KanaAudioAssetResolver.assetName(for:))).sorted()

        XCTAssertEqual(assetNames.count, 102)

        for assetName in assetNames {
            XCTAssertNotNil(
                Bundle.main.url(forResource: assetName, withExtension: "mp3"),
                "Missing bundled native audio asset: \(assetName).mp3"
            )
        }
    }

    func testBundleContainsNativeAudioAttributionNotice() {
        XCTAssertNotNil(Bundle.main.url(forResource: "AudioLicenses", withExtension: "txt"))
    }

    private func kana(romaji: String, audioFileName: String? = nil) -> SharedKana {
        SharedKana(
            id: "h_test_\(romaji)",
            character: "あ",
            romaji: romaji,
            kanaType: .hiragana,
            category: "basic",
            audioFileName: audioFileName
        )
    }
}
