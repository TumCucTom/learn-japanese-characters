import AVFoundation
import SwiftUI

final class AudioService: NSObject, ObservableObject {
    static let shared = AudioService()

    @Published var isPlaying = false

    private let synthesizer = AVSpeechSynthesizer()

    private override init() {
        super.init()
        synthesizer.delegate = self
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
        let utterance = AVSpeechUtterance(string: kana.character)
        utterance.voice = AVSpeechSynthesisVoice(language: "ja-JP")
        utterance.rate = 0.4
        utterance.pitchMultiplier = 1.0

        speak(utterance)
    }

    func playWord(_ word: SharedWord) {
        let utterance = AVSpeechUtterance(string: word.word)
        utterance.voice = AVSpeechSynthesisVoice(language: "ja-JP")
        utterance.rate = 0.4

        speak(utterance)
    }

    func playRomaji(_ romaji: String) {
        let utterance = AVSpeechUtterance(string: romaji)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = 0.5

        speak(utterance)
    }

    func stop() {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        isPlaying = false
    }

    private func speak(_ utterance: AVSpeechUtterance) {
        setupAudioSession()

        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }

        isPlaying = true
        synthesizer.speak(utterance)
    }
}

extension AudioService: AVSpeechSynthesizerDelegate {
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        isPlaying = false
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        isPlaying = false
    }
}
