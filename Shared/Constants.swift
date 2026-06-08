import Foundation

enum AppConstants {
    static let appGroupIdentifier = "group.com.maru.shared"
    static let databaseName = "maru.sqlite3"

    enum KanaType: String, Codable, CaseIterable {
        case hiragana
        case katakana
    }

    enum MasteryLevel: Int, Codable {
        case new = 0
        case learning = 1
        case familiar = 2
        case mastered = 3
    }
}
