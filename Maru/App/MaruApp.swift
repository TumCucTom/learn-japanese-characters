import SwiftUI

@main
struct MaruApp: App {
    init() {
        // Load kana and words data on first launch
        KanaRepository.shared.loadKanaData()
        KanaRepository.shared.loadWordsData()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
