import SwiftUI

// MARK: - HomeView

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @State private var showPractice = false

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    hero
                    progressSection
                    practiceButton
                    wordSection
                }
                .padding(.horizontal, 18)
                .padding(.top, 12)
                .padding(.bottom, 28)
            }
            .background(
                LearningTheme.cream
                    .overlay(LearningPattern().opacity(0.16))
                    .ignoresSafeArea()
            )
            .safeAreaInset(edge: .bottom) {
                Color.clear.frame(height: 84)
            }
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(isPresented: $showPractice) {
                PracticeView(hidesTabBar: true)
            }
            .onAppear {
                viewModel.loadLearningProgress()
            }
        }
    }

    private var hero: some View {
        HStack(alignment: .center, spacing: 14) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text("Learn Kana")
                        .font(.system(size: 31, weight: .black, design: .rounded))
                        .foregroundColor(LearningTheme.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)

                    LearningBadge(text: "Daily", color: LearningTheme.red)
                }

                DailyDateRow(
                    dateText: viewModel.currentDateJapanese,
                    timeText: viewModel.currentTimeJapanese
                )
            }

            Spacer(minLength: 4)

            MaruMascot(expression: viewModel.mascotExpression, size: 92)
                .accessibilityHidden(true)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: LearningTheme.cardRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: LearningTheme.cardRadius, style: .continuous)
                .stroke(LearningTheme.line, lineWidth: LearningTheme.heavyLine)
        )
    }

    private var progressSection: some View {
        VStack(spacing: 10) {
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
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Tap a word")
                    .font(.system(size: 20, weight: .black, design: .rounded))
                    .foregroundColor(LearningTheme.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)

                Spacer()

                Button(action: viewModel.refreshWordCloud) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 17, weight: .black))
                        .foregroundColor(LearningTheme.red)
                        .frame(width: 36, height: 32)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Refresh words")
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
                        .frame(maxWidth: .infinity, minHeight: 62)
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
            HapticService.shared.selection()
            showPractice = true
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "play.fill")
                    .font(.system(size: 18, weight: .black))

                Text("Start Drill")
                    .font(.system(size: 20, weight: .black, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
        }
        .buttonStyle(LearningOutlinedButtonStyle(fill: LearningTheme.red, pressedFill: LearningTheme.redDark))
    }
}

// MARK: - Supporting Views

private struct DailyDateRow: View {
    let dateText: String
    let timeText: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "sun.max.fill")
                .font(.system(size: 12, weight: .black))
                .foregroundColor(LearningTheme.yellow)

            Text(dateText)
                .font(.system(size: 13, weight: .black, design: .rounded))
                .foregroundColor(LearningTheme.mutedInk)
                .lineLimit(1)
                .minimumScaleFactor(0.75)

            Text(timeText)
                .font(.system(size: 15, weight: .black, design: .rounded))
                .foregroundColor(LearningTheme.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
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
                    .font(.system(size: 17, weight: .black, design: .rounded))
                    .foregroundColor(LearningTheme.ink)
                    .lineLimit(1)

                Spacer()

                Text("\(Int(value * 100))%")
                    .font(.system(size: 14, weight: .black, design: .rounded))
                    .foregroundColor(LearningTheme.red)
                    .lineLimit(1)
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
            .frame(height: 8)
            .overlay(Capsule().stroke(LearningTheme.line, lineWidth: 1.5))

            if let row {
                HStack(spacing: 6) {
                    Text("Next")
                        .font(.system(size: 11, weight: .black, design: .rounded))
                        .foregroundColor(LearningTheme.mutedInk)
                        .lineLimit(1)

                    ForEach(row.kana.prefix(5)) { kana in
                        Text(kana.character)
                            .font(.system(size: 17, weight: .black, design: .rounded))
                            .foregroundColor(LearningTheme.ink)
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)
                    }

                    Spacer()
                }
            }
        }
        .padding(12)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: LearningTheme.cardRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: LearningTheme.cardRadius, style: .continuous)
                .stroke(LearningTheme.line, lineWidth: LearningTheme.heavyLine)
        )
    }
}

// MARK: - Previews

#Preview("HomeView") {
    HomeView()
}
