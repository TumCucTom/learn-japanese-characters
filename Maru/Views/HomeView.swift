import SwiftUI

// MARK: - HomeView

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @State private var showPractice = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // MaruMascot at top
                    MaruMascot(expression: viewModel.mascotExpression, size: 120)
                        .padding(.top, 20)

                    // Japanese date/time display
                    VStack(spacing: 8) {
                        Text(viewModel.currentDateJapanese)
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(Color(hex: "22211F"))

                        Text(viewModel.currentTimeJapanese)
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(Color(hex: "8c867d"))
                    }
                    .padding(.horizontal, 24)

                    // WordCloud with tappable words
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Today's Words")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Color(hex: "22211F"))
                            .padding(.horizontal, 16)

                        WordCloud(words: viewModel.wordCloud) { word in
                            viewModel.playWord(word)
                        }
                    }
                    .padding(.top, 8)

                    // Quick practice button
                    Button(action: {
                        showPractice = true
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "play.fill")
                                .font(.system(size: 16, weight: .semibold))

                            Text("Quick Practice")
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
            .background(Color(hex: "f7f5f1"))
            .navigationTitle("Maru")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        viewModel.refreshWordCloud()
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(Color(hex: "8B5CF6"))
                    }
                }
            }
            .navigationDestination(isPresented: $showPractice) {
                PracticeView()
            }
        }
    }
}

// MARK: - Previews

#Preview("HomeView") {
    HomeView()
}