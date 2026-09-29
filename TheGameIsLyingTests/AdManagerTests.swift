import XCTest
@testable import TheGameIsLying

final class AdManagerTests: XCTestCase {
    func testDisabledAdsGrantRewardWithoutNetwork() async {
        let ads = AdManager(adsEnabled: false)
        let granted = await ads.showRewarded(reward: "hint")
        XCTAssertTrue(granted)
    }

    func testEnabledAdsCanFailWithoutSkipping() async {
        let ads = AdManager(adsEnabled: true, simulatedGrant: false, simulatedDelayNanoseconds: 0)
        let granted = await ads.showRewarded(reward: "hint")
        XCTAssertFalse(granted)
    }

    func testEnabledAdsCanGrant() async {
        let ads = AdManager(adsEnabled: true, simulatedGrant: true, simulatedDelayNanoseconds: 0)
        let granted = await ads.showRewarded(reward: "continue")
        XCTAssertTrue(granted)
    }

    func testCancelledAdDoesNotGrant() async {
        let ads = AdManager(adsEnabled: true, simulatedGrant: true, simulatedDelayNanoseconds: 400_000_000)
        let task = Task { await ads.showRewarded(reward: "hint") }
        task.cancel()
        let granted = await task.value
        XCTAssertFalse(granted)
    }

    func testTestIDsAreNotProduction() {
        XCTAssertTrue(AdConfig.testAppID.contains("3940256099942544"))
        XCTAssertTrue(AdConfig.testRewardedUnitID.contains("3940256099942544"))
        XCTAssertFalse(AdConfig.adsEnabled)
    }

    func testAdsOffCopyDoesNotPromiseAWatch() {
        let ads = AdManager(adsEnabled: false)
        XCTAssertEqual(ads.hintCTA, "GET HINT")
        XCTAssertEqual(ads.hintAccessibility, "Get hint")
        XCTAssertFalse(ads.offersRewardedContinue)
    }

    func testAdsOnCopyPromisesAWatch() {
        let ads = AdManager(adsEnabled: true)
        XCTAssertEqual(ads.hintCTA, "WATCH AD → GET HINT")
        XCTAssertEqual(ads.continueCTA, "WATCH AD → CONTINUE")
        XCTAssertEqual(ads.hintAccessibility, "Watch ad to get hint")
        XCTAssertTrue(ads.offersRewardedContinue)
    }
}
