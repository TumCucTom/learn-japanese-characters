import Foundation

enum KanaLearningPath {
    enum RowStatus: Equatable {
        case locked
        case unlocked
        case learning
        case mastered
    }

    struct Row: Identifiable, Equatable {
        let id: String
        let romajiPrefix: String
        let kana: [SharedKana]
    }

    private static let orderedRowPrefixes = [
        "a", "ka", "sa", "ta", "na",
        "ha", "ma", "ya", "ra", "wa"
    ]

    private static let rowLookup: [String: String] = [
        "a": "a", "i": "a", "u": "a", "e": "a", "o": "a",
        "ka": "ka", "ki": "ka", "ku": "ka", "ke": "ka", "ko": "ka",
        "sa": "sa", "shi": "sa", "su": "sa", "se": "sa", "so": "sa",
        "ta": "ta", "chi": "ta", "tsu": "ta", "te": "ta", "to": "ta",
        "na": "na", "ni": "na", "nu": "na", "ne": "na", "no": "na",
        "ha": "ha", "hi": "ha", "fu": "ha", "he": "ha", "ho": "ha",
        "ma": "ma", "mi": "ma", "mu": "ma", "me": "ma", "mo": "ma",
        "ya": "ya", "yu": "ya", "yo": "ya",
        "ra": "ra", "ri": "ra", "ru": "ra", "re": "ra", "ro": "ra",
        "wa": "wa", "wo": "wa", "n": "wa"
    ]

    static func rows(for kana: [SharedKana], type: AppConstants.KanaType) -> [Row] {
        let basicKana = kana.filter { $0.kanaType == type && $0.category == "basic" }
        let grouped = Dictionary(grouping: basicKana) { rowLookup[$0.romaji] ?? $0.romaji }

        return orderedRowPrefixes.compactMap { prefix in
            guard let rowKana = grouped[prefix], !rowKana.isEmpty else { return nil }
            return Row(
                id: "\(type.rawValue)-\(prefix)",
                romajiPrefix: prefix,
                kana: rowKana.sorted { kanaOrder($0) < kanaOrder($1) }
            )
        }
    }

    static func status(for rows: [Row], progressMap: [String: SharedProgress]) -> [String: RowStatus] {
        var statuses: [String: RowStatus] = [:]
        var previousRowAllowsUnlock = true

        for row in rows {
            if !previousRowAllowsUnlock {
                statuses[row.id] = .locked
                continue
            }

            statuses[row.id] = statusForUnlockedRow(row, progressMap: progressMap)
            previousRowAllowsUnlock = row.kana.allSatisfy { kana in
                guard let progress = progressMap[kana.id] else { return false }
                return progress.totalAttempts > 0
            }
        }

        return statuses
    }

    static func practicedFraction(for row: Row, progressMap: [String: SharedProgress]) -> Double {
        guard !row.kana.isEmpty else { return 0 }
        let practicedCount = row.kana.filter { kana in
            guard let progress = progressMap[kana.id] else { return false }
            return progress.totalAttempts > 0
        }.count
        return Double(practicedCount) / Double(row.kana.count)
    }

    private static func statusForUnlockedRow(_ row: Row, progressMap: [String: SharedProgress]) -> RowStatus {
        let rowProgress = row.kana.compactMap { progressMap[$0.id] }

        guard !rowProgress.isEmpty else { return .unlocked }

        if rowProgress.count == row.kana.count,
           rowProgress.allSatisfy({ $0.masteryLevel == .mastered }) {
            return .mastered
        }

        if rowProgress.contains(where: { $0.totalAttempts > 0 }) {
            return .learning
        }

        return .unlocked
    }

    private static func kanaOrder(_ kana: SharedKana) -> Int {
        if let number = kana.id.split(separator: "_").last.flatMap({ Int($0) }) {
            return number
        }

        return orderedRowPrefixes.firstIndex(of: rowLookup[kana.romaji] ?? kana.romaji) ?? Int.max
    }
}
