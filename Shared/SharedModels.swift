import Foundation

struct SharedKana: Codable, Identifiable, Hashable {
    let id: String
    let character: String
    let romaji: String
    let kanaType: AppConstants.KanaType
    let category: String // basic, dakuten, combination
    let strokeOrder: [String]
    let audioFileName: String?

    init(id: String, character: String, romaji: String, kanaType: AppConstants.KanaType, category: String, strokeOrder: [String] = [], audioFileName: String? = nil) {
        self.id = id
        self.character = character
        self.romaji = romaji
        self.kanaType = kanaType
        self.category = category
        self.strokeOrder = strokeOrder
        self.audioFileName = audioFileName
    }
}

struct SharedProgress: Codable, Identifiable {
    let id: String // kana id
    var mistakeCount: Int
    var correctCount: Int
    var lastPracticed: Date?
    var masteryLevel: AppConstants.MasteryLevel

    var totalAttempts: Int { mistakeCount + correctCount }
    var accuracy: Double {
        guard totalAttempts > 0 else { return 0 }
        return Double(correctCount) / Double(totalAttempts)
    }
}

struct SharedWord: Codable, Identifiable {
    let id: String
    let word: String
    let romaji: String
    let meaning: String
    let audioFileName: String?
}

struct DailyKanaSelection: Codable {
    let kanaId: String
    let date: Date
    let widgetType: WidgetType

    enum WidgetType: String, Codable {
        case dailyCharacter
        case flashcard
    }
}

// MARK: - Mascot Expression

enum MascotExpression: String, CaseIterable {
    case happy
    case thinking
    case celebrating
    case neutral
    case sad
}
