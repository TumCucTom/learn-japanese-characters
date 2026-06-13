import SwiftUI

// MARK: - PracticeView

struct PracticeView: View {
    @StateObject private var viewModel = PracticeViewModel()
    @State private var selectedKanaType: AppConstants.KanaType? = .hiragana
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
            .background(LearningTheme.cream.ignoresSafeArea())
            .navigationTitle("Drill")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - StartPracticeView

struct StartPracticeView: View {
    @Binding var selectedKanaType: AppConstants.KanaType?
    @Binding var focusOnWeak: Bool
    let onStart: () -> Void

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 26) {
                MaruMascot(expression: .happy, size: 150)
                    .padding(.top, 24)

                VStack(spacing: 8) {
                    Text("Practice")
                        .font(.system(size: 42, weight: .black, design: .rounded))
                        .foregroundColor(LearningTheme.ink)

                    HStack(spacing: 8) {
                        LearningBadge(text: "Listening", color: LearningTheme.red)
                        LearningBadge(text: "Typing", color: LearningTheme.yellow)
                            .foregroundStyle(LearningTheme.ink)
                    }
                }

                VStack(alignment: .leading, spacing: 14) {
                    Text("Kana Set")
                        .font(.system(size: 15, weight: .black, design: .rounded))
                        .foregroundColor(LearningTheme.mutedInk)

                    HStack(spacing: 10) {
                        TypeButton(title: "All", isSelected: selectedKanaType == nil) {
                            selectedKanaType = nil
                        }
                        TypeButton(title: "Hiragana", isSelected: selectedKanaType == .hiragana) {
                            selectedKanaType = .hiragana
                        }
                        TypeButton(title: "Katakana", isSelected: selectedKanaType == .katakana) {
                            selectedKanaType = .katakana
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Toggle(isOn: $focusOnWeak) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Weak spots")
                            .font(.system(size: 18, weight: .black, design: .rounded))
                            .foregroundColor(LearningTheme.ink)

                        Text("Mix in the kana that need more reps")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundColor(LearningTheme.mutedInk)
                    }
                }
                .toggleStyle(SwitchToggleStyle(tint: LearningTheme.red))
                .padding(16)
                .background(.white)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(LearningTheme.line, lineWidth: LearningTheme.heavyLine)
                )

                Button(action: onStart) {
                    Text("Start Learning")
                        .font(.system(size: 24, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                }
                .buttonStyle(LearningOutlinedButtonStyle(fill: LearningTheme.red, pressedFill: LearningTheme.redDark))
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 128)
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
                .font(.system(size: 14, weight: .black, design: .rounded))
                .foregroundColor(isSelected ? .white : LearningTheme.ink)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
        }
        .buttonStyle(
            LearningOutlinedButtonStyle(
                fill: isSelected ? LearningTheme.red : .white,
                pressedFill: isSelected ? LearningTheme.redDark : LearningTheme.yellowSoft
            )
        )
    }
}

// MARK: - PracticeContentView

struct PracticeContentView: View {
    @ObservedObject var viewModel: PracticeViewModel

    var body: some View {
        VStack(spacing: 16) {
            progressHeader

            MaruMascot(expression: viewModel.mascotExpression, size: 86)
                .padding(.top, 4)

            if let kana = viewModel.currentKana {
                promptCard(for: kana)
            }

            if viewModel.exerciseType == .spelling {
                typingPanel
            } else {
                choiceGrid
            }

            if viewModel.selectedAnswer != nil {
                nextButton
            }

            Spacer(minLength: 10)
        }
        .padding(.horizontal, 18)
        .padding(.top, 12)
        .padding(.bottom, 96)
        .background(
            LearningTheme.cream
                .overlay(LearningPattern().opacity(0.25))
                .ignoresSafeArea()
        )
    }

    private var progressHeader: some View {
        VStack(spacing: 10) {
            HStack {
                Button {
                    viewModel.restartSession()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 18, weight: .black))
                        .foregroundColor(LearningTheme.ink)
                }

                GeometryReader { proxy in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(LearningTheme.locked)
                        Capsule()
                            .fill(LearningTheme.red)
                            .frame(width: proxy.size.width * progressFraction)
                    }
                }
                .frame(height: 9)
                .overlay(Capsule().stroke(LearningTheme.line, lineWidth: 1.5))

