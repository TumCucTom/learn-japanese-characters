import Foundation
import SwiftUI

@MainActor
final class KanaChartViewModel: ObservableObject {
    @Published var selectedType: AppConstants.KanaType = .hiragana
    @Published var selectedCategory: String = "basic"
    @Published var kanaGrid: [SharedKana] = []
    @Published var selectedKana: SharedKana?
    @Published var progressMap: [String: SharedProgress] = [:]
    @Published var rows: [KanaLearningPath.Row] = []
    @Published var rowStatuses: [String: KanaLearningPath.RowStatus] = [:]

    private let repository = KanaRepository.shared
    private let audioService = AudioService.shared
    private let hapticService = HapticService.shared
    private let database = SharedDatabase.shared

    let categories = ["basic", "dakuten", "combination"]

    init() {
        loadProgress()
        loadKanaGrid()
    }

    func loadKanaGrid() {
        let filtered = repository.getAllKana().filter {
            $0.kanaType == selectedType && $0.category == selectedCategory
        }
        kanaGrid = filtered
        rows = KanaLearningPath.rows(for: repository.getAllKana(), type: selectedType)
        rowStatuses = KanaLearningPath.status(for: rows, progressMap: progressMap)
    }

    func loadProgress() {
        let allProgress = (try? database.getAllProgress()) ?? []
        progressMap = Dictionary(uniqueKeysWithValues: allProgress.map { ($0.id, $0) })
        rowStatuses = KanaLearningPath.status(for: rows, progressMap: progressMap)
    }

    func selectType(_ type: AppConstants.KanaType) {
        hapticService.selection()
        selectedType = type
        loadKanaGrid()
    }

    func selectCategory(_ category: String) {
        hapticService.selection()
        selectedCategory = category
        loadKanaGrid()
    }

    func selectKana(_ kana: SharedKana) {
        hapticService.impact(.light)
        selectedKana = kana
        audioService.playKana(kana)
    }

    func getProgress(for kana: SharedKana) -> SharedProgress? {
        return progressMap[kana.id]
    }

    func status(for row: KanaLearningPath.Row) -> KanaLearningPath.RowStatus {
        return rowStatuses[row.id] ?? .locked
    }

    func practicedFraction(for row: KanaLearningPath.Row) -> Double {
        return KanaLearningPath.practicedFraction(for: row, progressMap: progressMap)
    }

    func getMasteryColor(for kana: SharedKana) -> Color {
        guard let progress = getProgress(for: kana) else {
            return Color.gray.opacity(0.2)
        }

        switch progress.masteryLevel {
        case .new:
            return Color.gray.opacity(0.2)
        case .learning:
            return Color.orange.opacity(0.4)
        case .familiar:
            return Color.yellow.opacity(0.5)
        case .mastered:
            return Color.green.opacity(0.5)
        }
    }
}
