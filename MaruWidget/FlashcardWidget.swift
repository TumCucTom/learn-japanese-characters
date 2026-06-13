import WidgetKit
import SwiftUI

struct FlashcardWidget: Widget {
    var kind: String = "FlashcardWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: ConfigurationAppIntent.self,
            provider: FlashcardProvider()
        ) { entry in
            FlashcardWidgetView(entry: entry)
                .containerBackground(for: .widget) {
                    WidgetStyle.cream
                }
        }
        .configurationDisplayName("Kana Flashcard")
        .description("Practice your kana with a daily flashcard.")
        .supportedFamilies([.systemMedium])
    }
}

struct FlashcardWidgetView: View {
    var entry: FlashcardWidgetEntry

    var body: some View {
        HStack(spacing: 14) {
            VStack(spacing: 6) {
                Text(entry.kana.character)
                    .font(.system(size: 74, weight: .black, design: .rounded))
                    .foregroundStyle(WidgetStyle.ink)

                Text(entry.kana.kanaType == .hiragana ? "Hiragana" : "Katakana")
                    .font(.system(size: 12, weight: .black, design: .rounded))
                    .foregroundStyle(WidgetStyle.red)
            }
            .frame(width: 128)
            .frame(maxHeight: .infinity)
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(WidgetStyle.ink, lineWidth: 3)
            )

            VStack(alignment: .leading, spacing: 10) {
                Text("Today")
                    .font(.system(size: 14, weight: .black, design: .rounded))
                    .foregroundStyle(WidgetStyle.ink.opacity(0.68))

                Text(entry.hint)
                    .font(.system(size: 38, weight: .black, design: .rounded))
                    .foregroundStyle(WidgetStyle.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.65)

                Text("Say it once. Spot it later.")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(WidgetStyle.ink.opacity(0.72))
                    .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: 0)

                Capsule()
                    .fill(WidgetStyle.red)
                    .frame(width: 70, height: 10)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview(as: .systemMedium) {
    FlashcardWidget()
} timeline: {
    FlashcardWidgetEntry(
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
        hint: "a",
        configuration: ConfigurationAppIntent()
    )
}
