import XCTest
@testable import TheGameIsLying

@MainActor
final class GameSessionTortureTests: XCTestCase {
    func makeSession(suite: String, ads: AdManager = AdManager(adsEnabled: false), analytics: AnalyticsClient = AnalyticsClient(providers: [])) -> GameSession {
        let defaults = UserDefaults(suiteName: suite) ?? .standard
        defaults.removePersistentDomain(forName: suite)
        return GameSession(
            store: PersistenceService(defaults: defaults),
            ads: ads,
            analytics: analytics
        )
    }

    func testSpamSubmitAfterFailDoesNotDoubleCount() {
        let session = makeSession(suite: "torture.spam")
        session.playCampaign()
        session.submit(.tapButton(id: "red"), elapsed: 0.05)
        session.submit(.tapButton(id: "red"), elapsed: 0.06)
        session.submit(.tapButton(id: "red"), elapsed: 0.07)
        XCTAssertEqual(session.player.failCountByLevel["1"], 1)
        XCTAssertEqual(session.route, .result(won: false))
    }

    func testRetrySpamStaysOnSameLevel() {
        let session = makeSession(suite: "torture.retry")
        session.playCampaign()
        session.submit(.tapButton(id: "red"), elapsed: 0.1)
        session.retry()
        session.retry()
        session.retry()
        XCTAssertEqual(session.level.id, 1)
        XCTAssertEqual(session.route, .play)
        XCTAssertEqual(session.player.retryCount, 3)
    }

    func testNextSpamDoesNotSkipALevel() {
        let session = makeSession(suite: "torture.next")
        session.playCampaign()
        session.submit(.timeout, elapsed: 5)
        session.nextLevel()
        session.nextLevel()
        session.nextLevel()
        XCTAssertEqual(session.level.id, 2)
        XCTAssertEqual(session.player.currentLevelID, 2)
    }

    func testGoHomeOnSuccessDoesNotStartNextLevel() {
        let session = makeSession(suite: "torture.home")
        session.playCampaign()
        session.submit(.timeout, elapsed: 5)
        XCTAssertEqual(session.route, .result(won: true))
        XCTAssertEqual(session.player.currentLevelID, 2)
        session.goHome()
        XCTAssertEqual(session.route, .home)
        session.nextLevel()
        XCTAssertEqual(session.route, .home, "cancelled auto-next must not yank the player into the next level")
        XCTAssertEqual(session.player.currentLevelID, 2)
    }

    func testDailyDoesNotMutateCampaignProgress() {
        let session = makeSession(suite: "torture.daily")
        session.playCampaign()
        session.submit(.timeout, elapsed: 5)
        session.nextLevel()
        XCTAssertEqual(session.level.id, 2)
        session.goHome()
        session.player.currentLevelID = 4
        session.playDaily()
        session.submit(.tapButton(id: "ghost"), elapsed: 0.2)
        if case .result = session.route {
            session.retry()
            session.submit(.timeout, elapsed: 20)
        }
        session.goHome()
        session.playCampaign()
        XCTAssertEqual(session.player.currentLevelID, 4)
        XCTAssertEqual(session.level.id, 4)
        XCTAssertFalse(session.isDaily)
    }

    func testCampaignCompleteStaysFinished() {
        let session = makeSession(suite: "torture.done")
        session.player.campaignWon = true
        session.player.currentLevelID = 30
        session.playCampaign()
        XCTAssertEqual(session.route, .finished)
        session.playCampaign()
        XCTAssertEqual(session.route, .finished)
    }

    func testPlayAgainAfterFinishStartsLevelOne() {
        let session = makeSession(suite: "torture.again")
        session.player.campaignWon = true
        session.player.currentLevelID = 30
        session.playAgain()
        XCTAssertEqual(session.player, .fresh)
        XCTAssertEqual(session.level.id, 1)
        XCTAssertEqual(session.route, .play)
    }

    func testHintDoesNotApplyAfterLeavingLevel() async {
        let session = makeSession(
            suite: "torture.hintleak",
            ads: AdManager(adsEnabled: true, simulatedDelayNanoseconds: 200_000_000)
        )
        session.playCampaign()
        XCTAssertEqual(session.level.id, 1)
        let hintTask = Task { await session.requestHint() }
        var spins = 0
        while !session.adsBusy && spins < 1_000 {
            await Task.yield()
            spins += 1
        }
        XCTAssertTrue(session.adsBusy, "hint request should start on level 1")
        session.submit(.timeout, elapsed: 5)
        session.nextLevel()
        XCTAssertEqual(session.level.id, 2)
        await hintTask.value
        XCTAssertEqual(session.level.id, 2)
        XCTAssertFalse(session.hintVisible, "level 1 hint must not leak onto level 2")
        XCTAssertNil(session.grantedHint)
    }

    func testRelaunchRestoresProgress() {
        let suite = "torture.relaunch"
        let defaults = UserDefaults(suiteName: suite) ?? .standard
        defaults.removePersistentDomain(forName: suite)
        let store = PersistenceService(defaults: defaults)
        let first = GameSession(store: store, ads: AdManager(adsEnabled: false), analytics: AnalyticsClient(providers: []))
        first.playCampaign()
        first.submit(.timeout, elapsed: 5)
        first.nextLevel()
        XCTAssertEqual(first.player.currentLevelID, 2)
        let relaunched = GameSession(store: store, ads: AdManager(adsEnabled: false), analytics: AnalyticsClient(providers: []))
        XCTAssertEqual(relaunched.player.currentLevelID, 2)
        relaunched.playCampaign()
        XCTAssertEqual(relaunched.level.id, 2)
    }

