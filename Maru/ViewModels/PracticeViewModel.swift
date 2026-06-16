import Foundation
import SwiftUI

@MainActor
final class PracticeViewModel: ObservableObject {
    @Published var currentKana: SharedKana?
    @Published var options: [String] = []
    @Published var choices: [PracticeChoice] = []
    @Published var selectedAnswer: String?
    @Published var isCorrect: Bool?
    @Published var score: Int = 0
    @Published var totalQuestions: Int = 0
    @Published var mistakeCount: Int = 0
    @Published var practiceSession: [SharedKana] = []
    @Published var currentIndex: Int = 0
    @Published var isSessionComplete: Bool = false
    @Published var exerciseType: ExerciseType = .multipleChoice
    @Published var typedAnswer: String = ""
    @Published var answerFeedbackID: Int = 0

    private let repository = KanaRepository.shared
    private let audioService = AudioService.shared
    private let hapticService = HapticService.shared
    private let database = SharedDatabase.shared
    private var fixedExerciseType: ExerciseType?
    private let standardSessionLength = 15
    private let focusedSessionLength = 12
    private let mixedExerciseTypes: [ExerciseType] = [.multipleChoice, .listening, .reading, .spelling]
    private var activeChoicePool: [SharedKana] = []
    private var fallbackChoicePool: [SharedKana] = []

    enum ExerciseType: String, CaseIterable {
        case multipleChoice = "Choose"
        case listening = "Listening"
        case reading = "Reading"
        case spelling = "Typing"
        case writing = "Trace"
    }

    struct PracticeChoice: Identifiable, Hashable {
        let id: String
        let label: String
        let sublabel: String?
        let answer: String
        let usesSpeakerIcon: Bool
    }

    @Published var mascotExpression: MascotExpression = .thinking

    init() {}

    func startPracticeSession(
        kanaType: AppConstants.KanaType? = nil,
        focusOnWeak: Bool = false,
        exerciseType: ExerciseType? = nil
    ) {
        fixedExerciseType = exerciseType
        let kanaList: [SharedKana]
        let fallbackChoices: [SharedKana]

        if focusOnWeak {
            let weakKana = repository.getWeakKana(limit: focusedSessionLength)
            kanaList = weakKana.isEmpty ? repository.getRandomKana(limit: standardSessionLength) : weakKana
            fallbackChoices = weakKana.isEmpty ? [] : repository.getAllKana()
        } else if let type = kanaType {
            kanaList = Array(repository.getKana(byType: type).shuffled().prefix(standardSessionLength))
            fallbackChoices = []
        } else {
            kanaList = repository.getRandomKana(limit: standardSessionLength)
            fallbackChoices = []
        }

        activeChoicePool = kanaList
        fallbackChoicePool = fallbackChoices
        practiceSession = kanaList.shuffled()
        currentIndex = 0
        score = 0
        totalQuestions = 0
        mistakeCount = 0
        isSessionComplete = false

        loadCurrentQuestion()
    }

    func startPracticeSession(
        kana: [SharedKana],
        exerciseType: ExerciseType? = nil,
        fallbackChoicePool: [SharedKana] = []
    ) {
        fixedExerciseType = exerciseType
        activeChoicePool = kana
        self.fallbackChoicePool = fallbackChoicePool
        practiceSession = kana.shuffled()
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
        exerciseType = fixedExerciseType ?? mixedExerciseTypes[currentIndex % mixedExerciseTypes.count]
        generateOptions()
        selectedAnswer = nil
        isCorrect = nil
        typedAnswer = ""
        withAnimation(.spring(response: 0.28, dampingFraction: 0.74)) {
            mascotExpression = .neutral
        }

        if exerciseType == .listening {
            playCurrentKana()
        }
    }

