import SwiftUI

// MARK: - PracticeView

struct PracticeView: View {
    @StateObject private var viewModel = PracticeViewModel()
    @State private var selectedKanaType: AppConstants.KanaType? = nil
    @State private var focusOnWeak = false
    @State private var hasStarted = false

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isSessionComplete {
                    SessionCompleteView(viewModel: viewModel) {
                        hasStarted = false
                        viewModel.restartSession()
                    }
                } else if hasStarted {
                    PracticeContentView(viewModel: viewModel)
                } else {
                    StartPracticeView(
                        selectedKanaType: $selectedKanaType,
                        focusOnWeak: $focusOnWeak,
                        onStart: {
                            viewModel.startPracticeSession(
                                kanaType: selectedKanaType,
                                focusOnWeak: focusOnWeak
                            )
                            hasStarted = true
                        }
                    )
                }
            }
            .navigationTitle("Practice")
            .navigationBarTitleDisplayMode(.inline)
            .background(Color(hex: "f7f5f1"))
        }
    }
}

// MARK: - StartPracticeView

struct StartPracticeView: View {
    @Binding var selectedKanaType: AppConstants.KanaType?
    @Binding var focusOnWeak: Bool
    let onStart: () -> Void

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Type picker
            VStack(alignment: .leading, spacing: 12) {
                Text("Kana Type")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color(hex: "5b554d"))

                HStack(spacing: 12) {
                    TypeButton(
                        title: "All",
                        isSelected: selectedKanaType == nil
                    ) {
                        selectedKanaType = nil
                    }

                    TypeButton(
                        title: "Hiragana",
                        isSelected: selectedKanaType == .hiragana
                    ) {
                        selectedKanaType = .hiragana
                    }

                    TypeButton(
                        title: "Katakana",
                        isSelected: selectedKanaType == .katakana
                    ) {
                        selectedKanaType = .katakana
                    }
                }
            }
            .padding(.horizontal, 16)

            // Weak spots toggle
            VStack(alignment: .leading, spacing: 12) {
                Text("Practice Mode")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color(hex: "5b554d"))

                Toggle(isOn: $focusOnWeak) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Focus on Weak Spots")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Color(hex: "22211F"))

                        Text("Prioritize kana you find difficult")
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(Color(hex: "8c867d"))
                    }
                }
                .toggleStyle(SwitchToggleStyle(tint: Color(hex: "8B5CF6")))
                .padding(16)
                .background(Color(hex: "faf8f4"))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(hex: "e4ded4"), lineWidth: 1)
                )
            }
            .padding(.horizontal, 16)

            Spacer()

            // Start button
            Button(action: onStart) {
                Text("Start Practice")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(Color(hex: "8B5CF6"))
                    .cornerRadius(16)
                    .shadow(color: Color(hex: "8B5CF6").opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 32)
        }
    }
}

// MARK: - TypeButton

private struct TypeButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(isSelected ? .white : Color(hex: "5b554d"))
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(isSelected ? Color(hex: "8B5CF6") : Color(hex: "faf8f4"))
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(isSelected ? Color.clear : Color(hex: "e4ded4"), lineWidth: 1)
                )
        }
    }
}

// MARK: - PracticeContentView

struct PracticeContentView: View {
    @ObservedObject var viewModel: PracticeViewModel

    var body: some View {
        VStack(spacing: 24) {
            // Progress indicator
            HStack {
                Text("Question \(viewModel.currentIndex + 1)")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color(hex: "8c867d"))

                Spacer()

                Text("Score: \(viewModel.score)")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color(hex: "8B5CF6"))
            }
            .padding(.horizontal, 16)

            Spacer()

            // Kana display
            if let kana = viewModel.currentKana {
                VStack(spacing: 16) {
                    Text(kana.character)
                        .font(.system(size: 96, weight: .medium, design: .serif))
                        .foregroundColor(Color(hex: "22211F"))

                    // Play button
                    Button(action: {
                        viewModel.playCurrentKana()
                    }) {
                        Image(systemName: "speaker.wave.2.fill")
                            .font(.system(size: 24))
                            .foregroundColor(Color(hex: "8B5CF6"))
                            .frame(width: 60, height: 60)
                            .background(Color(hex: "e8dff5"))
                            .clipShape(Circle())
                    }
                }
            }

