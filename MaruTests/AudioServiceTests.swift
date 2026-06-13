import XCTest
@testable import Maru

@MainActor
final class AudioServiceTests: XCTestCase {
    override func tearDown() {
        AudioService.shared.stop()
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
}