                Text("\(viewModel.score)")
                    .font(.system(size: 18, weight: .black, design: .rounded))
                    .foregroundColor(LearningTheme.red)
                    .frame(width: 28)
            }

            HStack {
                LearningBadge(text: viewModel.exerciseType.rawValue, color: viewModel.exerciseType == .listening ? LearningTheme.yellow : LearningTheme.red)
                Spacer()
                Text("Question \(viewModel.currentIndex + 1)")
                    .font(.system(size: 13, weight: .black, design: .rounded))
                    .foregroundColor(LearningTheme.mutedInk)
            }
        }
    }

    private func promptCard(for kana: SharedKana) -> some View {
        VStack(spacing: 16) {
            switch viewModel.exerciseType {
            case .listening:
                Text("Listen")
                    .font(.system(size: 26, weight: .black, design: .rounded))
                    .foregroundColor(LearningTheme.ink)

                Button {
                    viewModel.playCurrentKana()
                } label: {
                    Image(systemName: "speaker.wave.2.fill")
                        .font(.system(size: 46, weight: .black))
                        .foregroundColor(LearningTheme.ink)
                        .frame(width: 118, height: 92)
                }
                .buttonStyle(LearningOutlinedButtonStyle(fill: LearningTheme.yellow))
            case .spelling:
                Text(kana.character)
                    .font(.system(size: 102, weight: .black, design: .rounded))
                    .foregroundColor(LearningTheme.ink)

                Text("Type the sound")
                    .font(.system(size: 18, weight: .black, design: .rounded))
                    .foregroundColor(LearningTheme.mutedInk)
            case .reading:
                Text(kana.romaji)
                    .font(.system(size: 96, weight: .black, design: .rounded))
                    .foregroundColor(LearningTheme.ink)

                Text("Choose the kana")
                    .font(.system(size: 18, weight: .black, design: .rounded))
                    .foregroundColor(LearningTheme.mutedInk)
            case .multipleChoice:
                Text(kana.character)
                    .font(.system(size: 112, weight: .black, design: .rounded))
                    .foregroundColor(LearningTheme.ink)

                Button {
                    viewModel.playCurrentKana()
                } label: {
                    Image(systemName: "speaker.wave.2.fill")
                        .font(.system(size: 22, weight: .black))
                        .foregroundColor(LearningTheme.ink)
                        .frame(width: 62, height: 48)
                }
                .buttonStyle(LearningOutlinedButtonStyle(fill: LearningTheme.yellow))
            }
        }
        .frame(maxWidth: .infinity, minHeight: 220)
        .padding(.vertical, 20)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(LearningTheme.line, lineWidth: LearningTheme.heavyLine)
        )
    }

    private var choiceGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            ForEach(viewModel.choices) { choice in
                ChoiceTile(
                    choice: choice,
                    selectedAnswer: viewModel.selectedAnswer,
                    correctAnswer: viewModel.currentKana?.romaji
                ) {
                    viewModel.selectAnswer(choice.answer)
                }
            }
        }
    }

    private var typingPanel: some View {
        VStack(spacing: 14) {
            TextField("romaji", text: $viewModel.typedAnswer)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .font(.system(size: 28, weight: .black, design: .rounded))
                .foregroundColor(LearningTheme.ink)
                .multilineTextAlignment(.center)
                .padding(.vertical, 16)
                .background(.white)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(LearningTheme.line, lineWidth: LearningTheme.heavyLine)
                )
                .disabled(viewModel.selectedAnswer != nil)

            Button {
                viewModel.submitTypedAnswer()
            } label: {
                Text("Check answers")
                    .font(.system(size: 19, weight: .black, design: .rounded))
                    .foregroundColor(LearningTheme.ink)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(LearningOutlinedButtonStyle(fill: LearningTheme.yellow))
            .disabled(viewModel.selectedAnswer != nil || viewModel.typedAnswer.isEmpty)

            if let selectedAnswer = viewModel.selectedAnswer,
               let correctAnswer = viewModel.currentKana?.romaji {
                Text(selectedAnswer == correctAnswer ? "Correct" : "Answer: \(correctAnswer)")
                    .font(.system(size: 18, weight: .black, design: .rounded))
                    .foregroundColor(selectedAnswer == correctAnswer ? LearningTheme.green : LearningTheme.red)
            }
        }
    }

    private var nextButton: some View {
        Button {
            viewModel.nextQuestion()
        } label: {
            Text(viewModel.currentIndex + 1 >= viewModel.practiceSession.count ? "Finish" : "Continue")
                .font(.system(size: 21, weight: .black, design: .rounded))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
        }
        .buttonStyle(LearningOutlinedButtonStyle(fill: LearningTheme.red, pressedFill: LearningTheme.redDark))
    }

    private var progressFraction: Double {
        guard !viewModel.practiceSession.isEmpty else { return 0 }
        return Double(viewModel.currentIndex) / Double(viewModel.practiceSession.count)
    }
}

