import XCTest
@testable import TheGameIsLying

@MainActor
final class GameSessionTests: XCTestCase {
    func testHintAndRetryEmitAnalytics() async {
        let probe = RecordingAnalytics()
        let defaults = UserDefaults(suiteName: "GameSessionAnalytics")!
        defaults.removePersistentDomain(forName: "ui.GameSessionAnalytics")
        defaults.removePersistentDomain(forName: "GameSessionAnalytics")
        let session = GameSession(
            store: PersistenceService(defaults: defaults),
            ads: AdManager(adsEnabled: false),
            analytics: AnalyticsClient(providers: [probe])
        )
        XCTAssertTrue(probe.names.contains("session_started"))
        session.playCampaign()
        XCTAssertTrue(probe.names.contains("level_started"))
        await session.requestHint()
        XCTAssertTrue(probe.names.contains("hint_clicked"))
        XCTAssertFalse(probe.names.contains("rewarded_ad_completed"))
        XCTAssertEqual(session.grantedHint, session.level.hint)
        session.submit(.tapButton(id: "red"), elapsed: 0.2)
        XCTAssertTrue(probe.names.contains("level_failed"))
        session.retry()
        XCTAssertTrue(probe.names.contains("retry_clicked"))
        XCTAssertEqual(session.route, .play)
        session.endSession()
        XCTAssertTrue(probe.names.contains("session_finished"))
    }

    func testHintWhenAdsOnEmitsRewarded() async {
        let probe = RecordingAnalytics()
        let defaults = UserDefaults(suiteName: "GameSessionHintAdsOn")!
        defaults.removePersistentDomain(forName: "GameSessionHintAdsOn")
        let session = GameSession(
            store: PersistenceService(defaults: defaults),
            ads: AdManager(adsEnabled: true, simulatedDelayNanoseconds: 0),
            analytics: AnalyticsClient(providers: [probe])
        )
        session.playCampaign()
        await session.requestHint()
        XCTAssertTrue(probe.names.contains("hint_clicked"))
        XCTAssertTrue(probe.names.contains("rewarded_ad_completed"))
        XCTAssertEqual(session.grantedHint, session.level.hint)
    }

    func testRetryKeepsMemoryAndSameLevel() {
        let defaults = UserDefaults(suiteName: "GameSessionRetry")!
        defaults.removePersistentDomain(forName: "GameSessionRetry")
        let session = GameSession(
            store: PersistenceService(defaults: defaults),
            ads: AdManager(adsEnabled: false),
            analytics: AnalyticsClient(providers: [])
        )
        session.playCampaign()
        session.submit(.tapButton(id: "red"), elapsed: 0.2)
        XCTAssertEqual(session.player.currentLevelID, 1)
        XCTAssertEqual(session.player.lastColorID, "red")
        session.retry()
        XCTAssertEqual(session.level.id, 1)
        XCTAssertEqual(session.player.lastColorID, "red")
        XCTAssertEqual(session.player.retryCount, 1)
    }
}
