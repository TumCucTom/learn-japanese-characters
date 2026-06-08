import Foundation
import SwiftUI

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var mascotExpression: MascotExpression = .happy
    @Published var currentWord: SharedWord?
    @Published var wordCloud: [SharedWord] = []
    @Published var currentDateJapanese: String = ""
    @Published var currentTimeJapanese: String = ""

    private let repository = KanaRepository.shared
    private let audioService = AudioService.shared

    init() {
        loadWordCloud()
        updateDateTime()
    }

    func loadWordCloud() {
        wordCloud = repository.getRandomWords(limit: 12)
        currentWord = wordCloud.randomElement()
    }

    func updateDateTime() {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年MM月dd日"
        currentDateJapanese = formatter.string(from: Date())

        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"
        currentTimeJapanese = timeFormatter.string(from: Date())
    }

    func playWord(_ word: SharedWord) {
        audioService.playWord(word)
    }

    func setExpression(_ expression: MascotExpression) {
        withAnimation(.easeInOut(duration: 0.3)) {
            mascotExpression = expression
        }
    }

    func refreshWordCloud() {
        loadWordCloud()
        setExpression(.happy)
    }
}
