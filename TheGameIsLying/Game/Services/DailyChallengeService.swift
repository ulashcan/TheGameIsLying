import Foundation

enum DailyChallengeService {
    static func levelID(for date: Date, calendar: Calendar = .current, catalogCount: Int = LevelCatalog.count) -> Int {
        let safeCount = max(catalogCount, 1)
        let day = calendar.ordinality(of: .day, in: .era, for: date) ?? 1
        return (day % safeCount) + 1
    }
}
