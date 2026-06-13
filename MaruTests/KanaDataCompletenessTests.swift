import XCTest
@testable import Maru

final class KanaDataCompletenessTests: XCTestCase {
    func testBundledKanaDataContainsCompleteHiraganaAndKatakanaSets() throws {
        let url = try XCTUnwrap(Bundle.main.url(forResource: "kana_data", withExtension: "json"))
        let data = try Data(contentsOf: url)
        let kana = try JSONDecoder().decode([SharedKana].self, from: data)

        let hiragana = kana.filter { $0.kanaType == .hiragana }
        let katakana = kana.filter { $0.kanaType == .katakana }

        XCTAssertEqual(hiragana.count, 104)
        XCTAssertEqual(katakana.count, 104)
        XCTAssertEqual(Set(kana.map(\.id)).count, kana.count)
        XCTAssertFalse(kana.contains { $0.character.isEmpty || $0.romaji.isEmpty || $0.category.isEmpty })
    }
}
