import XCTest
@testable import TheGameIsLying

final class DailyChallengeTests: XCTestCase {
    func testSameDayMapsToSameLevel() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let day = Date(timeIntervalSince1970: 1_700_000_000)
        let a = DailyChallengeService.levelID(for: day, calendar: calendar, catalogCount: 10)
        let b = DailyChallengeService.levelID(for: day.addingTimeInterval(3_600), calendar: calendar, catalogCount: 10)
        XCTAssertEqual(a, b)
        XCTAssertGreaterThanOrEqual(a, 1)
        XCTAssertLessThanOrEqual(a, 10)
    }

    func testDifferentDaysCanChange() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let day = Date(timeIntervalSince1970: 1_700_000_000)
        let next = calendar.date(byAdding: .day, value: 1, to: day)!
        let a = DailyChallengeService.levelID(for: day, calendar: calendar, catalogCount: 10)
        let b = DailyChallengeService.levelID(for: next, calendar: calendar, catalogCount: 10)
        XCTAssertNotEqual(a, b)
    }

    func testUsesFullCatalogRange() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let ids = (0..<60).map { offset -> Int in
            let date = Date(timeIntervalSince1970: 1_700_000_000).addingTimeInterval(TimeInterval(offset) * 86_400)
            return DailyChallengeService.levelID(for: date, calendar: calendar)
        }
        XCTAssertEqual(Set(ids).count, LevelCatalog.count)
    }

    func testTimezoneDoesNotChangeCalendarDayIdentity() {
        var tokyo = Calendar(identifier: .gregorian)
        tokyo.timeZone = TimeZone(identifier: "Asia/Tokyo")!
        let noon = tokyo.date(from: DateComponents(year: 2024, month: 6, day: 15, hour: 12))!
        let later = noon.addingTimeInterval(3_600)
        XCTAssertEqual(
            DailyChallengeService.levelID(for: noon, calendar: tokyo, catalogCount: 30),
            DailyChallengeService.levelID(for: later, calendar: tokyo, catalogCount: 30)
        )
    }
}
