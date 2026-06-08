import Foundation

final class DailyKanaService {
    static let shared = DailyKanaService()

    private let database = SharedDatabase.shared
    private let repository = KanaRepository.shared

    private init() {}

    func getDailyCharacter() -> SharedKana {
        let today = Date()

        // Check if we already have a selection for today
        if let existing = try? database.getDailySelection(for: today, widgetType: .dailyCharacter),
           let kana = repository.getKana(byId: existing.kanaId) {
            return kana
        }

        // Select a new character - prefer weak ones
        let weakKana = repository.getWeakKana(limit: 20)
        let allKana = repository.getAllKana()

        let selectedKana: SharedKana
        if let weak = weakKana.randomElement() {
            selectedKana = weak
        } else {
            selectedKana = allKana.randomElement()!
        }

        // Save selection
        let selection = DailyKanaSelection(
            kanaId: selectedKana.id,
            date: today,
            widgetType: .dailyCharacter
        )
        try? database.saveDailySelection(selection)

        return selectedKana
    }

    func getFlashcardKana() -> SharedKana {
        let today = Date()

        // Check if we already have a selection for today
        if let existing = try? database.getDailySelection(for: today, widgetType: .flashcard),
           let kana = repository.getKana(byId: existing.kanaId) {
            return kana
        }

        // Get a different character for flashcard
        let weakKana = repository.getWeakKana(limit: 20)
        let allKana = repository.getAllKana()

        let selectedKana: SharedKana
        if let weak = weakKana.randomElement() {
            selectedKana = weak
        } else {
            selectedKana = allKana.randomElement()!
        }

        // Save selection
        let selection = DailyKanaSelection(
            kanaId: selectedKana.id,
            date: today,
            widgetType: .flashcard
        )
        try? database.saveDailySelection(selection)

        return selectedKana
    }

    func getKanaForWidget() -> (daily: SharedKana, flashcard: SharedKana) {
        return (getDailyCharacter(), getFlashcardKana())
    }
}