import Foundation
import SQLite

final class SharedDatabase {
    static let shared = SharedDatabase()

    private var db: Connection?

    // Tables
    private let kanaTable = Table("kana")
    private let progressTable = Table("progress")
    private let wordsTable = Table("words")
    private let dailySelectionTable = Table("daily_selection")

    // Kana columns
    private let kanaId = Expression<String>("id")
    private let kanaCharacter = Expression<String>("character")
    private let kanaRomaji = Expression<String>("romaji")
    private let kanaType = Expression<String>("kana_type")
    private let kanaCategory = Expression<String>("category")
    private let kanaStrokeOrder = Expression<String>("stroke_order")
    private let kanaAudioFile = Expression<String?>("audio_file")

    // Progress columns
    private let progressKanaId = Expression<String>("kana_id")
    private let mistakeCount = Expression<Int>("mistake_count")
    private let correctCount = Expression<Int>("correct_count")
    private let lastPracticed = Expression<Double?>("last_practiced")
    private let masteryLevel = Expression<Int>("mastery_level")

    // Words columns
    private let wordId = Expression<String>("id")
    private let wordText = Expression<String>("word")
    private let wordRomaji = Expression<String>("romaji")
    private let wordMeaning = Expression<String>("meaning")
    private let wordAudioFile = Expression<String?>("audio_file")

    // Daily selection columns
    private let dailyKanaId = Expression<String>("kana_id")
    private let dailyDate = Expression<Double>("date")
    private let dailyWidgetType = Expression<String>("widget_type")

    private init() {
        setupDatabase()
    }

    private func setupDatabase() {
        guard let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: AppConstants.appGroupIdentifier) else {
            print("Failed to get app group container URL")
            return
        }

        let dbPath = containerURL.appendingPathComponent(AppConstants.databaseName).path

