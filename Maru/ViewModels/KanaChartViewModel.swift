import Foundation
import SwiftUI

@MainActor
final class KanaChartViewModel: ObservableObject {
    @Published var selectedType: AppConstants.KanaType = .hiragana
    @Published var selectedCategory: String = "basic"
    @Published var kanaGrid: [SharedKana] = []
    @Published var selectedKana: SharedKana?
    @Published var progressMap: [String: SharedProgress] = [:]

    private let repository = KanaRepository.shared
    private let audioService = AudioService.shared
    private let database = SharedDatabase.shared

    let categories = ["basic", "dakuten", "combination"]

    init() {
        loadKanaGrid()
        loadProgress()
    }

    func loadKanaGrid() {
        let filtered = repository.getAllKana().filter {
            $0.kanaType == selectedType && $0.category == selectedCategory
        }
        kanaGrid = filtered
    }

    func loadProgress() {
        let allProgress = (try? database.getAllProgress()) ?? []
        progressMap = Dictionary(uniqueKeysWithValues: allProgress.map { ($0.id, $0) })
    }

    func selectType(_ type: AppConstants.KanaType) {
        selectedType = type
        loadKanaGrid()
    }

    func selectCategory(_ category: String) {
        selectedCategory = category
        loadKanaGrid()
    }

    func selectKana(_ kana: SharedKana) {
        selectedKana = kana
        audioService.playKana(kana)
    }

    func getProgress(for kana: SharedKana) -> SharedProgress? {
        return progressMap[kana.id]
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
