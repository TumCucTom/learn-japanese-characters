import Foundation
import SwiftUI

@MainActor
final class PracticeViewModel: ObservableObject {
    @Published var currentKana: SharedKana?
    @Published var options: [String] = []
    @Published var selectedAnswer: String?
    @Published var isCorrect: Bool?
    @Published var score: Int = 0
    @Published var totalQuestions: Int = 0
    @Published var mistakeCount: Int = 0
    @Published var practiceSession: [SharedKana] = []
    @Published var currentIndex: Int = 0
    @Published var isSessionComplete: Bool = false
    @Published var exerciseType: ExerciseType = .multipleChoice

    private let repository = KanaRepository.shared
    private let audioService = AudioService.shared
    private let database = SharedDatabase.shared

    enum ExerciseType: String, CaseIterable {
        case multipleChoice = "Multiple Choice"
        case listening = "Listening"
        case reading = "Reading"
        case spelling = "Spelling"
    }

    enum MascotExpression {
        case happy
        case thinking
        case celebrating
        case sad
    }

    @Published var mascotExpression: MascotExpression = .neutral

    init() {}

    func startPracticeSession(kanaType: AppConstants.KanaType? = nil, focusOnWeak: Bool = false) {
        let kanaList: [SharedKana]

        if focusOnWeak {
            kanaList = repository.getWeakKana(limit: 20)
        } else if let type = kanaType {
            kanaList = repository.getKana(byType: type)
        } else {
            kanaList = repository.getRandomKana(limit: 15)
        }

        practiceSession = kanaList.shuffled()
        currentIndex = 0
        score = 0
        totalQuestions = 0
        mistakeCount = 0
        isSessionComplete = false

        loadCurrentQuestion()
    }

    func loadCurrentQuestion() {
        guard currentIndex < practiceSession.count else {
            isSessionComplete = true
            return
        }

        currentKana = practiceSession[currentIndex]
        generateOptions()
        selectedAnswer = nil
        isCorrect = nil
        mascotExpression = .neutral
    }

    private func generateOptions() {
        guard let current = currentKana else { return }

        let allKana = repository.getAllKana()
        let otherKana = allKana.filter { $0.id != current.id }

        var wrongOptions = otherKana.shuffled().prefix(3).map { $0.romaji }
        wrongOptions.append(current.romaji)
        options = wrongOptions.shuffled()
    }

    func selectAnswer(_ answer: String) {
        guard let current = currentKana else { return }

        selectedAnswer = answer
        totalQuestions += 1

        if answer == current.romaji {
            isCorrect = true
            score += 1
            mascotExpression = .celebrating
            updateProgress(for: current, correct: true)
        } else {
            isCorrect = false
            mistakeCount += 1
            mascotExpression = .sad
            updateProgress(for: current, correct: false)
        }
    }

    private func updateProgress(for kana: SharedKana, correct: Bool) {
        var progress = (try? database.getProgress(forKanaId: kana.id)) ?? SharedProgress(
            id: kana.id,
            mistakeCount: 0,
            correctCount: 0,
            lastPracticed: nil,
            masteryLevel: .new
        )

        if correct {
            progress.correctCount += 1
        } else {
            progress.mistakeCount += 1
        }

        progress.lastPracticed = Date()

        // Update mastery level based on accuracy
        if progress.accuracy >= 0.9 && progress.totalAttempts >= 10 {
            progress.masteryLevel = .mastered
        } else if progress.accuracy >= 0.7 && progress.totalAttempts >= 5 {
            progress.masteryLevel = .familiar
        } else if progress.totalAttempts >= 3 {
            progress.masteryLevel = .learning
        }

        try? database.insertOrUpdateProgress(progress)
    }

    func nextQuestion() {
        currentIndex += 1
        loadCurrentQuestion()
    }

    func playCurrentKana() {
        guard let kana = currentKana else { return }
        audioService.playKana(kana)
    }

    func restartSession() {
        startPracticeSession()
    }
}
