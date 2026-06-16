import XCTest
@testable import Maru

@MainActor
final class PracticeViewModelTests: XCTestCase {
    private func sampleHiraganaRow() -> [SharedKana] {
        [
            SharedKana(id: "h_basic_1", character: "あ", romaji: "a", kanaType: .hiragana, category: "basic"),
            SharedKana(id: "h_basic_2", character: "い", romaji: "i", kanaType: .hiragana, category: "basic"),
            SharedKana(id: "h_basic_3", character: "う", romaji: "u", kanaType: .hiragana, category: "basic"),
            SharedKana(id: "h_basic_4", character: "え", romaji: "e", kanaType: .hiragana, category: "basic"),
            SharedKana(id: "h_basic_5", character: "お", romaji: "o", kanaType: .hiragana, category: "basic")
        ]
    }

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

    func testCorrectAnswerUpdatesFeedbackOnce() {
        let kana = [
            SharedKana(id: "h_basic_1", character: "あ", romaji: "a", kanaType: .hiragana, category: "basic")
        ]
        let viewModel = PracticeViewModel()

        viewModel.startPracticeSession(kana: kana, exerciseType: .spelling)
        viewModel.typedAnswer = "a"
        viewModel.submitTypedAnswer()
        viewModel.submitTypedAnswer()

        XCTAssertEqual(viewModel.score, 1)
        XCTAssertEqual(viewModel.totalQuestions, 1)
        XCTAssertEqual(viewModel.mascotExpression, .celebrating)
        XCTAssertTrue(viewModel.answerFeedbackID > 0)
    }

    func testAnswerFeedbackEventCapturesSelectedAndCorrectAnswer() throws {
        let rowKana = sampleHiraganaRow()
        let viewModel = PracticeViewModel()
        viewModel.startPracticeSession(kana: rowKana, exerciseType: .multipleChoice)
        let current = try XCTUnwrap(viewModel.currentKana)
        let wrongAnswer = try XCTUnwrap(viewModel.choices.first { $0.answer != current.romaji }?.answer)

        viewModel.selectAnswer(wrongAnswer)

        XCTAssertEqual(viewModel.answerFeedback?.selectedAnswer, wrongAnswer)
        XCTAssertEqual(viewModel.answerFeedback?.correctAnswer, current.romaji)
        XCTAssertEqual(viewModel.answerFeedback?.isCorrect, false)
        XCTAssertEqual(viewModel.answerFeedback?.id, viewModel.answerFeedbackID)
    }

    func testAnswerFeedbackClearsWhenNextQuestionLoads() throws {
        let rowKana = sampleHiraganaRow()
        let viewModel = PracticeViewModel()
        viewModel.startPracticeSession(kana: rowKana, exerciseType: .multipleChoice)
        let current = try XCTUnwrap(viewModel.currentKana)

        viewModel.selectAnswer(current.romaji)
        XCTAssertNotNil(viewModel.answerFeedback)

        viewModel.nextQuestion()

        XCTAssertNil(viewModel.answerFeedback)
    }

    func testMultipleChoiceDoesNotRevealPromptCharacterInChoiceSubtitle() {
        let rowKana = sampleHiraganaRow()
        let viewModel = PracticeViewModel()

        viewModel.startPracticeSession(kana: rowKana, exerciseType: .multipleChoice)

        XCTAssertFalse(viewModel.choices.contains { $0.sublabel == viewModel.currentKana?.character })
    }

    func testReadingDoesNotRevealRomajiInChoiceSubtitle() {
        let rowKana = sampleHiraganaRow()
        let viewModel = PracticeViewModel()

        viewModel.startPracticeSession(kana: rowKana, exerciseType: .reading)

        XCTAssertFalse(viewModel.choices.contains { $0.sublabel == viewModel.currentKana?.romaji })
    }

    func testRowSpecificPracticeUsesProvidedKanaAsChoicePool() {
        let rowKana = sampleHiraganaRow()
        let viewModel = PracticeViewModel()

        viewModel.startPracticeSession(kana: rowKana, exerciseType: .reading)

        XCTAssertEqual(viewModel.choices.count, 4)
        XCTAssertTrue(Set(viewModel.choices.map(\.id)).isSubset(of: Set(rowKana.map(\.id))))
    }

    func testSmallFocusedChoicePoolPadsDistractorsFromFallbackPool() {
        let rowKana = sampleHiraganaRow()
        let viewModel = PracticeViewModel()

        viewModel.startPracticeSession(
            kana: [rowKana[0]],
            exerciseType: .multipleChoice,
            fallbackChoicePool: rowKana
        )

        XCTAssertEqual(viewModel.choices.count, 4)
        XCTAssertEqual(viewModel.choices.filter { $0.answer == rowKana[0].romaji }.count, 1)
        XCTAssertTrue(Set(viewModel.choices.map(\.id)).isSubset(of: Set(rowKana.map(\.id))))
    }

    func testMixedModeExcludesTracePractice() {
        let rowKana = sampleHiraganaRow()
        let viewModel = PracticeViewModel()

        viewModel.startPracticeSession(kana: rowKana)

        for _ in rowKana.indices {
            XCTAssertNotEqual(viewModel.exerciseType, .writing)
            viewModel.nextQuestion()
        }
    }
}
