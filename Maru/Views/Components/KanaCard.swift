import SwiftUI

// MARK: - KanaCard

struct KanaCard: View {
    let kana: SharedKana
    var fill: Color = LearningTheme.card
    var isLocked: Bool = false
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                Text(kana.character)
                    .font(.system(size: 33, weight: .black, design: .rounded))
                    .foregroundColor(isLocked ? LearningTheme.softInk.opacity(0.35) : LearningTheme.ink)

                Text(kana.romaji)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(isLocked ? LearningTheme.softInk.opacity(0.35) : LearningTheme.mutedInk)
            }
            .frame(width: 58, height: 70)
            .opacity(isLocked ? 0.65 : 1)
        }
        .buttonStyle(LearningOutlinedButtonStyle(fill: isLocked ? LearningTheme.locked.opacity(0.7) : fill))
        .disabled(isLocked)
    }
}

// MARK: - LargeKanaCard

struct LargeKanaCard: View {
    let kana: SharedKana
    let masteryLevel: AppConstants.MasteryLevel
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 10) {
                Text(kana.character)
                    .font(.system(size: 88, weight: .black, design: .rounded))
                    .foregroundColor(LearningTheme.ink)

                Text(kana.romaji)
                    .font(.system(size: 22, weight: .black, design: .rounded))
                    .foregroundColor(LearningTheme.mutedInk)
            }
            .frame(width: 170, height: 205)
            .overlay(alignment: .topTrailing) {
                Circle()
                    .fill(backgroundColor)
                    .overlay(Circle().stroke(LearningTheme.line, lineWidth: 2))
                    .frame(width: 22, height: 22)
                    .padding(10)
            }
        }
        .buttonStyle(LearningOutlinedButtonStyle(fill: LearningTheme.card))
    }

    private var backgroundColor: Color {
        switch masteryLevel {
        case .new:
            return LearningTheme.locked
        case .learning:
            return LearningTheme.yellow
        case .familiar:
            return LearningTheme.redSoft
        case .mastered:
            return LearningTheme.green
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

    VStack {
        KanaCard(kana: sampleKana) {}
        LargeKanaCard(kana: sampleKana, masteryLevel: .learning) {}
    }
    .padding()
    .background(LearningTheme.cream)
}
