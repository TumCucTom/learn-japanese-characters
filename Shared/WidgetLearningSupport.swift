import Foundation

enum WidgetTimelineSchedule {
    static let refreshInterval: TimeInterval = 4 * 60 * 60

    static func nextRefresh(after date: Date) -> Date {
        date.addingTimeInterval(refreshInterval)
    }
}

enum WidgetKanaSelector {
    static func filter(_ kana: [SharedKana], for type: AppConstants.KanaType) -> [SharedKana] {
        kana
            .filter { $0.kanaType == type }
            .sorted { $0.id < $1.id }
    }

    static func select(
        from kana: [SharedKana],
        type: AppConstants.KanaType,
        date: Date = Date(),
        salt: String
    ) -> SharedKana? {
        let typedKana = filter(kana, for: type)
        guard !typedKana.isEmpty else { return nil }

        let slot = Int(date.timeIntervalSince1970 / WidgetTimelineSchedule.refreshInterval)
        let saltValue = salt.unicodeScalars.reduce(0) { partial, scalar in
            partial &+ Int(scalar.value)
        }
        let rawIndex = (slot &+ saltValue) % typedKana.count
        let index = rawIndex >= 0 ? rawIndex : rawIndex + typedKana.count
        return typedKana[index]
    }
}