        do {
            db = try Connection(dbPath)
            try createTables()
        } catch {
            print("Database setup error: \(error)")
        }
    }

    private func createTables() throws {
        guard let db = db else { return }

        try db.run(kanaTable.create(ifNotExists: true) { t in
            t.column(kanaId, primaryKey: true)
            t.column(kanaCharacter)
            t.column(kanaRomaji)
            t.column(kanaType)
            t.column(kanaCategory)
            t.column(kanaStrokeOrder)
            t.column(kanaAudioFile)
        })

        try db.run(progressTable.create(ifNotExists: true) { t in
            t.column(progressKanaId, primaryKey: true)
            t.column(mistakeCount)
            t.column(correctCount)
            t.column(lastPracticed)
            t.column(masteryLevel)
        })

        try db.run(wordsTable.create(ifNotExists: true) { t in
            t.column(wordId, primaryKey: true)
            t.column(wordText)
            t.column(wordRomaji)
            t.column(wordMeaning)
            t.column(wordAudioFile)
        })

        try db.run(dailySelectionTable.create(ifNotExists: true) { t in
            t.column(dailyKanaId)
            t.column(dailyDate)
            t.column(dailyWidgetType)
        })
    }

    // MARK: - Kana Operations

    func insertKana(_ kana: SharedKana) throws {
        guard let db = db else { return }

        let strokeOrderJson = try JSONEncoder().encode(kana.strokeOrder)
        let strokeOrderString = String(data: strokeOrderJson, encoding: .utf8) ?? "[]"

        try db.run(kanaTable.insert(or: .replace,
            kanaId <- kana.id,
            kanaCharacter <- kana.character,
            kanaRomaji <- kana.romaji,
            kanaType <- kana.kanaType.rawValue,
            kanaCategory <- kana.category,
            kanaStrokeOrder <- strokeOrderString,
            kanaAudioFile <- kana.audioFileName
        ))
    }

    func getAllKana() throws -> [SharedKana] {
        guard let db = db else { return [] }

        var kanas: [SharedKana] = []

        for row in try db.prepare(kanaTable) {
            let strokeOrderString = row[kanaStrokeOrder]
            let strokeOrderData = strokeOrderString.data(using: .utf8) ?? Data()
            let strokeOrder = (try? JSONDecoder().decode([String].self, from: strokeOrderData)) ?? []

            let kana = SharedKana(
                id: row[kanaId],
                character: row[kanaCharacter],
                romaji: row[kanaRomaji],
                kanaType: AppConstants.KanaType(rawValue: row[kanaType]) ?? .hiragana,
                category: row[kanaCategory],
                strokeOrder: strokeOrder,
                audioFileName: row[kanaAudioFile]
            )
            kanas.append(kana)
        }

        return kanas
    }

    func getKana(byId id: String) throws -> SharedKana? {
        guard let db = db else { return nil }

        let query = kanaTable.filter(kanaId == id)

        guard let row = try db.pluck(query) else { return nil }

        let strokeOrderString = row[kanaStrokeOrder]
        let strokeOrderData = strokeOrderString.data(using: .utf8) ?? Data()
        let strokeOrder = (try? JSONDecoder().decode([String].self, from: strokeOrderData)) ?? []

        return SharedKana(
            id: row[kanaId],
            character: row[kanaCharacter],
            romaji: row[kanaRomaji],
            kanaType: AppConstants.KanaType(rawValue: row[kanaType]) ?? .hiragana,
            category: row[kanaCategory],
            strokeOrder: strokeOrder,
            audioFileName: row[kanaAudioFile]
        )
    }

    // MARK: - Progress Operations

    func insertOrUpdateProgress(_ progress: SharedProgress) throws {
        guard let db = db else { return }

        try db.run(progressTable.insert(or: .replace,
            progressKanaId <- progress.id,
            mistakeCount <- progress.mistakeCount,
            correctCount <- progress.correctCount,
            lastPracticed <- progress.lastPracticed?.timeIntervalSince1970,
            masteryLevel <- progress.masteryLevel.rawValue
        ))
    }

    func getProgress(forKanaId id: String) throws -> SharedProgress? {
        guard let db = db else { return nil }

        let query = progressTable.filter(progressKanaId == id)

        guard let row = try db.pluck(query) else { return nil }

        return SharedProgress(
            id: row[progressKanaId],
            mistakeCount: row[mistakeCount],
            correctCount: row[correctCount],
            lastPracticed: row[lastPracticed].map { Date(timeIntervalSince1970: $0) },
            masteryLevel: AppConstants.MasteryLevel(rawValue: row[masteryLevel]) ?? .new
        )
    }

    func getAllProgress() throws -> [SharedProgress] {
        guard let db = db else { return [] }

        var progressList: [SharedProgress] = []

        for row in try db.prepare(progressTable) {
            let progress = SharedProgress(
                id: row[progressKanaId],
                mistakeCount: row[mistakeCount],
                correctCount: row[correctCount],
                lastPracticed: row[lastPracticed].map { Date(timeIntervalSince1970: $0) },
                masteryLevel: AppConstants.MasteryLevel(rawValue: row[masteryLevel]) ?? .new
            )
            progressList.append(progress)
        }

        return progressList
    }

    func getWeakKana(limit: Int = 10) throws -> [SharedKana] {
        guard let db = db else { return [] }

        let progressList = try getAllProgress()
        let weakIds = progressList
            .filter { $0.accuracy < 0.7 && $0.totalAttempts >= 3 }
            .sorted { $0.accuracy < $1.accuracy }
            .prefix(limit)
            .map { $0.id }

        return try weakIds.compactMap { try getKana(byId: $0) }
    }

    // MARK: - Daily Selection Operations

    func getDailySelection(for date: Date, widgetType: DailyKanaSelection.WidgetType) throws -> DailyKanaSelection? {
        guard let db = db else { return nil }

        let calendar = Calendar.current
        let startOfDayDate = calendar.startOfDay(for: date)
        let startOfDay = startOfDayDate.timeIntervalSince1970
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDayDate)!.timeIntervalSince1970

        let query = dailySelectionTable
            .filter(dailyDate >= startOfDay && dailyDate < endOfDay)
            .filter(dailyWidgetType == widgetType.rawValue)

        guard let row = try db.pluck(query) else { return nil }

        return DailyKanaSelection(
            kanaId: row[dailyKanaId],
            date: Date(timeIntervalSince1970: row[dailyDate]),
            widgetType: DailyKanaSelection.WidgetType(rawValue: row[dailyWidgetType]) ?? .dailyCharacter
        )
    }

    func saveDailySelection(_ selection: DailyKanaSelection) throws {
        guard let db = db else { return }

        try db.run(dailySelectionTable.insert(or: .replace,
            dailyKanaId <- selection.kanaId,
            dailyDate <- selection.date.timeIntervalSince1970,
            dailyWidgetType <- selection.widgetType.rawValue
        ))
    }
}
