import XCTest
@testable import TheGameIsLying

final class LevelCatalogTests: XCTestCase {
    func testCatalogHasThirtyUniquePlayableLevels() {
        XCTAssertEqual(LevelCatalog.count, 30)
        let ids = LevelCatalog.all.map(\.id)
        XCTAssertEqual(ids, Array(1...30))
        XCTAssertEqual(Set(ids).count, 30)
        XCTAssertEqual(Set(LevelCatalog.all.map(\.instruction)).count, 30)
        XCTAssertEqual(LevelCatalog.level(id: 13)?.instruction, "WAIT 10 SECONDS.")
        XCTAssertLessThan(LevelCatalog.level(id: 1)?.waitDuration ?? 99, 4)
        XCTAssertLessThan(LevelCatalog.level(id: 2)?.waitDuration ?? 99, 4)
        for level in LevelCatalog.all {
            XCTAssertFalse(level.hint.isEmpty, "level \(level.id) missing hint")
            XCTAssertFalse(level.successMessage.isEmpty)
            XCTAssertFalse(level.failureMessage.isEmpty)
            XCTAssertGreaterThan(level.waitDuration, 0)
            XCTAssertLessThanOrEqual(level.waitDuration, 15)
            for button in level.buttons {
                XCTAssertFalse(button.title.isEmpty)
            }
        }
    }

    func testHiddenZonesAreWiredForHiddenLevels() {
        XCTAssertEqual(LevelCatalog.level(id: 7)?.hiddenZone, .levelTitle)
        XCTAssertEqual(LevelCatalog.level(id: 15)?.hiddenZone, .instruction)
        XCTAssertEqual(LevelCatalog.level(id: 30)?.hiddenZone, .levelTitle)
    }
}
