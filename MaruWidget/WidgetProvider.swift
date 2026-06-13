import WidgetKit
import AppIntents
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

        var appKanaType: AppConstants.KanaType {
            switch self {
            case .hiragana:
                return .hiragana
            case .katakana:
                return .katakana
            }
        }
    }
}

// MARK: - Widget Daily Kana Service

final class WidgetDailyKanaService {
    static let shared = WidgetDailyKanaService()

    private let database = SharedDatabase.shared

    private init() {}

    func getDailyCharacter(kanaType: AppConstants.KanaType, date: Date = Date()) -> SharedKana {
        guard let allKana = try? database.getAllKana(), !allKana.isEmpty else {
            return fallbackKana(for: kanaType)
        }

        return WidgetKanaSelector.select(
            from: allKana,
            type: kanaType,
            date: date,
            salt: "daily-character"
        ) ?? fallbackKana(for: kanaType)
    }

    func getFlashcardKana(kanaType: AppConstants.KanaType, date: Date = Date()) -> SharedKana {
        guard let allKana = try? database.getAllKana(), !allKana.isEmpty else {
            return fallbackKana(for: kanaType)
        }

        return WidgetKanaSelector.select(
            from: allKana,
            type: kanaType,
            date: date,
            salt: "flashcard"
        ) ?? fallbackKana(for: kanaType)
    }

    private func fallbackKana(for type: AppConstants.KanaType) -> SharedKana {
        switch type {
        case .hiragana:
            return SharedKana(
                id: "h_basic_1",
                character: "あ",
                romaji: "a",
                kanaType: .hiragana,
                category: "basic"
            )
        case .katakana:
            return SharedKana(
                id: "k_basic_1",
                character: "ア",
                romaji: "a",
                kanaType: .katakana,
                category: "basic"
            )
        }
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
        let kana = WidgetDailyKanaService.shared.getDailyCharacter(kanaType: configuration.kanaType.appKanaType)
        return KanaWidgetEntry(date: Date(), kana: kana, configuration: configuration)
    }

    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<KanaWidgetEntry> {
        let date = Date()
        let kana = WidgetDailyKanaService.shared.getDailyCharacter(kanaType: configuration.kanaType.appKanaType, date: date)

        let entry = KanaWidgetEntry(date: date, kana: kana, configuration: configuration)
        return Timeline(entries: [entry], policy: .after(WidgetTimelineSchedule.nextRefresh(after: date)))
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
        let kana = WidgetDailyKanaService.shared.getFlashcardKana(kanaType: configuration.kanaType.appKanaType)
        return FlashcardWidgetEntry(date: Date(), kana: kana, hint: kana.romaji, configuration: configuration)
    }

    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<FlashcardWidgetEntry> {
        let date = Date()
        let kana = WidgetDailyKanaService.shared.getFlashcardKana(kanaType: configuration.kanaType.appKanaType, date: date)

        let entry = FlashcardWidgetEntry(date: date, kana: kana, hint: kana.romaji, configuration: configuration)
        return Timeline(entries: [entry], policy: .after(WidgetTimelineSchedule.nextRefresh(after: date)))
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
        let kana = WidgetDailyKanaService.shared.getDailyCharacter(kanaType: configuration.kanaType.appKanaType)
        return LockScreenWidgetEntry(date: Date(), kana: kana, configuration: configuration)
    }

    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<LockScreenWidgetEntry> {
        let date = Date()
        let kana = WidgetDailyKanaService.shared.getDailyCharacter(kanaType: configuration.kanaType.appKanaType, date: date)

        let entry = LockScreenWidgetEntry(date: date, kana: kana, configuration: configuration)
        return Timeline(entries: [entry], policy: .after(WidgetTimelineSchedule.nextRefresh(after: date)))
    }
}
