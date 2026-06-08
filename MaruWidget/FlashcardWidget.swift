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
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Kana Flashcard")
        .description("Practice your kana with a daily flashcard.")
        .supportedFamilies([.systemMedium])
    }
}

struct FlashcardWidgetView: View {
    var entry: FlashcardWidgetEntry

    var body: some View {
        HStack(spacing: 20) {
            // Character side
            VStack {
                Text(entry.kana.character)
                    .font(.system(size: 72, weight: .bold, design: .serif))
                    .foregroundStyle(.primary)

                Text(entry.kana.kanaType == .hiragana ? "Hiragana" : "Katakana")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)

            // Divider
            Rectangle()
                .fill(.tertiary)
                .frame(width: 1)

            // Hint/Romaji side
            VStack {
                Text("What is this?")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(entry.hint)
                    .font(.system(size: 28, weight: .semibold, design: .rounded))
                    .foregroundStyle(.primary)
            }
            .frame(maxWidth: .infinity)
        }
        .padding()
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