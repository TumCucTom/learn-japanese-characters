import XCTest
@testable import Maru

final class SharedDatabaseTests: XCTestCase {
    func testDeleteAllProgressRemovesSavedProgress() throws {
        let progress = SharedProgress(
            id: "h_basic_1",
            mistakeCount: 1,
            correctCount: 4,
            lastPracticed: Date(),
            masteryLevel: .learning
        )

        try SharedDatabase.shared.insertOrUpdateProgress(progress)
        XCTAssertNotNil(try SharedDatabase.shared.getProgress(forKanaId: progress.id))

        try SharedDatabase.shared.deleteAllProgress()

        XCTAssertNil(try SharedDatabase.shared.getProgress(forKanaId: progress.id))
    }
}
