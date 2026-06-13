import SwiftUI

// MARK: - HomeView

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @State private var showPractice = false

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    hero
                    progressSection
                    Color.clear.frame(height: 32)
                    wordSection
                    practiceButton
                }
                .padding(.horizontal, 18)
                .padding(.top, 18)
                .padding(.bottom, 128)
            }
            .background(
                LearningTheme.cream
                    .overlay(LearningPattern().opacity(0.38))
                    .ignoresSafeArea()
            )
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: viewModel.refreshWordCloud) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 16, weight: .black))
                            .foregroundColor(LearningTheme.ink)
                            .frame(width: 38, height: 38)
                            .background(.white)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(LearningTheme.line, lineWidth: 2))
                    }
                    .accessibilityLabel("Refresh words")
                }
            }
            .navigationDestination(isPresented: $showPractice) {
                PracticeView()
            }
            .onAppear {
                viewModel.loadLearningProgress()
            }
        }
    }

    private var hero: some View {
        VStack(spacing: 16) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("Learn Kana")
                    .font(.system(size: 36, weight: .black, design: .rounded))
                    .foregroundColor(LearningTheme.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                LearningBadge(text: "Daily", color: LearningTheme.red)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            TimeLearningPanel(
                dateText: viewModel.currentDateJapanese,
                timeText: viewModel.currentTimeJapanese
            )

            ZStack {
                FloatingLabel(text: "あした", subtitle: "tomorrow", rotation: -9)
                    .offset(x: -118, y: -38)
                FloatingLabel(text: "おかね", subtitle: "money", rotation: 8, fill: LearningTheme.greenSoft)
                    .offset(x: 116, y: -22)
                FloatingLabel(text: "ベスト", subtitle: "best", rotation: 10)
                    .offset(x: 116, y: 54)
                FloatingLabel(text: "いち", subtitle: "one", rotation: -6, fill: LearningTheme.yellowSoft)
                    .offset(x: -100, y: 88)

                MaruMascot(expression: viewModel.mascotExpression, size: 188)
                    .padding(.top, 18)
                    .accessibilityHidden(true)
            }
            .frame(height: 232)
        }
    }

    private var progressSection: some View {
        VStack(spacing: 12) {
            LearningProgressStrip(
                title: "Hiragana",
                value: viewModel.hiraganaProgress,
                row: viewModel.nextHiraganaRow
            )

            LearningProgressStrip(
                title: "Katakana",
                value: viewModel.katakanaProgress,
                row: viewModel.nextKatakanaRow
            )
        }
    }

    private var wordSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Tap a word")
                    .font(.system(size: 22, weight: .black, design: .rounded))
                    .foregroundColor(LearningTheme.ink)

                Spacer()

                Image(systemName: "speaker.wave.2.fill")
                    .font(.system(size: 18, weight: .black))
                    .foregroundColor(LearningTheme.red)
            }

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 96), spacing: 10)], spacing: 10) {
                ForEach(viewModel.wordCloud.prefix(9)) { word in
                    Button {
                        viewModel.playWord(word)
                    } label: {
                        VStack(spacing: 4) {
                            Text(word.word)
                                .font(.system(size: 22, weight: .black, design: .rounded))
                                .foregroundColor(LearningTheme.ink)
                                .lineLimit(1)
                                .minimumScaleFactor(0.65)

                            Text(word.meaning)
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .foregroundColor(LearningTheme.mutedInk)
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                        }
                        .frame(maxWidth: .infinity, minHeight: 70)
                        .padding(.horizontal, 8)
                    }
                    .buttonStyle(LearningOutlinedButtonStyle(fill: word.id.hashValue.isMultiple(of: 2) ? .white : LearningTheme.yellowSoft))
                }
            }
        }
        .padding(.top, 4)
    }

    private var practiceButton: some View {
        Button {
            showPractice = true
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "play.fill")
                    .font(.system(size: 18, weight: .black))

                Text("Start Drill")
                    .font(.system(size: 22, weight: .black, design: .rounded))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
        }
        .buttonStyle(LearningOutlinedButtonStyle(fill: LearningTheme.red, pressedFill: LearningTheme.redDark))
    }
}

// MARK: - Supporting Views

private struct TimeLearningPanel: View {
    let dateText: String
    let timeText: String

    var body: some View {
        VStack(spacing: 6) {
            Text(dateText)
                .font(.system(size: 18, weight: .black, design: .rounded))
                .foregroundColor(LearningTheme.ink)

            Text(timeText)
                .font(.system(size: 34, weight: .black, design: .rounded))
                .foregroundColor(LearningTheme.ink)

            Text("いま")
                .font(.system(size: 15, weight: .black, design: .rounded))
                .foregroundColor(LearningTheme.mutedInk)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(LearningTheme.line, lineWidth: LearningTheme.heavyLine)
        )
    }
}

private struct LearningProgressStrip: View {
    let title: String
    let value: Double
    let row: KanaLearningPath.Row?

    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Text(title)
                    .font(.system(size: 18, weight: .black, design: .rounded))
                    .foregroundColor(LearningTheme.ink)

                Spacer()

                Text("\(Int(value * 100))%")
                    .font(.system(size: 15, weight: .black, design: .rounded))
                    .foregroundColor(LearningTheme.red)
            }

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(LearningTheme.locked)

                    Capsule()
                        .fill(LearningTheme.red)
                        .frame(width: max(8, proxy.size.width * value))
                }
            }
            .frame(height: 10)
            .overlay(Capsule().stroke(LearningTheme.line, lineWidth: 2))

            if let row {
                HStack(spacing: 8) {
                    Text("Next row")
                        .font(.system(size: 12, weight: .black, design: .rounded))
                        .foregroundColor(LearningTheme.mutedInk)

                    ForEach(row.kana.prefix(5)) { kana in
                        Text(kana.character)
                            .font(.system(size: 18, weight: .black, design: .rounded))
                            .foregroundColor(LearningTheme.ink)
                    }

                    Spacer()
                }
            }
        }
        .padding(16)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(LearningTheme.line, lineWidth: LearningTheme.heavyLine)
        )
    }
}

private struct FloatingLabel: View {
    let text: String
    let subtitle: String
    let rotation: Double
    var fill: Color = .white

    var body: some View {
        VStack(spacing: 1) {
            Text(text)
                .font(.system(size: 21, weight: .black, design: .rounded))
                .foregroundColor(LearningTheme.ink)

            Text(subtitle)
                .font(.system(size: 9, weight: .bold, design: .rounded))
                .foregroundColor(LearningTheme.mutedInk)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(fill)
        .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .stroke(LearningTheme.line, lineWidth: 2.5)
        )
        .rotationEffect(.degrees(rotation))
    }
}

// MARK: - Previews

#Preview("HomeView") {
    HomeView()
}
