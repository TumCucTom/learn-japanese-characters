import SwiftUI

// MARK: - PracticeView

struct PracticeView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = PracticeViewModel()
    @State private var selectedKanaType: AppConstants.KanaType? = .hiragana
    @State private var selectedExerciseType: PracticeViewModel.ExerciseType?
    @State private var focusOnWeak = false
    @State private var hasStarted = false
    private let initialKana: [SharedKana]?
    private let initialExerciseType: PracticeViewModel.ExerciseType?
    private let hidesTabBar: Bool

    init(
        initialKana: [SharedKana]? = nil,
        initialExerciseType: PracticeViewModel.ExerciseType? = nil,
        hidesTabBar: Bool = false
    ) {
        self.initialKana = initialKana
        self.initialExerciseType = initialExerciseType
        self.hidesTabBar = hidesTabBar
        _hasStarted = State(initialValue: initialKana != nil)
        _selectedKanaType = State(initialValue: initialKana?.first?.kanaType ?? .hiragana)
    }

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isSessionComplete {
                    SessionCompleteView(
                        viewModel: viewModel,
                        doneTitle: shouldDismissRoute ? "Done" : "Back to Practice",
                        onRestart: {
                            viewModel.restartSession()
                            hasStarted = true
                        },
                        onDone: closePractice
                    )
                } else if hasStarted {
                    PracticeContentView(viewModel: viewModel, onClose: closePractice)
                } else {
                    StartPracticeView(
                        selectedKanaType: $selectedKanaType,
                        selectedExerciseType: $selectedExerciseType,
                        focusOnWeak: $focusOnWeak,
                        onStart: {
                            HapticService.shared.selection()
                            viewModel.startPracticeSession(kanaType: selectedKanaType, focusOnWeak: focusOnWeak, exerciseType: selectedExerciseType)
                            hasStarted = true
                        }
                    )
                }
            }
            .background(LearningTheme.cream.ignoresSafeArea())
            .navigationTitle("Drill")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(shouldHideTabBar ? .hidden : .visible, for: .tabBar)
            .onAppear {
                guard let initialKana, viewModel.practiceSession.isEmpty else { return }
                viewModel.startPracticeSession(kana: initialKana, exerciseType: initialExerciseType)
            }
        }
    }

    private var shouldHideTabBar: Bool {
        hidesTabBar || (hasStarted && !viewModel.isSessionComplete)
    }

    private var shouldDismissRoute: Bool {
        hidesTabBar || initialKana != nil
    }

    private func closePractice() {
        HapticService.shared.selection()
        if shouldDismissRoute {
            dismiss()
        } else {
            viewModel.resetSession()
            hasStarted = false
        }
    }
}

// MARK: - StartPracticeView