// MARK: - ChoiceTile

private struct ChoiceTile: View {
    let choice: PracticeViewModel.PracticeChoice
    let selectedAnswer: String?
    let correctAnswer: String?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 5) {
                Text(choice.label)
                    .font(.system(size: choice.label.count > 3 ? 34 : 44, weight: .black, design: .rounded))
                    .foregroundColor(LearningTheme.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.55)

                if let sublabel = choice.sublabel {
                    Text(sublabel)
                        .font(.system(size: 13, weight: .black, design: .rounded))
                        .foregroundColor(LearningTheme.mutedInk)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 104)
            .overlay(alignment: .topTrailing) {
                if let iconName {
                    Image(systemName: iconName)
                        .font(.system(size: 17, weight: .black))
                        .foregroundColor(iconColor)
                        .padding(8)
                }
            }
        }
        .buttonStyle(LearningOutlinedButtonStyle(fill: fillColor))
        .disabled(selectedAnswer != nil)
    }

    private var fillColor: Color {
        guard let selectedAnswer, let correctAnswer else {
            return .white
        }

        if choice.answer == correctAnswer {
            return LearningTheme.greenSoft
        }

        if choice.answer == selectedAnswer {
            return LearningTheme.redSoft
        }

        return .white
    }

    private var iconName: String? {
        guard let selectedAnswer, let correctAnswer else { return nil }
        if choice.answer == correctAnswer { return "checkmark.circle.fill" }
        if choice.answer == selectedAnswer { return "xmark.circle.fill" }
        return nil
    }

    private var iconColor: Color {
        iconName == "checkmark.circle.fill" ? LearningTheme.green : LearningTheme.red
    }
}

// MARK: - SessionCompleteView

struct SessionCompleteView: View {
    @ObservedObject var viewModel: PracticeViewModel
    let onRestart: () -> Void

    var body: some View {
        VStack(spacing: 28) {
            Spacer()

            MaruMascot(expression: accuracy >= 0.7 ? .celebrating : .happy, size: 150)

            VStack(spacing: 12) {
                Text("Nice Drill")
                    .font(.system(size: 38, weight: .black, design: .rounded))
                    .foregroundColor(LearningTheme.ink)

                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("\(viewModel.score)")
                        .font(.system(size: 66, weight: .black, design: .rounded))
                        .foregroundColor(LearningTheme.red)
                    Text("/\(viewModel.totalQuestions)")
                        .font(.system(size: 28, weight: .black, design: .rounded))
                        .foregroundColor(LearningTheme.mutedInk)
                }

                ProgressRing(progress: accuracy, size: 112)
            }

            HStack(spacing: 22) {
                StatItem(title: "Correct", value: "\(viewModel.score)", color: LearningTheme.green)
                StatItem(title: "Mistakes", value: "\(viewModel.mistakeCount)", color: LearningTheme.red)
            }

            Spacer()

            Button(action: onRestart) {
                Text("Practice Again")
                    .font(.system(size: 22, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 17)
            }
            .buttonStyle(LearningOutlinedButtonStyle(fill: LearningTheme.red, pressedFill: LearningTheme.redDark))
        }
        .padding(.horizontal, 18)
        .padding(.bottom, 128)
        .background(LearningTheme.cream.ignoresSafeArea())
    }

    private var accuracy: Double {
        viewModel.totalQuestions > 0 ? Double(viewModel.score) / Double(viewModel.totalQuestions) : 0
    }
}

// MARK: - StatItem

private struct StatItem: View {
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Text(value)
                .font(.system(size: 30, weight: .black, design: .rounded))
                .foregroundColor(color)

            Text(title)
                .font(.system(size: 12, weight: .black, design: .rounded))
                .foregroundColor(LearningTheme.mutedInk)
        }
        .frame(width: 112, height: 92)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(LearningTheme.line, lineWidth: LearningTheme.heavyLine)
        )
    }
}

// MARK: - Previews

#Preview("PracticeView") {
    PracticeView()
}
