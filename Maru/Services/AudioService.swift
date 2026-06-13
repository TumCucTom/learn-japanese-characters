import AVFoundation
import SwiftUI

final class AudioService: NSObject, ObservableObject {
    static let shared = AudioService()

    @Published var isPlaying = false

    private let synthesizer = AVSpeechSynthesizer()

    private override init() {
        super.init()
        synthesizer.delegate = self
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
        deactivateAudioSession()
    }

    func applyCurrentPreferences() {
        if !UserPreferences.soundEffectsEnabled {
            stop()
        }
    }

    private func speak(_ utterance: AVSpeechUtterance) {
        guard UserPreferences.soundEffectsEnabled else {
            stop()
            return
        }

        setupAudioSession()

        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }

        isPlaying = true
        synthesizer.speak(utterance)
    }

    private func deactivateAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        } catch {
            print("Audio session deactivate error: \(error)")
        }
    }
}

extension AudioService: AVSpeechSynthesizerDelegate {
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        isPlaying = false
        deactivateAudioSession()
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        isPlaying = false
        deactivateAudioSession()
    }
}
