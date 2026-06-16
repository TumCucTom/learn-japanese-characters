import Foundation

enum KanaAudioAssetResolver {
    static let fileExtension = "mp3"
    static let speechFallbackRomaji: Set<String> = [
        "d",
        "vu"
    ]

    private static let sourceAliases: [String: String] = [
        "sha": "sya",
        "shu": "syu",
        "sho": "syo",
        "cha": "cya",
        "chu": "cyu",
        "cho": "cyo",
        "ja": "zya",
        "ju": "zyu",
        "jo": "zyo"
    ]

    static func assetName(for kana: SharedKana) -> String? {
        if let audioFileName = kana.audioFileName?.trimmingCharacters(in: .whitespacesAndNewlines),
           !audioFileName.isEmpty {
            return audioFileName.replacingOccurrences(of: ".\(fileExtension)", with: "")
        }

        let normalizedRomaji = kana.romaji
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

        guard !speechFallbackRomaji.contains(normalizedRomaji) else {
            return nil
        }

        let sourceRomaji = sourceAliases[normalizedRomaji] ?? normalizedRomaji
        return "kana_native_\(sourceRomaji)"
    }

    static func url(for kana: SharedKana, in bundle: Bundle = .main) -> URL? {
        guard let assetName = assetName(for: kana) else {
            return nil
        }

        return bundle.url(forResource: assetName, withExtension: fileExtension)
    }
}