    private func generateOptions() {
        guard let current = currentKana else { return }

        let choicePool = expandedChoicePool(for: current)
        let otherKana = choicePool.filter { $0.id != current.id && $0.romaji != current.romaji }
        let optionKana = (Array(otherKana.shuffled().prefix(3)) + [current]).shuffled()

        switch exerciseType {
        case .multipleChoice:
            choices = optionKana.map { kana in
                PracticeChoice(
                    id: kana.id,
                    label: kana.romaji,
                    sublabel: nil,
                    answer: kana.romaji,
                    usesSpeakerIcon: false
                )
            }
        case .listening:
            choices = optionKana.map { kana in
                PracticeChoice(
                    id: kana.id,
                    label: kana.character,
                    sublabel: nil,
                    answer: kana.romaji,
                    usesSpeakerIcon: false
                )
            }
        case .reading:
            choices = optionKana.map { kana in
                PracticeChoice(
                    id: kana.id,
                    label: kana.character,
                    sublabel: nil,
                    answer: kana.romaji,
                    usesSpeakerIcon: false
                )
            }
        case .spelling, .writing:
            choices = []
        }

        options = choices.map(\.answer)
    }

    private func expandedChoicePool(for current: SharedKana) -> [SharedKana] {
        let primaryPool = activeChoicePool.isEmpty ? practiceSession : activeChoicePool
        let primaryChoices = uniqueByRomaji(primaryPool)
        let availableDistractors = primaryChoices.filter { $0.romaji != current.romaji }.count

        guard availableDistractors < 3, !fallbackChoicePool.isEmpty else {
            return primaryChoices
        }

        let sameTypeFallback = fallbackChoicePool.filter { $0.kanaType == current.kanaType }
        let sameTypeChoices = uniqueByRomaji(primaryPool + sameTypeFallback)
        if sameTypeChoices.filter({ $0.romaji != current.romaji }).count >= 3 {
            return sameTypeChoices
        }

        return uniqueByRomaji(primaryPool + fallbackChoicePool)
    }

    private func uniqueByRomaji(_ kanaList: [SharedKana]) -> [SharedKana] {
        var seenRomaji: Set<String> = []
        return kanaList.filter { kana in
            seenRomaji.insert(kana.romaji).inserted
        }
    }

    func selectAnswer(_ answer: String) {
        guard let current = currentKana else { return }
        guard selectedAnswer == nil else { return }

        withAnimation(.spring(response: 0.26, dampingFraction: 0.72)) {
            selectedAnswer = answer
            totalQuestions += 1
            answerFeedbackID += 1
        }

        if answer == current.romaji {
            hapticService.success()
            score += 1
            withAnimation(.spring(response: 0.32, dampingFraction: 0.66)) {
                isCorrect = true
                mascotExpression = .celebrating
            }
            updateProgress(for: current, correct: true)
        } else {
            hapticService.error()
            mistakeCount += 1
            withAnimation(.spring(response: 0.32, dampingFraction: 0.66)) {
                isCorrect = false
                mascotExpression = .sad
            }
            updateProgress(for: current, correct: false)
        }
    }

    func submitTypedAnswer() {
        selectAnswer(typedAnswer.trimmingCharacters(in: .whitespacesAndNewlines).lowercased())
    }

    func completeWritingPractice() {
        guard let currentKana else { return }
        selectAnswer(currentKana.romaji)
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
        hapticService.selection()
        currentIndex += 1
        loadCurrentQuestion()
    }

    func playCurrentKana() {
        guard let kana = currentKana else { return }
        hapticService.impact(.light)
        audioService.playKana(kana)
    }

    func restartSession() {
        if !practiceSession.isEmpty {
            startPracticeSession(kana: practiceSession, exerciseType: fixedExerciseType, fallbackChoicePool: fallbackChoicePool)
        } else {
            startPracticeSession()
        }
    }

    func resetSession() {
        currentKana = nil
        options = []
        choices = []
        selectedAnswer = nil
        isCorrect = nil
        score = 0
        totalQuestions = 0
        mistakeCount = 0
        practiceSession = []
        currentIndex = 0
        isSessionComplete = false
        exerciseType = .multipleChoice
        typedAnswer = ""
        fixedExerciseType = nil
        activeChoicePool = []
        fallbackChoicePool = []
        mascotExpression = .thinking
    }
}
