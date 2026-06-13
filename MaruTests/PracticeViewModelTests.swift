import XCTest
@testable import Maru

@MainActor
final class PracticeViewModelTests: XCTestCase {
    func testStartsRowSpecificPracticeWithProvidedKanaAndMode() {
        let rowKana = [
            SharedKana(id: "h_basic_1", character: "あ", romaji: "a", kanaType: .hiragana, category: "basic"),
            SharedKana(id: "h_basic_2", character: "い", romaji: "i", kanaType: .hiragana, category: "basic")
        ]
        let viewModel = PracticeViewModel()

        viewModel.startPracticeSession(kana: rowKana, exerciseType: .listening)

        XCTAssertEqual(Set(viewModel.practiceSession.map(\.id)), Set(rowKana.map(\.id)))
        XCTAssertEqual(viewModel.exerciseType, .listening)
        XCTAssertNotNil(viewModel.currentKana)
    }
}
