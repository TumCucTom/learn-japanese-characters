import SwiftUI

// MARK: - WordsView

struct WordsView: View {
    @StateObject private var viewModel = WordsViewModel()

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    hero
                    wordGrid
                }
                .padding(.horizontal, 18)
                .padding(.top, 14)
                .padding(.bottom, 28)
            }
            .background(
                LearningTheme.cream
                    .overlay(LearningPattern().opacity(0.14))
                    .ignoresSafeArea()
            )
            .safeAreaInset(edge: .bottom) {
                Color.clear.frame(height: 84)
            }
            .navigationTitle("Words")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        viewModel.loadWords(includeHaptic: true)
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 16, weight: .black))
                            .foregroundColor(LearningTheme.ink)
                    }
                    .accessibilityLabel("Refresh words")
                }
            }
        }
    }

    private var hero: some View {
        HStack(spacing: 14) {
            MaruMascot(expression: viewModel.mascotExpression, size: 88)

            VStack(alignment: .leading, spacing: 8) {
                Text("Word Cards")
                    .font(.system(size: 26, weight: .black, design: .rounded))
                    .foregroundColor(LearningTheme.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)

                if let featuredWord = viewModel.featuredWord {
                    Text(featuredWord.word)
                        .font(.system(size: 29, weight: .black, design: .rounded))
                        .foregroundColor(LearningTheme.red)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)

                    Text("\(featuredWord.romaji) · \(featuredWord.meaning)")
                        .font(.system(size: 13, weight: .black, design: .rounded))
                        .foregroundColor(LearningTheme.mutedInk)
                        .lineLimit(2)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(14)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: LearningTheme.cardRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: LearningTheme.cardRadius, style: .continuous)
                .stroke(LearningTheme.line, lineWidth: LearningTheme.heavyLine)
        )
    }

    private var wordGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
            ForEach(viewModel.words) { word in
                Button {
                    viewModel.playWord(word)
                } label: {
                    VStack(alignment: .leading, spacing: 7) {
                        HStack(alignment: .top) {
                            Text(word.word)
                                .font(.system(size: 25, weight: .black, design: .rounded))
                                .foregroundColor(LearningTheme.ink)
                                .lineLimit(1)
                                .minimumScaleFactor(0.55)

                            Spacer()

                            Image(systemName: "speaker.wave.2.fill")
                                .font(.system(size: 13, weight: .black))
                                .foregroundColor(LearningTheme.red)
                        }

                        Text(word.romaji)
                            .font(.system(size: 13, weight: .black, design: .rounded))
                            .foregroundColor(LearningTheme.red)
                            .lineLimit(1)
                            .minimumScaleFactor(0.65)

                        Text(word.meaning)
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundColor(LearningTheme.mutedInk)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)

                        Spacer(minLength: 0)
                    }
                    .frame(maxWidth: .infinity, minHeight: 116, alignment: .topLeading)
                    .padding(12)
                }
                .buttonStyle(LearningOutlinedButtonStyle(fill: word.id.hashValue.isMultiple(of: 2) ? .white : LearningTheme.yellowSoft))
            }
        }
    }
}

// MARK: - Preview

#Preview("WordsView") {
    WordsView()
}