            Spacer()

            // Multiple choice options
            VStack(spacing: 12) {
                ForEach(viewModel.options, id: \.self) { option in
                    OptionButton(
                        option: option,
                        isSelected: viewModel.selectedAnswer == option,
                        isCorrect: option == viewModel.currentKana?.romaji,
                        showResult: viewModel.selectedAnswer != nil
                    ) {
                        viewModel.selectAnswer(option)
                    }
                }
            }
            .padding(.horizontal, 16)

            // Next button (appears after answering)
            if viewModel.selectedAnswer != nil {
                Button(action: {
                    viewModel.nextQuestion()
                }) {
                    Text("Next")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color(hex: "FF7A1A"))
                        .cornerRadius(12)
                }
                .padding(.horizontal, 16)
            }

            Spacer()
        }
        .padding(.top, 16)
    }
}

// MARK: - OptionButton

private struct OptionButton: View {
    let option: String
    let isSelected: Bool
    let isCorrect: Bool
    let showResult: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Text(option)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(textColor)

                Spacer()

                if showResult {
                    Image(systemName: resultIcon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(resultColor)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(backgroundColor)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(borderColor, lineWidth: isSelected || (showResult && isCorrect) ? 2 : 1)
            )
        }
        .disabled(showResult)
    }

    private var textColor: Color {
        if showResult {
            return isCorrect ? Color(hex: "34D399") : (isSelected ? Color(hex: "ef4444") : Color(hex: "22211F"))
        }
        return Color(hex: "22211F")
    }

    private var backgroundColor: Color {
        if showResult {
            if isCorrect {
                return Color(hex: "f2f7ef")
            } else if isSelected {
                return Color(hex: "fef2f2")
            }
        }
        return Color(hex: "faf8f4")
    }

    private var borderColor: Color {
        if showResult {
            if isCorrect {
                return Color(hex: "34D399")
            } else if isSelected {
                return Color(hex: "ef4444")
            }
        }
        return Color(hex: "e4ded4")
    }

    private var resultIcon: String {
        isCorrect ? "checkmark.circle.fill" : (isSelected ? "xmark.circle.fill" : "")
    }

    private var resultColor: Color {
        isCorrect ? Color(hex: "34D399") : Color(hex: "ef4444")
    }
}

// MARK: - SessionCompleteView

struct SessionCompleteView: View {
    @ObservedObject var viewModel: PracticeViewModel
    let onRestart: () -> Void

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Celebration mascot
            MaruMascot(expression: .celebrating, size: 120)

            // Score display
            VStack(spacing: 16) {
                Text("Session Complete!")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(Color(hex: "22211F"))

                Text("\(viewModel.score)/\(viewModel.totalQuestions)")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(Color(hex: "8B5CF6"))

                // Accuracy ring
                let accuracy = viewModel.totalQuestions > 0
                    ? Double(viewModel.score) / Double(viewModel.totalQuestions)
                    : 0

                ProgressRing(progress: accuracy, size: 100)
            }

            // Stats
            HStack(spacing: 32) {
                StatItem(title: "Correct", value: "\(viewModel.score)", color: Color(hex: "34D399"))
                StatItem(title: "Mistakes", value: "\(viewModel.mistakeCount)", color: Color(hex: "ef4444"))
            }

            Spacer()

            // Restart button
            Button(action: onRestart) {
                HStack(spacing: 12) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 16, weight: .semibold))

                    Text("Practice Again")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color(hex: "8B5CF6"))
                .cornerRadius(16)
                .shadow(color: Color(hex: "8B5CF6").opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 32)
        }
    }
}

// MARK: - StatItem

private struct StatItem: View {
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Text(value)
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(color)

            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color(hex: "8c867d"))
        }
    }
}

// MARK: - Previews

#Preview("StartPracticeView") {
    StartPracticeView(
        selectedKanaType: .constant(.hiragana),
        focusOnWeak: .constant(false),
        onStart: {}
    )
}

#Preview("PracticeView") {
    PracticeView()
}