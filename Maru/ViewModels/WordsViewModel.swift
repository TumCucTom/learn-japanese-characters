import Foundation
import SwiftUI

@MainActor
final class WordsViewModel: ObservableObject {
    @Published var words: [SharedWord] = []
    @Published var featuredWord: SharedWord?
    @Published var mascotExpression: MascotExpression = .happy

    private let repository = KanaRepository.shared
    private let audioService = AudioService.shared
    private let hapticService = HapticService.shared

    init() {
        loadWords()
    }

    func loadWords(includeHaptic: Bool = false) {
        if includeHaptic {
            hapticService.selection()
        }
        words = repository.getRandomWords(limit: 40)
        featuredWord = words.first
    }

    func playWord(_ word: SharedWord) {
        hapticService.impact(.light)
        featuredWord = word
        withAnimation(.easeInOut(duration: 0.2)) {
            mascotExpression = .thinking
        }
        audioService.playWord(word)

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) { [weak self] in
            withAnimation(.easeInOut(duration: 0.2)) {
                self?.mascotExpression = .happy
            }
        }
    }
}