    func testContinueWhenAdsOffDoesNotSkip() async {
        let session = makeSession(suite: "torture.adsoff.continue")
        session.playCampaign()
        session.submit(.tapButton(id: "red"), elapsed: 0.2)
        await session.continueAfterFail()
        XCTAssertEqual(session.route, .result(won: false))
        XCTAssertEqual(session.level.id, 1)
        XCTAssertFalse(session.player.skippedIDs.contains(1))
    }

    func testDailyLockedUntilPastLevel3() {
        let session = makeSession(suite: "torture.daily.lock")
        XCTAssertFalse(session.dailyUnlocked)
        session.playDaily()
        XCTAssertEqual(session.route, .home)
        session.player.currentLevelID = 4
        XCTAssertTrue(session.dailyUnlocked)
        session.playDaily()
        XCTAssertEqual(session.route, .play)
    }

    func testFailedRewardedAdDoesNotSkipLevel() async {
        let session = makeSession(
            suite: "torture.adfail",
            ads: AdManager(adsEnabled: true, simulatedGrant: false, simulatedDelayNanoseconds: 0)
        )
        session.playCampaign()
        session.submit(.tapButton(id: "red"), elapsed: 0.2)
        await session.continueAfterFail()
        XCTAssertEqual(session.route, .result(won: false))
        XCTAssertEqual(session.level.id, 1)
        XCTAssertFalse(session.player.skippedIDs.contains(1))
    }

    func testContinueAdAfterRetryDoesNotSkip() async {
        let session = makeSession(
            suite: "torture.continue.retry",
            ads: AdManager(adsEnabled: true, simulatedGrant: true, simulatedDelayNanoseconds: 200_000_000)
        )
        session.playCampaign()
        session.submit(.tapButton(id: "red"), elapsed: 0.2)
        XCTAssertEqual(session.route, .result(won: false))
        let continueTask = Task { await session.continueAfterFail() }
        var spins = 0
        while !session.adsBusy && spins < 1_000 {
            await Task.yield()
            spins += 1
        }
        session.retry()
        XCTAssertEqual(session.route, .play)
        XCTAssertEqual(session.level.id, 1)
        await continueTask.value
        XCTAssertEqual(session.level.id, 1)
        XCTAssertEqual(session.player.currentLevelID, 1)
        XCTAssertFalse(session.player.skippedIDs.contains(1))
        XCTAssertEqual(session.route, .play)
    }

    func testImmediateBackgroundTapDoesNotFailWaitLevel() {
        let session = makeSession(suite: "torture.chromelock")
        session.playCampaign()
        session.submit(.tapBackground, elapsed: 0.01)
        XCTAssertEqual(session.route, .play, "stray NEXT-finger lift must not fail a wait level")
        session.submit(.timeout, elapsed: 5)
        XCTAssertEqual(session.route, .result(won: true))
    }

    func testNextLevelIgnoresStrayBackgroundTapOnDontTouch() {
        let session = makeSession(suite: "torture.l3bleed")
        session.playCampaign()
        session.submit(.timeout, elapsed: 5)
        session.nextLevel()
        session.submit(.timeout, elapsed: 5)
        session.nextLevel()
        XCTAssertEqual(session.level.id, 3)
        session.submit(.tapBackground, elapsed: 0.02)
        XCTAssertEqual(session.route, .play)
        XCTAssertEqual(session.level.id, 3)
        session.submit(.timeout, elapsed: 5)
        XCTAssertEqual(session.route, .result(won: true))
    }

    func testBackgroundTapFailsWaitLevelAfterGrace() {
        let session = makeSession(suite: "torture.chromelock.after")
        session.playCampaign()
        let deadline = Date().addingTimeInterval(0.7)
        while Date() < deadline {
            RunLoop.current.run(until: Date().addingTimeInterval(0.05))
        }
        session.submit(.tapBackground, elapsed: 0.7)
        XCTAssertEqual(session.route, .result(won: false))
    }

    func testWaitClockWinsAfterNextLevel() async {
        let session = makeSession(suite: "torture.waitclock")
        session.playCampaign()
        let firstDeadline = Date().addingTimeInterval(4.5)
        while Date() < firstDeadline, session.route != .result(won: true) {
            try? await Task.sleep(nanoseconds: 50_000_000)
        }
        XCTAssertEqual(session.route, .result(won: true), "level 1 wait clock should win without a view")
        session.nextLevel()
        XCTAssertEqual(session.level.id, 2)
        XCTAssertEqual(session.route, .play)
        let secondDeadline = Date().addingTimeInterval(4.5)
        while Date() < secondDeadline, session.route != .result(won: true) {
            try? await Task.sleep(nanoseconds: 50_000_000)
        }
        XCTAssertEqual(session.route, .result(won: true), "level 2 wait clock must start after NEXT")
        XCTAssertEqual(session.player.currentLevelID, 3)
    }

    func testDailyEmitsAnalyticsEvents() {
        let probe = RecordingAnalytics()
        let session = makeSession(
            suite: "torture.daily.analytics",
            analytics: AnalyticsClient(providers: [probe])
        )
        session.player.currentLevelID = 4
        session.playDaily()
        XCTAssertTrue(probe.names.contains("daily_challenge_started"))
        XCTAssertTrue(probe.names.contains("level_started"))
        session.submit(.timeout, elapsed: 20)
        if session.route == .result(won: true) {
            XCTAssertTrue(probe.names.contains("daily_challenge_completed"))
        } else {
            session.retry()
            session.submit(.timeout, elapsed: 20)
            if session.route == .result(won: true) {
                XCTAssertTrue(probe.names.contains("daily_challenge_completed"))
            }
        }
    }
}
