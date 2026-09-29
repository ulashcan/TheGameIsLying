import XCTest
@testable import TheGameIsLying

final class AnalyticsTests: XCTestCase {
    func testEventsAreForwardedToProvider() {
        let probe = RecordingAnalytics()
        let client = AnalyticsClient(providers: [probe])
        client.track(.sessionStarted)
        client.track(.levelStarted(1))
        client.track(.levelFailed(1))
        client.track(.retryClicked(1))
        client.track(.hintClicked(1))
        client.track(.rewardedAdCompleted(reward: "hint"))
        client.track(.levelCompleted(2))
        client.track(.sessionFinished)
        client.track(.dailyChallengeStarted(4))
        client.track(.dailyChallengeCompleted(4))
        XCTAssertEqual(probe.names, [
            "session_started",
            "level_started",
            "level_failed",
            "retry_clicked",
            "hint_clicked",
            "rewarded_ad_completed",
            "level_completed",
            "session_finished",
            "daily_challenge_started",
            "daily_challenge_completed"
        ])
    }
}

final class RecordingAnalytics: AnalyticsProvider {
    var names: [String] = []

    func track(_ event: AnalyticsEvent) {
        names.append(event.name)
    }
}
