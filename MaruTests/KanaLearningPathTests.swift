import XCTest
@testable import Maru

final class KanaLearningPathTests: XCTestCase {
    func testRowsForBasicHiraganaGroupsCharactersInGojuonOrder() {
        let kana = [
            SharedKana(id: "h_basic_6", character: "か", romaji: "ka", kanaType: .hiragana, category: "basic"),
            SharedKana(id: "h_basic_7", character: "き", romaji: "ki", kanaType: .hiragana, category: "basic"),
            SharedKana(id: "h_basic_8", character: "く", romaji: "ku", kanaType: .hiragana, category: "basic"),
            SharedKana(id: "h_basic_9", character: "け", romaji: "ke", kanaType: .hiragana, category: "basic"),
            SharedKana(id: "h_basic_10", character: "こ", romaji: "ko", kanaType: .hiragana, category: "basic"),
            SharedKana(id: "h_basic_1", character: "あ", romaji: "a", kanaType: .hiragana, category: "basic"),
            SharedKana(id: "h_basic_2", character: "い", romaji: "i", kanaType: .hiragana, category: "basic"),
            SharedKana(id: "h_basic_3", character: "う", romaji: "u", kanaType: .hiragana, category: "basic"),
            SharedKana(id: "h_basic_4", character: "え", romaji: "e", kanaType: .hiragana, category: "basic"),
            SharedKana(id: "h_basic_5", character: "お", romaji: "o", kanaType: .hiragana, category: "basic")
        ]

        let rows = KanaLearningPath.rows(for: kana, type: .hiragana)

        XCTAssertEqual(rows.map(\.romajiPrefix), ["a", "ka"])
        XCTAssertEqual(rows.first?.kana.map(\.romaji), ["a", "i", "u", "e", "o"])
        XCTAssertEqual(rows.last?.kana.map(\.romaji), ["ka", "ki", "ku", "ke", "ko"])
    }

    func testStatusUnlocksFirstRowAndLocksLaterRowsUntilPreviousRowHasPractice() {
        let rowA = KanaLearningPath.Row(
            id: "hiragana-a",
            romajiPrefix: "a",
            kana: [
                SharedKana(id: "h_basic_1", character: "あ", romaji: "a", kanaType: .hiragana, category: "basic"),
                SharedKana(id: "h_basic_2", character: "い", romaji: "i", kanaType: .hiragana, category: "basic")
            ]
        )
        let rowKa = KanaLearningPath.Row(
            id: "hiragana-ka",
            romajiPrefix: "ka",
            kana: [
                SharedKana(id: "h_basic_6", character: "か", romaji: "ka", kanaType: .hiragana, category: "basic")
            ]
        )

        let locked = KanaLearningPath.status(for: [rowA, rowKa], progressMap: [:])
        XCTAssertEqual(locked[rowA.id], .unlocked)
        XCTAssertEqual(locked[rowKa.id], .locked)

        let progressMap = [
            "h_basic_1": SharedProgress(id: "h_basic_1", mistakeCount: 0, correctCount: 3, lastPracticed: Date(), masteryLevel: .learning),
            "h_basic_2": SharedProgress(id: "h_basic_2", mistakeCount: 0, correctCount: 3, lastPracticed: Date(), masteryLevel: .learning)
        ]

        let unlocked = KanaLearningPath.status(for: [rowA, rowKa], progressMap: progressMap)
        XCTAssertEqual(unlocked[rowA.id], .learning)
        XCTAssertEqual(unlocked[rowKa.id], .unlocked)
    }
}
