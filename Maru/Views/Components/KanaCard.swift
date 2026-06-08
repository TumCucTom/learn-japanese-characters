import SwiftUI

// MARK: - KanaCard

struct KanaCard: View {
    let kana: SharedKana
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                Text(kana.character)
                    .font(.system(size: 48, weight: .medium, design: .serif))
                    .foregroundColor(Color(hex: "22211F"))

                Text(kana.romaji)
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(Color(hex: "5b554d"))
            }
            .frame(width: 80, height: 100)
            .background(Color(hex: "faf8f4"))
            .cornerRadius(16)
            .shadow(color: Color(hex: "22211f").opacity(0.04), radius: 4, x: 0, y: 2)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color(hex: "e4ded4"), lineWidth: 1)
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - LargeKanaCard

struct LargeKanaCard: View {
    let kana: SharedKana
    let masteryLevel: AppConstants.MasteryLevel
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            ZStack {
                // Background with mastery level color
                RoundedRectangle(cornerRadius: 20)
                    .fill(backgroundColor)
                    .shadow(color: Color(hex: "22211f").opacity(0.06), radius: 6, x: 0, y: 3)

                VStack(spacing: 12) {
                    Text(kana.character)
                        .font(.system(size: 72, weight: .medium, design: .serif))
                        .foregroundColor(Color(hex: "22211F"))

                    Text(kana.romaji)
                        .font(.system(size: 20, weight: .regular))
                        .foregroundColor(Color(hex: "5b554d"))
                }
                .padding(24)
            }
            .frame(width: 160, height: 200)
        }
        .buttonStyle(ScaleButtonStyle())
    }

    private var backgroundColor: Color {
        switch masteryLevel {
        case .new:
            return Color(hex: "f7f5f1")
        case .learning:
            return Color(hex: "e8dff5") // purple tint
        case .familiar:
            return Color(hex: "fff3e8") // orange tint
        case .mastered:
            return Color(hex: "f2f7ef") // success background
        }
    }
}

// MARK: - ScaleButtonStyle

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Previews

#Preview("KanaCard") {
    let sampleKana = SharedKana(
        id: "a",
        character: "あ",
        romaji: "a",
        kanaType: .hiragana,
        category: "basic"
    )

    KanaCard(kana: sampleKana) {
        print("Tapped!")
    }
    .padding()
}

#Preview("LargeKanaCard") {
    let sampleKana = SharedKana(
        id: "a",
        character: "あ",
        romaji: "a",
        kanaType: .hiragana,
        category: "basic"
    )

    VStack(spacing: 20) {
        ForEach([AppConstants.MasteryLevel.new, .learning, .familiar, .mastered], id: \.self) { level in
            LargeKanaCard(
                kana: sampleKana,
                masteryLevel: level
            ) {
                print("Tapped!")
            }
        }
    }
    .padding()
}
