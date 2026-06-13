import AVFoundation
import SwiftUI

enum AudioPlaybackSource: Equatable {
    case none
    case nativeKanaAsset
    case speechFallback
}

final class AudioService: NSObject, ObservableObject {
    static let shared = AudioService()

    @Published var isPlaying = false
    private(set) var lastPlaybackSource: AudioPlaybackSource = .none

    private let synthesizer = AVSpeechSynthesizer()
    private var audioPlayer: AVAudioPlayer?

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
        guard UserPreferences.soundEffectsEnabled else {
            stop()
            return
        }

        if let url = KanaAudioAssetResolver.url(for: kana),
           playNativeAudio(at: url) {
            return
        }

        let utterance = AVSpeechUtterance(string: kana.character)
        utterance.voice = AVSpeechSynthesisVoice(language: "ja-JP")
        utterance.rate = 0.4
        utterance.pitchMultiplier = 1.0

        speak(utterance, source: .speechFallback)
    }

    func playWord(_ word: SharedWord) {
        let utterance = AVSpeechUtterance(string: word.word)
        utterance.voice = AVSpeechSynthesisVoice(language: "ja-JP")
        utterance.rate = 0.4

        speak(utterance, source: .speechFallback)
    }

    func playRomaji(_ romaji: String) {
        let utterance = AVSpeechUtterance(string: romaji)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = 0.5

        speak(utterance, source: .speechFallback)
    }

    func stop() {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        if let audioPlayer {
            audioPlayer.stop()
            self.audioPlayer = nil
        }
        lastPlaybackSource = .none
        isPlaying = false
        deactivateAudioSession()
    }

    func applyCurrentPreferences() {
        if !UserPreferences.soundEffectsEnabled {
            stop()
        }
    }

    private func playNativeAudio(at url: URL) -> Bool {
        guard UserPreferences.soundEffectsEnabled else {
            stop()
            return false
        }

        setupAudioSession()

        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        if let audioPlayer {
            audioPlayer.stop()
            self.audioPlayer = nil
        }

        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.delegate = self
            player.prepareToPlay()

            audioPlayer = player
            lastPlaybackSource = .nativeKanaAsset
            isPlaying = true

            if player.play() {
                return true
            }

            self.audioPlayer = nil
            lastPlaybackSource = .none
            isPlaying = false
            deactivateAudioSession()
            return false
        } catch {
            print("Native audio playback error: \(error)")
            return false
        }
    }

    private func speak(_ utterance: AVSpeechUtterance, source: AudioPlaybackSource) {
        guard UserPreferences.soundEffectsEnabled else {
            stop()
            return
        }

        setupAudioSession()

        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        if let audioPlayer {
            audioPlayer.stop()
            self.audioPlayer = nil
        }

        lastPlaybackSource = source
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

extension AudioService: AVSpeechSynthesizerDelegate, AVAudioPlayerDelegate {
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        guard lastPlaybackSource == .speechFallback else {
            return
        }

        lastPlaybackSource = .none
        isPlaying = false
        deactivateAudioSession()
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        guard lastPlaybackSource == .speechFallback else {
            return
        }

        lastPlaybackSource = .none
        isPlaying = false
        deactivateAudioSession()
    }

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        guard lastPlaybackSource == .nativeKanaAsset else {
            return
        }

        audioPlayer = nil
        lastPlaybackSource = .none
        isPlaying = false
        deactivateAudioSession()
    }

    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        guard lastPlaybackSource == .nativeKanaAsset else {
            return
        }

        audioPlayer = nil
        lastPlaybackSource = .none
        isPlaying = false
        deactivateAudioSession()
    }
}
