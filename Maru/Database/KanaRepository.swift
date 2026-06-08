import Foundation

final class KanaRepository {
    static let shared = KanaRepository()

    private var kanaData: [SharedKana] = []
    private var wordsData: [SharedWord] = []

    private init() {}

    // MARK: - Loading Data

    func loadKanaData() {
        guard let url = Bundle.main.url(forResource: "kana_data", withExtension: "json") else {
            print("kana_data.json not found in bundle")
            return
        }

        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            kanaData = try decoder.decode([SharedKana].self, from: data)
            print("Loaded \(kanaData.count) kana entries")
        } catch {
            print("Failed to load kana data: \(error)")
        }
    }

    func loadWordsData() {
        guard let url = Bundle.main.url(forResource: "words_data", withExtension: "json") else {
            print("words_data.json not found in bundle")
            return
        }

        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            wordsData = try decoder.decode([SharedWord].self, from: data)
            print("Loaded \(wordsData.count) vocabulary entries")
        } catch {
            print("Failed to load words data: \(error)")
        }
    }

    // MARK: - Kana Access Methods

    func getAllKana() -> [SharedKana] {
        return kanaData
    }

    func getKana(byId id: String) -> SharedKana? {
        return kanaData.first { $0.id == id }
    }

    func getKana(byType type: AppConstants.KanaType) -> [SharedKana] {
        return kanaData.filter { $0.kanaType == type }
    }

    func getKana(byCategory category: String) -> [SharedKana] {
        return kanaData.filter { $0.category == category }
    }

    func getRandomKana(limit: Int = 10) -> [SharedKana] {
        let shuffled = kanaData.shuffled()
        return Array(shuffled.prefix(limit))
    }

    func getWeakKana(limit: Int = 10) -> [SharedKana] {
        // This method would need progress data from SharedDatabase
        // For now, return random kana as a fallback
        // In full implementation, this would cross-reference with progress data
        let shuffled = kanaData.filter { kana in
            guard let progress = try? SharedDatabase.shared.getProgress(forKanaId: kana.id) else {
                return false
            }
            return progress.accuracy < 0.7 && progress.totalAttempts >= 3
        }.sorted { ($0.accuracy) < ($1.accuracy) }

        return Array(shuffled.prefix(limit))
    }

    // MARK: - Words Access Methods

    func getAllWords() -> [SharedWord] {
        return wordsData
    }

    func getWord(byId id: String) -> SharedWord? {
        return wordsData.first { $0.id == id }
    }

    func getRandomWords(limit: Int = 10) -> [SharedWord] {
        let shuffled = wordsData.shuffled()
        return Array(shuffled.prefix(limit))
    }

    func getWords(byCategory category: String) -> [SharedWord] {
        // Filter words by category if needed
        return wordsData
    }
}