import Foundation
import SwiftUI

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var mascotExpression: MascotExpression = .happy
    @Published var currentWord: SharedWord?
    @Published var wordCloud: [SharedWord] = []
    @Published var currentDateJapanese: String = ""
    @Published var currentTimeJapanese: String = ""
    @Published var hiraganaProgress: Double = 0
    @Published var katakanaProgress: Double = 0
    @Published var nextHiraganaRow: KanaLearningPath.Row?
    @Published var nextKatakanaRow: KanaLearningPath.Row?

    private let repository = KanaRepository.shared
    private let audioService = AudioService.shared
    private let database = SharedDatabase.shared

    init() {
        loadWordCloud()
        loadLearningProgress()
        updateDateTime()
    }

    func loadWordCloud() {
        wordCloud = repository.getRandomWords(limit: 12)
        currentWord = wordCloud.randomElement()
    }

    func updateDateTime() {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年MM月dd日"
        currentDateJapanese = formatter.string(from: Date())

        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"
        currentTimeJapanese = timeFormatter.string(from: Date())
    }

    func playWord(_ word: SharedWord) {
        // Show thinking expression while audio plays
        setExpression(.thinking)

        // Play audio
        audioService.playWord(word)

        // Return to happy after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { [weak self] in
            self?.setExpression(.happy)
        }
    }

    func setExpression(_ expression: MascotExpression) {
        withAnimation(.easeInOut(duration: 0.3)) {
            mascotExpression = expression
        }
    }

    func refreshWordCloud() {
        loadWordCloud()
        loadLearningProgress()
        setExpression(.happy)
    }

    func loadLearningProgress() {
        let progressMap = Dictionary(
            uniqueKeysWithValues: ((try? database.getAllProgress()) ?? []).map { ($0.id, $0) }
        )
        let allKana = repository.getAllKana()
        let hiraganaRows = KanaLearningPath.rows(for: allKana, type: .hiragana)
        let katakanaRows = KanaLearningPath.rows(for: allKana, type: .katakana)

        hiraganaProgress = masteredFraction(rows: hiraganaRows, progressMap: progressMap)
        katakanaProgress = masteredFraction(rows: katakanaRows, progressMap: progressMap)
        nextHiraganaRow = firstActiveRow(rows: hiraganaRows, progressMap: progressMap)
        nextKatakanaRow = firstActiveRow(rows: katakanaRows, progressMap: progressMap)
    }

    private func masteredFraction(rows: [KanaLearningPath.Row], progressMap: [String: SharedProgress]) -> Double {
        let kana = rows.flatMap(\.kana)
        guard !kana.isEmpty else { return 0 }

        let masteredCount = kana.filter { progressMap[$0.id]?.masteryLevel == .mastered }.count
        return Double(masteredCount) / Double(kana.count)
    }

    private func firstActiveRow(rows: [KanaLearningPath.Row], progressMap: [String: SharedProgress]) -> KanaLearningPath.Row? {
        let statuses = KanaLearningPath.status(for: rows, progressMap: progressMap)
        return rows.first { row in
            let status = statuses[row.id] ?? .locked
            return status == .unlocked || status == .learning
        } ?? rows.first
    }
}