struct StartPracticeView: View {
    @Binding var selectedKanaType: AppConstants.KanaType?
    @Binding var selectedExerciseType: PracticeViewModel.ExerciseType?
    @Binding var focusOnWeak: Bool
    let onStart: () -> Void

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 18) {
                MaruMascot(expression: .happy, size: 112)
                    .padding(.top, 8)

                VStack(spacing: 8) {
                    Text("Practice")
                        .font(.system(size: 34, weight: .black, design: .rounded))
                        .foregroundColor(LearningTheme.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)

                    HStack(spacing: 8) {
                        LearningBadge(text: "Listening", color: LearningTheme.red)
                        LearningBadge(text: "Trace", color: LearningTheme.yellow)
                            .foregroundStyle(LearningTheme.ink)
                    }
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("Kana Set")
                        .font(.system(size: 15, weight: .black, design: .rounded))
                        .foregroundColor(LearningTheme.mutedInk)

                    HStack(spacing: 10) {
                        TypeButton(title: "All", isSelected: selectedKanaType == nil) {
                            HapticService.shared.selection()
                            selectedKanaType = nil
                        }
                        TypeButton(title: "Hiragana", isSelected: selectedKanaType == .hiragana) {
                            HapticService.shared.selection()
                            selectedKanaType = .hiragana
                        }
                        TypeButton(title: "Katakana", isSelected: selectedKanaType == .katakana) {
                            HapticService.shared.selection()
                            selectedKanaType = .katakana
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .leading, spacing: 10) {
                    Text("Exercise")
                        .font(.system(size: 15, weight: .black, design: .rounded))
                        .foregroundColor(LearningTheme.mutedInk)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                        ModeButton(
                            title: "Mix",
                            icon: "shuffle",
                            isSelected: selectedExerciseType == nil
                        ) {
                            HapticService.shared.selection()
                            selectedExerciseType = nil
                        }

                        ForEach(PracticeViewModel.ExerciseType.allCases, id: \.self) { mode in
                            ModeButton(
                                title: mode.rawValue,
                                icon: iconName(for: mode),
                                isSelected: selectedExerciseType == mode
                            ) {
                                HapticService.shared.selection()
                                selectedExerciseType = mode
                            }
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
                .onChange(of: focusOnWeak) { _, _ in
                    HapticService.shared.selection()
                }
                .padding(14)
                .background(.white)
                .clipShape(RoundedRectangle(cornerRadius: LearningTheme.cardRadius, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: LearningTheme.cardRadius, style: .continuous)
                        .stroke(LearningTheme.line, lineWidth: LearningTheme.heavyLine)
                )

                Button(action: onStart) {
                    Text("Start Learning")
                        .font(.system(size: 22, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                }
                .buttonStyle(LearningOutlinedButtonStyle(fill: LearningTheme.red, pressedFill: LearningTheme.redDark))
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 32)
        }
        .safeAreaInset(edge: .bottom) {
            Color.clear.frame(height: 84)
        }
    }

    private func iconName(for mode: PracticeViewModel.ExerciseType) -> String {
        switch mode {
        case .multipleChoice:
            return "checklist"
        case .listening:
            return "speaker.wave.2.fill"
        case .reading:
            return "textformat"
        case .spelling:
            return "keyboard"
        case .writing:
            return "hand.draw"
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

private struct ModeButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .black))

                Text(title)
                    .font(.system(size: 14, weight: .black, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
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
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ObservedObject var viewModel: PracticeViewModel
    let onClose: () -> Void
    @State private var speakerPulseID = 0

    var body: some View {
        VStack(spacing: 14) {
            progressHeader

            MaruMascot(expression: viewModel.mascotExpression, size: 72)
                .scaleEffect(!reduceMotion && viewModel.mascotExpression == .celebrating ? 1.08 : 1)
                .rotationEffect(.degrees(!reduceMotion && viewModel.mascotExpression == .sad ? -3 : 0))
                .pulseOnChange(viewModel.answerFeedback?.id ?? 0, scale: 1.04)
                .animation(LearningMotion.animation(reduceMotion: reduceMotion, spring: LearningMotion.feedbackSpring), value: viewModel.mascotExpression)

            if let kana = viewModel.currentKana {
                promptCard(for: kana)
                    .id(kana.id)
                    .transition(.scale(scale: reduceMotion ? 1 : 0.97).combined(with: .opacity))
            }

            if viewModel.exerciseType == .spelling {
                typingPanel
            } else if viewModel.exerciseType == .writing {
                writingPanel
            } else {
                choiceGrid
            }

            if viewModel.selectedAnswer != nil {
                feedbackText
                    .transition(.scale(scale: 0.92).combined(with: .opacity))

                nextButton
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            Spacer(minLength: 10)
        }
        .padding(.horizontal, 18)
        .padding(.top, 88)
        .padding(.bottom, 96)
        .background(
            LearningTheme.cream
                .overlay(LearningPattern().opacity(0.14))
                .ignoresSafeArea()
        )
        .animation(LearningMotion.animation(reduceMotion: reduceMotion, spring: LearningMotion.quickSpring), value: viewModel.answerFeedbackID)
        .animation(LearningMotion.animation(reduceMotion: reduceMotion, spring: LearningMotion.gentleSpring), value: viewModel.currentKana?.id)
    }

    private var progressHeader: some View {
        VStack(spacing: 10) {
            HStack {
                Button {
                    onClose()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 18, weight: .black))
                        .foregroundColor(LearningTheme.ink)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Close practice")

                GeometryReader { proxy in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(LearningTheme.locked)
                        Capsule()
                            .fill(LearningTheme.red)
                            .frame(width: proxy.size.width * progressFraction)
                            .animation(LearningMotion.animation(reduceMotion: reduceMotion, spring: LearningMotion.gentleSpring), value: progressFraction)
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
                Text("Question \(viewModel.currentIndex + 1)/\(viewModel.practiceSession.count)")
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
                    .font(.system(size: 24, weight: .black, design: .rounded))
                    .foregroundColor(LearningTheme.ink)

                Button {
                    speakerPulseID += 1
                    viewModel.playCurrentKana()
                } label: {
                    Image(systemName: "speaker.wave.2.fill")
                        .font(.system(size: 46, weight: .black))
                        .foregroundColor(LearningTheme.ink)
                        .frame(width: 118, height: 92)
                        .pulseOnChange(speakerPulseID, scale: 1.08)
                }
                .buttonStyle(LearningOutlinedButtonStyle(fill: LearningTheme.yellow))
            case .spelling:
                Text(kana.character)
                    .font(.system(size: 92, weight: .black, design: .rounded))
                    .foregroundColor(LearningTheme.ink)

                Text("Type the sound")
                    .font(.system(size: 18, weight: .black, design: .rounded))
                    .foregroundColor(LearningTheme.mutedInk)
            case .writing:
                Text(kana.character)
                    .font(.system(size: 92, weight: .black, design: .rounded))
                    .foregroundColor(LearningTheme.ink)

                Text("Trace practice")
                    .font(.system(size: 18, weight: .black, design: .rounded))
                    .foregroundColor(LearningTheme.mutedInk)
            case .reading:
                Text(kana.romaji)
                    .font(.system(size: 84, weight: .black, design: .rounded))
                    .foregroundColor(LearningTheme.ink)

                Text("Choose the kana")
                    .font(.system(size: 18, weight: .black, design: .rounded))
                    .foregroundColor(LearningTheme.mutedInk)
            case .multipleChoice:
                Text(kana.character)
                    .font(.system(size: 96, weight: .black, design: .rounded))
                    .foregroundColor(LearningTheme.ink)

                Button {
                    speakerPulseID += 1
                    viewModel.playCurrentKana()
                } label: {
                    Image(systemName: "speaker.wave.2.fill")
                        .font(.system(size: 22, weight: .black))
                        .foregroundColor(LearningTheme.ink)
                        .frame(width: 62, height: 48)
                        .pulseOnChange(speakerPulseID, scale: 1.08)
                }
                .buttonStyle(LearningOutlinedButtonStyle(fill: LearningTheme.yellow))
            }
        }
        .frame(maxWidth: .infinity, minHeight: 184)
        .padding(.vertical, 16)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: LearningTheme.cardRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: LearningTheme.cardRadius, style: .continuous)
                .stroke(LearningTheme.line, lineWidth: LearningTheme.heavyLine)
        )
    }

    private var choiceGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            ForEach(viewModel.choices) { choice in
                ChoiceTile(
                    choice: choice,
                    selectedAnswer: viewModel.selectedAnswer,
                    correctAnswer: viewModel.currentKana?.romaji,
                    answerFeedback: viewModel.answerFeedback
                ) {
                    viewModel.selectAnswer(choice.answer)
                }
            }
        }
        .animation(LearningMotion.animation(reduceMotion: reduceMotion, spring: LearningMotion.quickSpring), value: viewModel.answerFeedbackID)
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
                Text("Check answer")
                    .font(.system(size: 19, weight: .black, design: .rounded))
                    .foregroundColor(LearningTheme.ink)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(LearningOutlinedButtonStyle(fill: LearningTheme.yellow))
            .disabled(viewModel.selectedAnswer != nil || viewModel.typedAnswer.isEmpty)

        }
    }

    private var writingPanel: some View {
        VStack(spacing: 14) {
            if let kana = viewModel.currentKana {
                KanaTracePad(kana: kana)
            }

            Button {
                viewModel.completeWritingPractice()
            } label: {
                Text(viewModel.selectedAnswer == nil ? "Mark traced" : "Traced")
                    .font(.system(size: 19, weight: .black, design: .rounded))
                    .foregroundColor(LearningTheme.ink)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(LearningOutlinedButtonStyle(fill: LearningTheme.yellow))
            .disabled(viewModel.selectedAnswer != nil)
            .scaleEffect(viewModel.selectedAnswer != nil ? 0.98 : 1)
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
        return Double(viewModel.currentIndex + 1) / Double(viewModel.practiceSession.count)
    }

    @ViewBuilder
    private var feedbackText: some View {
        if let kana = viewModel.currentKana, let selectedAnswer = viewModel.selectedAnswer {
            Text(selectedAnswer == kana.romaji ? "Correct" : "Answer: \(kana.character) = \(kana.romaji)")
                .font(.system(size: 17, weight: .black, design: .rounded))
                .foregroundColor(selectedAnswer == kana.romaji ? LearningTheme.green : LearningTheme.red)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                .id(viewModel.answerFeedbackID)
        }
    }
}

// MARK: - ChoiceTile

private struct ChoiceTile: View {
    let choice: PracticeViewModel.PracticeChoice
    let selectedAnswer: String?
    let correctAnswer: String?
    let answerFeedback: PracticeViewModel.AnswerFeedback?
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
        .pulseOnChange(answerFeedback?.id ?? 0, scale: shouldPopCorrect ? 1.05 : 1)
        .shakeOnChange(answerFeedback?.id ?? 0, isActive: isSelectedWrong)
    }

    private var isSelectedWrong: Bool {
        answerFeedback?.selectedAnswer == choice.answer && answerFeedback?.isCorrect == false
    }

    private var shouldPopCorrect: Bool {
        answerFeedback?.correctAnswer == choice.answer && answerFeedback?.isCorrect == true
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

// MARK: - KanaTracePad

private struct KanaTracePad: View {
    let kana: SharedKana
    @State private var strokes: [[CGPoint]] = []
    @State private var currentStroke: [CGPoint] = []
    @State private var hasStartedCurrentStroke = false

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: LearningTheme.cardRadius, style: .continuous)
                .fill(.white)
                .overlay(
                    RoundedRectangle(cornerRadius: LearningTheme.cardRadius, style: .continuous)
                        .stroke(LearningTheme.line, lineWidth: LearningTheme.heavyLine)
                )

            Text(kana.character)
                .font(.system(size: 138, weight: .black, design: .rounded))
                .foregroundColor(LearningTheme.locked.opacity(0.65))

            TraceGuide()
                .stroke(LearningTheme.locked, style: StrokeStyle(lineWidth: 2, dash: [8, 8]))
                .padding(16)

            Canvas { context, _ in
                var path = Path()
                for stroke in strokes {
                    append(stroke: stroke, to: &path)
                }
                append(stroke: currentStroke, to: &path)
                context.stroke(path, with: .color(LearningTheme.red), style: StrokeStyle(lineWidth: 9, lineCap: .round, lineJoin: .round))
            }
            .clipShape(RoundedRectangle(cornerRadius: LearningTheme.cardRadius, style: .continuous))

            VStack {
                HStack {
                    Text("Trace here")
                        .font(.system(size: 13, weight: .black, design: .rounded))
                        .foregroundColor(LearningTheme.mutedInk)
                    Spacer()
                    Button {
                        HapticService.shared.selection()
                        strokes.removeAll()
                        currentStroke.removeAll()
                        hasStartedCurrentStroke = false
                    } label: {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 15, weight: .black))
                            .foregroundColor(LearningTheme.ink)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Clear tracing")
                }
                Spacer()
            }
            .padding(16)
        }
        .frame(height: 188)
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    if !hasStartedCurrentStroke {
                        HapticService.shared.traceStrokeStarted()
                        hasStartedCurrentStroke = true
                    }
                    currentStroke.append(value.location)
                }
                .onEnded { _ in
                    if !currentStroke.isEmpty {
                        strokes.append(currentStroke)
                        HapticService.shared.traceStrokeCompleted()
                    }
                    currentStroke.removeAll()
                    hasStartedCurrentStroke = false
                }
        )
    }

    private func append(stroke: [CGPoint], to path: inout Path) {
        guard let first = stroke.first else { return }
        path.move(to: first)
        for point in stroke.dropFirst() {
            path.addLine(to: point)
        }
    }
}

