import WidgetKit
import SwiftUI

struct LockScreenWidget: Widget {
    var kind: String = "LockScreenWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: ConfigurationAppIntent.self,
            provider: LockScreenProvider()
        ) { entry in
            LockScreenWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Maru Kana")
        .description("Rotating kana reference on your lock screen.")
        .supportedFamilies([.accessoryCircular, .accessoryRectangular])
    }
}

struct LockScreenWidgetView: View {
    @Environment(\.widgetFamily) var widgetFamily
    var entry: LockScreenWidgetEntry

    var body: some View {
        switch widgetFamily {
        case .accessoryCircular:
            accessoryCircularView
        case .accessoryRectangular:
            accessoryRectangularView
        default:
            accessoryCircularView
        }
    }

    var accessoryCircularView: some View {
        ZStack {
            AccessoryWidgetBackground()
            VStack(spacing: 0) {
                Text(entry.kana.character)
                    .font(.system(size: 29, weight: .black, design: .rounded))
                    .widgetAccentable()
                Text(entry.kana.romaji)
                    .font(.system(size: 12, weight: .black, design: .rounded))
            }
        }
    }

    var accessoryRectangularView: some View {
        HStack(spacing: 10) {
            Text(entry.kana.character)
                .font(.system(size: 34, weight: .black, design: .rounded))
                .widgetAccentable()

            VStack(alignment: .leading, spacing: 2) {
                Text(entry.kana.romaji)
                    .font(.system(size: 16, weight: .black, design: .rounded))
                Text(entry.kana.kanaType == .hiragana ? "Hiragana" : "Katakana")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview(as: .accessoryCircular) {
    LockScreenWidget()
} timeline: {
    LockScreenWidgetEntry(
        date: Date(),
        kana: SharedKana(
            id: "hiragana_a",
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

#Preview(as: .accessoryRectangular) {
    LockScreenWidget()
} timeline: {
    LockScreenWidgetEntry(
        date: Date(),
        kana: SharedKana(
            id: "hiragana_a",
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
