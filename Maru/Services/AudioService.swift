import AVFoundation
import SwiftUI

final class AudioService: ObservableObject {
    static let shared = AudioService()

    @Published var isPlaying = false

    private var audioPlayer: AVAudioPlayer?

    private init() {
        setupAudioSession()
    }

    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Audio session setup error: \(error)")
        }
    }

    func playKana(_ kana: SharedKana) {
        // For now, use text-to-speech as placeholder
        // In production, would play actual audio files
        let utterance = AVSpeechUtterance(string: kana.character)
        utterance.voice = AVSpeechSynthesisVoice(language: "ja-JP")
        utterance.rate = 0.4
        utterance.pitchMultiplier = 1.0

        let synthesizer = AVSpeechSynthesizer()
        synthesizer.speak(utterance)
    }

    func playWord(_ word: SharedWord) {
        let utterance = AVSpeechUtterance(string: word.word)
        utterance.voice = AVSpeechSynthesisVoice(language: "ja-JP")
        utterance.rate = 0.4

        let synthesizer = AVSpeechSynthesizer()
        synthesizer.speak(utterance)
    }

    func playRomaji(_ romaji: String) {
        let utterance = AVSpeechUtterance(string: romaji)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = 0.5

        let synthesizer = AVSpeechSynthesizer()
        synthesizer.speak(utterance)
    }
}