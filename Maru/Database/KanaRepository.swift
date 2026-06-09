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

            // Seed shared database for widgets
            try SharedDatabase.shared.seedKanaIfNeeded(from: kanaData)
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
        // Get kana with progress that indicates weakness (low accuracy, enough attempts)
        var weakKana: [(kana: SharedKana, progress: SharedProgress)] = []
        
        for kana in kanaData {
            if let progress = try? SharedDatabase.shared.getProgress(forKanaId: kana.id) {
                if progress.accuracy < 0.7 && progress.totalAttempts >= 3 {
                    weakKana.append((kana, progress))
                }
            }
        }
        
        // Sort by accuracy (lowest first)
        weakKana.sort { $0.progress.accuracy < $1.progress.accuracy }
        
        return weakKana.prefix(limit).map { $0.kana }
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