private struct TraceGuide: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.move(to: CGPoint(x: rect.minX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        return path
    }
}

// MARK: - SessionCompleteView

struct SessionCompleteView: View {
    @ObservedObject var viewModel: PracticeViewModel
    let doneTitle: String
    let onRestart: () -> Void
    let onDone: () -> Void

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

            VStack(spacing: 12) {
                Button {
                    HapticService.shared.selection()
                    onRestart()
                } label: {
                    Text("Practice Again")
                        .font(.system(size: 22, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 17)
                }
                .buttonStyle(LearningOutlinedButtonStyle(fill: LearningTheme.red, pressedFill: LearningTheme.redDark))

                Button {
                    onDone()
                } label: {
                    Text(doneTitle)
                        .font(.system(size: 20, weight: .black, design: .rounded))
                        .foregroundColor(LearningTheme.ink)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                }
                .buttonStyle(LearningOutlinedButtonStyle(fill: .white, pressedFill: LearningTheme.yellowSoft))
            }
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
        .clipShape(RoundedRectangle(cornerRadius: LearningTheme.cardRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: LearningTheme.cardRadius, style: .continuous)
                .stroke(LearningTheme.line, lineWidth: LearningTheme.heavyLine)
        )
    }
}

// MARK: - Previews

#Preview("PracticeView") {
    PracticeView()
}
