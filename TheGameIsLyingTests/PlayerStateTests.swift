import XCTest
@testable import TheGameIsLying

final class PlayerStateTests: XCTestCase {
    func testFreshStateStartsAtLevelOne() {
        XCTAssertEqual(PlayerState.fresh.currentLevelID, 1)
        XCTAssertTrue(PlayerState.fresh.completedIDs.isEmpty)
        XCTAssertEqual(PlayerState.fresh.retryCount, 0)
    }

    func testPersistenceRoundTrip() {
        let defaults = UserDefaults(suiteName: "PlayerStateTests")!
        defaults.removePersistentDomain(forName: "PlayerStateTests")
        let store = PersistenceService(defaults: defaults)
        var state = PlayerState.fresh
        state.currentLevelID = 4
        state.pressedIDs = ["red"]
        store.save(state)
        XCTAssertEqual(store.load().currentLevelID, 4)
        XCTAssertEqual(store.load().pressedIDs, ["red"])
    }

    func testResetReturnsFreshCampaign() {
        let defaults = UserDefaults(suiteName: "PlayerStateResetTests")!
        defaults.removePersistentDomain(forName: "PlayerStateResetTests")
        let store = PersistenceService(defaults: defaults)
        var state = PlayerState.fresh
        state.currentLevelID = 8
        store.save(state)
        store.reset()
        XCTAssertEqual(store.load(), .fresh)
    }

    func testCorruptedPersistenceReturnsFreshState() {
        let defaults = UserDefaults(suiteName: "PlayerStateCorruptTests")!
        defaults.removePersistentDomain(forName: "PlayerStateCorruptTests")
        defaults.set(Data("{{{{".utf8), forKey: "player_state_v1")
        let store = PersistenceService(defaults: defaults)
        XCTAssertEqual(store.load(), .fresh)
    }

    func testInvalidLevelIDIsClamped() {
        let defaults = UserDefaults(suiteName: "PlayerStateClampTests")!
        defaults.removePersistentDomain(forName: "PlayerStateClampTests")
        let store = PersistenceService(defaults: defaults)
        var state = PlayerState.fresh
        state.currentLevelID = 999
        store.save(state)
        XCTAssertEqual(store.load().currentLevelID, 1)
        XCTAssertFalse(store.load().campaignWon)
    }

    func testZeroAndMissingLevelIDsAreClamped() {
        let defaults = UserDefaults(suiteName: "PlayerStateZeroTests") ?? .standard
        defaults.removePersistentDomain(forName: "PlayerStateZeroTests")
        let store = PersistenceService(defaults: defaults)
        var state = PlayerState.fresh
        state.currentLevelID = 0
        store.save(state)
        XCTAssertEqual(store.load().currentLevelID, 1)
        defaults.removeObject(forKey: "player_state_v1")
        XCTAssertEqual(store.load(), .fresh)
    }
}
