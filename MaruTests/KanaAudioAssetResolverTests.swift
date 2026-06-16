import XCTest
@testable import Maru

final class KanaAudioAssetResolverTests: XCTestCase {
    private struct AudioManifest: Decodable {
        let assets: [AudioAsset]
    }

    private struct AudioAsset: Decodable {
        let asset: String
        let source: String
        let url: String
        let bytes: Int
        let sha256: String
    }

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

    func testOnlyExplicitFallbackKanaSkipNativeAudio() throws {
        let url = try XCTUnwrap(Bundle.main.url(forResource: "kana_data", withExtension: "json"))
        let data = try Data(contentsOf: url)
        let allKana = try JSONDecoder().decode([SharedKana].self, from: data)

        let nativeRomaji = Set(allKana.compactMap { kana in
            KanaAudioAssetResolver.assetName(for: kana) == nil ? nil : kana.romaji
        })
        let allRomaji = Set(allKana.map(\.romaji))

        XCTAssertEqual(allRomaji.subtracting(nativeRomaji), KanaAudioAssetResolver.speechFallbackRomaji)
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

    func testManifestRecordsJustGojuonProvenanceForEveryNativeKanaAsset() throws {
        let url = try XCTUnwrap(Bundle.main.url(forResource: "AudioSourceManifest", withExtension: "json"))
        let data = try Data(contentsOf: url)
        let manifest = try JSONDecoder().decode(AudioManifest.self, from: data)
        let assets = manifest.assets.filter { $0.asset.hasPrefix("kana_native_") }

        XCTAssertEqual(assets.count, 102)

        for asset in assets {
            XCTAssertTrue(asset.source.contains("Just Gojuon MIT"), asset.asset)
            XCTAssertTrue(asset.url.hasPrefix("https://raw.githubusercontent.com/veardk/just-gojuon/main/public/sounds/"), asset.asset)
            XCTAssertGreaterThan(asset.bytes, 0, asset.asset)
            XCTAssertEqual(asset.sha256.count, 64, asset.asset)
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
