import WidgetKit
import SwiftUI

enum WidgetStyle {
    static let cream = Color(red: 1.0, green: 0.992, blue: 0.973)
    static let ink = Color(red: 0.09, green: 0.08, blue: 0.08)
    static let red = Color(red: 0.94, green: 0.19, blue: 0.22)
    static let yellow = Color(red: 1.0, green: 0.79, blue: 0.04)
    static let softRed = Color(red: 1.0, green: 0.88, blue: 0.89)
}

struct DailyKanaWidget: Widget {
    var kind: String = "DailyKanaWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: ConfigurationAppIntent.self,
            provider: DailyKanaProvider()
        ) { entry in
            DailyKanaWidgetView(entry: entry)
                .containerBackground(for: .widget) {
                    WidgetStyle.cream
                }
        }
        .configurationDisplayName("Daily Kana")
        .description("Learn a new kana character every day.")
        .supportedFamilies([.systemSmall])
    }
}

struct DailyKanaWidgetView: View {
    var entry: KanaWidgetEntry

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(WidgetStyle.ink, lineWidth: 3)
                    )

                Text(entry.kana.character)
                    .font(.system(size: 54, weight: .black, design: .rounded))
                    .foregroundStyle(WidgetStyle.ink)
            }
            .frame(height: 92)

            HStack(spacing: 6) {
                Text(entry.kana.romaji)
                    .font(.system(size: 20, weight: .black, design: .rounded))
                    .foregroundStyle(WidgetStyle.ink)

                Circle()
                    .fill(WidgetStyle.red)
                    .frame(width: 9, height: 9)
            }
        }
        .padding(10)
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
