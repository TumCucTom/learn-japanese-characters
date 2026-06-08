import WidgetKit
import Foundation

// MARK: - Widget Timeline Entry

struct KanaWidgetEntry: TimelineEntry {
    let date: Date
    let kana: SharedKana
    let configuration: ConfigurationAppIntent
}

struct FlashcardWidgetEntry: TimelineEntry {
    let date: Date
    let kana: SharedKana
    let hint: String
    let configuration: ConfigurationAppIntent
}

struct LockScreenWidgetEntry: TimelineEntry {
    let date: Date
    let kana: SharedKana
    let configuration: ConfigurationAppIntent
}

// MARK: - Configuration Intent

struct ConfigurationAppIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Configuration"
    static var description = IntentDescription("Configure the Maru widget.")

    @Parameter(title: "Kana Type", default: .hiragana)
    var kanaType: KanaTypeOption

    enum KanaTypeOption: String, AppEnum {
        case hiragana
        case katakana

        static var typeDisplayRepresentation: TypeDisplayRepresentation = "Kana Type"

        static var caseDisplayRepresentations: [KanaTypeOption: DisplayRepresentation] = [
            .hiragana: "Hiragana",
            .katakana: "Katakana"
        ]
    }
}

// MARK: - Widget Daily Kana Service

final class WidgetDailyKanaService {
    static let shared = WidgetDailyKanaService()

    private let database = SharedDatabase.shared

    private init() {}

    func getDailyCharacter() -> SharedKana {
        let today = Date()

        // Check if we already have a selection for today
        if let existing = try? database.getDailySelection(for: today, widgetType: .dailyCharacter),
           let kana = try? database.getKana(byId: existing.kanaId) {
            return kana
        }

        // Select a new character from available kana
        guard let allKana = try? database.getAllKana(), !allKana.isEmpty else {
            // Return a fallback kana if database is empty
            return SharedKana(
                id: "hiragana_a",
                character: "あ",
                romaji: "a",
                kanaType: .hiragana,
                category: "basic",
                strokeOrder: [],
                audioFileName: nil
            )
        }

        let selectedKana = allKana.randomElement()!

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
           let kana = try? database.getKana(byId: existing.kanaId) {
            return kana
        }

        // Get a random character for flashcard
        guard let allKana = try? database.getAllKana(), !allKana.isEmpty else {
            return SharedKana(
                id: "hiragana_a",
                character: "あ",
                romaji: "a",
                kanaType: .hiragana,
                category: "basic",
                strokeOrder: [],
                audioFileName: nil
            )
        }

        let selectedKana = allKana.randomElement()!

        // Save selection
        let selection = DailyKanaSelection(
            kanaId: selectedKana.id,
            date: today,
            widgetType: .flashcard
        )
        try? database.saveDailySelection(selection)

        return selectedKana
    }
}

// MARK: - Timeline Provider

struct DailyKanaProvider: AppIntentTimelineProvider {
    typealias Entry = KanaWidgetEntry
    typealias Intent = ConfigurationAppIntent

    func placeholder(in context: Context) -> KanaWidgetEntry {
        KanaWidgetEntry(
            date: Date(),
            kana: SharedKana(
                id: "placeholder",
                character: "あ",
                romaji: "a",
                kanaType: .hiragana,
                category: "basic",
                strokeOrder: [],
                audioFileName: nil
            ),
            configuration: ConfigurationAppIntent()
        )
    }

    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> KanaWidgetEntry {
        let kana = WidgetDailyKanaService.shared.getDailyCharacter()
        return KanaWidgetEntry(date: Date(), kana: kana, configuration: configuration)
    }

    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<KanaWidgetEntry> {
        let kana = WidgetDailyKanaService.shared.getDailyCharacter()

        // Update at midnight
        let calendar = Calendar.current
        let tomorrow = calendar.startOfDay(for: calendar.date(byAdding: .day, value: 1, to: Date())!)

        let entry = KanaWidgetEntry(date: Date(), kana: kana, configuration: configuration)
        return Timeline(entries: [entry], policy: .after(tomorrow))
    }
}

struct FlashcardProvider: AppIntentTimelineProvider {
    typealias Entry = FlashcardWidgetEntry
    typealias Intent = ConfigurationAppIntent

    func placeholder(in context: Context) -> FlashcardWidgetEntry {
        FlashcardWidgetEntry(
            date: Date(),
            kana: SharedKana(
                id: "placeholder",
                character: "あ",
                romaji: "a",
                kanaType: .hiragana,
                category: "basic",
                strokeOrder: [],
                audioFileName: nil
            ),
            hint: "Tap to reveal",
            configuration: ConfigurationAppIntent()
        )
    }

    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> FlashcardWidgetEntry {
        let kana = WidgetDailyKanaService.shared.getFlashcardKana()
        return FlashcardWidgetEntry(date: Date(), kana: kana, hint: kana.romaji, configuration: configuration)
    }

    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<FlashcardWidgetEntry> {
        let kana = WidgetDailyKanaService.shared.getFlashcardKana()

        // Update at midnight
        let calendar = Calendar.current
        let tomorrow = calendar.startOfDay(for: calendar.date(byAdding: .day, value: 1, to: Date())!)

        let entry = FlashcardWidgetEntry(date: Date(), kana: kana, hint: kana.romaji, configuration: configuration)
        return Timeline(entries: [entry], policy: .after(tomorrow))
    }
}

struct LockScreenProvider: AppIntentTimelineProvider {
    typealias Entry = LockScreenWidgetEntry
    typealias Intent = ConfigurationAppIntent

    func placeholder(in context: Context) -> LockScreenWidgetEntry {
        LockScreenWidgetEntry(
            date: Date(),
            kana: SharedKana(
                id: "placeholder",
                character: "あ",
                romaji: "a",
                kanaType: .hiragana,
                category: "basic",
                strokeOrder: [],
                audioFileName: nil
            ),
            configuration: ConfigurationAppIntent()
        )
    }

    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> LockScreenWidgetEntry {
        let kana = WidgetDailyKanaService.shared.getDailyCharacter()
        return LockScreenWidgetEntry(date: Date(), kana: kana, configuration: configuration)
    }

    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<LockScreenWidgetEntry> {
        let kana = WidgetDailyKanaService.shared.getDailyCharacter()

        // Update at midnight
        let calendar = Calendar.current
        let tomorrow = calendar.startOfDay(for: calendar.date(byAdding: .day, value: 1, to: Date())!)

        let entry = LockScreenWidgetEntry(date: Date(), kana: kana, configuration: configuration)
        return Timeline(entries: [entry], policy: .after(tomorrow))
    }
}