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
                .padding(.top, 18)
                .padding(.bottom, 128)
            }
            .background(
                LearningTheme.cream
                    .overlay(LearningPattern().opacity(0.25))
                    .ignoresSafeArea()
            )
            .navigationTitle("Words")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: viewModel.loadWords) {
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
        HStack(spacing: 16) {
            MaruMascot(expression: viewModel.mascotExpression, size: 106)

            VStack(alignment: .leading, spacing: 8) {
                Text("Word Cards")
                    .font(.system(size: 30, weight: .black, design: .rounded))
                    .foregroundColor(LearningTheme.ink)

                if let featuredWord = viewModel.featuredWord {
                    Text(featuredWord.word)
                        .font(.system(size: 34, weight: .black, design: .rounded))
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
        .padding(16)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(LearningTheme.line, lineWidth: LearningTheme.heavyLine)
        )
    }

    private var wordGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            ForEach(viewModel.words) { word in
                Button {
                    viewModel.playWord(word)
                } label: {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(alignment: .top) {
                            Text(word.word)
                                .font(.system(size: 28, weight: .black, design: .rounded))
                                .foregroundColor(LearningTheme.ink)
                                .lineLimit(1)
                                .minimumScaleFactor(0.55)

                            Spacer()

                            Image(systemName: "speaker.wave.2.fill")
                                .font(.system(size: 13, weight: .black))
                                .foregroundColor(LearningTheme.red)
                        }

                        Text(word.romaji)
                            .font(.system(size: 14, weight: .black, design: .rounded))
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
                    .frame(maxWidth: .infinity, minHeight: 128, alignment: .topLeading)
                    .padding(14)
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
