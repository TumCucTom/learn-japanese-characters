import WidgetKit
import SwiftUI

struct DailyKanaWidget: Widget {
    var kind: String = "DailyKanaWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: ConfigurationAppIntent.self,
            provider: DailyKanaProvider()
        ) { entry in
            DailyKanaWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Daily Kana")
        .description("Learn a new kana character every day.")
        .supportedFamilies([.systemSmall])
    }
}

struct DailyKanaWidgetView: View {
    var entry: KanaWidgetEntry

    var body: some View {
        VStack(spacing: 4) {
            Text(entry.kana.character)
                .font(.system(size: 56, weight: .bold, design: .serif))
                .foregroundStyle(.primary)

            Text(entry.kana.romaji)
                .font(.system(size: 20, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview(as: .systemSmall) {
    DailyKanaWidget()
} timeline: {
    KanaWidgetEntry(
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