import XCTest
@testable import Maru

final class WidgetScheduleTests: XCTestCase {
    func testWidgetFiltersKanaByConfiguredType() {
        let kana = [
            SharedKana(id: "h_basic_1", character: "あ", romaji: "a", kanaType: .hiragana, category: "basic"),
            SharedKana(id: "k_basic_1", character: "ア", romaji: "a", kanaType: .katakana, category: "basic")
        ]

        let filtered = WidgetKanaSelector.filter(kana, for: .katakana)

        XCTAssertEqual(filtered.map(\.id), ["k_basic_1"])
    }

    func testWidgetRefreshesEveryFourHours() {
        let base = Date(timeIntervalSince1970: 1_800_000_000)

        let next = WidgetTimelineSchedule.nextRefresh(after: base)

        XCTAssertEqual(next.timeIntervalSince(base), 14_400, accuracy: 1)
    }

    func testWidgetSelectionDoesNotFallBackToWrongKanaType() {
        let kana = [
            SharedKana(id: "h_basic_1", character: "あ", romaji: "a", kanaType: .hiragana, category: "basic")
        ]

        let selected = WidgetKanaSelector.select(
            from: kana,
            type: .katakana,
            date: Date(timeIntervalSince1970: 1_800_000_000),
            salt: "test"
        )

        XCTAssertNil(selected)
    }

    func testWidgetSelectionRotatesAcrossRefreshSlots() throws {
        let kana = [
            SharedKana(id: "h_basic_1", character: "あ", romaji: "a", kanaType: .hiragana, category: "basic"),
            SharedKana(id: "h_basic_2", character: "い", romaji: "i", kanaType: .hiragana, category: "basic")
        ]
        let firstDate = Date(timeIntervalSince1970: 1_800_000_000)
        let secondDate = WidgetTimelineSchedule.nextRefresh(after: firstDate)

        let first = try XCTUnwrap(WidgetKanaSelector.select(from: kana, type: .hiragana, date: firstDate, salt: "rotate"))
        let second = try XCTUnwrap(WidgetKanaSelector.select(from: kana, type: .hiragana, date: secondDate, salt: "rotate"))

        XCTAssertNotEqual(first.id, second.id)
    }
}
