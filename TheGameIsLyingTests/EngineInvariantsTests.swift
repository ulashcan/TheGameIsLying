import XCTest
@testable import TheGameIsLying

final class EngineInvariantsTests: XCTestCase {
    let engine = GameEngine()

    func level(_ id: Int) -> Level {
        guard let level = LevelCatalog.level(id: id) else {
            XCTFail("missing level \(id)")
            return LevelCatalog.all[0]
        }
        return level
    }

    func testUnknownLevelIDsAreNil() {
        XCTAssertNil(LevelCatalog.level(id: 0))
        XCTAssertNil(LevelCatalog.level(id: -1))
        XCTAssertNil(LevelCatalog.level(id: 31))
        XCTAssertNil(LevelCatalog.level(id: 999))
    }

    func testImpossibleActionsNeverSoftLockOrCrash() {
        let actions: [PlayerAction] = [
            .tapButton(id: "ghost"),
            .tapButton(id: ""),
            .tapBackground,
            .tapHidden,
            .timeout
        ]
        for id in 1...LevelCatalog.count {
            for action in actions {
                let result = engine.outcome(for: action, level: level(id), state: .fresh, elapsed: 99)
                if action == .timeout {
                    XCTAssertNotEqual(result, .stillPlaying, "level \(id) timed out into a soft lock")
                }
            }
        }
    }

    func testTapChromeOnTapToWinDoesNotFinishTheLevel() {
        XCTAssertEqual(
            engine.outcome(for: .tapBackground, level: level(4), state: .fresh, elapsed: 0.2),
            .stillPlaying
        )
        XCTAssertEqual(
            engine.outcome(for: .tapHidden, level: level(4), state: .fresh, elapsed: 0.2),
            .stillPlaying
        )
    }

    func testWinningAnEarlierLevelDoesNotRewindProgress() {
        var state = PlayerState.fresh
        state.currentLevelID = 6
        state.completedIDs = [1, 2, 3, 4, 5]
        let next = engine.apply(
            outcome: .win,
            action: .timeout,
            level: level(1),
            state: state
        )
        XCTAssertEqual(next.currentLevelID, 6)
        XCTAssertEqual(next.completedIDs, [1, 2, 3, 4, 5])
    }

    func testWinningLevel30DoesNotCreateInvalidLevel() {
        var state = PlayerState.fresh
        state.currentLevelID = 30
        let next = engine.apply(
            outcome: .win,
            action: .tapHidden,
            level: level(30),
            state: state
        )
        XCTAssertEqual(next.currentLevelID, 30)
        XCTAssertTrue(next.campaignWon)
        XCTAssertNotNil(LevelCatalog.level(id: next.currentLevelID))
    }

    func testRecompletingALevelDoesNotDuplicateCompletion() {
        var state = PlayerState.fresh
        state = engine.apply(outcome: .win, action: .timeout, level: level(1), state: state)
        state = engine.apply(outcome: .win, action: .timeout, level: level(1), state: state)
        XCTAssertEqual(state.completedIDs.filter { $0 == 1 }.count, 1)
    }

    func testFailCountsStayNonNegativeAndRetryKeepsMemory() {
        var state = PlayerState.fresh
        state.lastColorID = "red"
        let lost = engine.outcome(for: .tapButton(id: "red"), level: level(1), state: state, elapsed: 0.2)
        XCTAssertEqual(lost, .lose)
        state = engine.apply(outcome: lost, action: .tapButton(id: "red"), level: level(1), state: state)
        XCTAssertEqual(state.currentLevelID, 1)
        XCTAssertEqual(state.lastColorID, "red")
        XCTAssertGreaterThanOrEqual(state.failCountByLevel["1"] ?? 0, 1)
        XCTAssertGreaterThanOrEqual(state.trustedCount, 0)
        XCTAssertGreaterThanOrEqual(state.ignoredCount, 0)
        let retryWin = engine.outcome(for: .timeout, level: level(1), state: state, elapsed: 5)
        XCTAssertEqual(retryWin, .win)
    }

    func testSkipOnLastLevelDoesNotInventLevel31() {
        let next = engine.skip(level: level(30), state: .fresh)
        XCTAssertEqual(next.currentLevelID, 30)
        XCTAssertTrue(next.campaignWon)
        XCTAssertNil(LevelCatalog.level(id: 31))
    }

    func testEarlyTapFailsUntilIsHonored() {
        XCTAssertEqual(
            engine.outcome(for: .tapButton(id: "go"), level: level(9), state: .fresh, elapsed: 0.1),
            .lose
        )
        XCTAssertEqual(
            engine.outcome(for: .tapButton(id: "go"), level: level(9), state: .fresh, elapsed: 3.0),
            .win
        )
    }

    func testPlayerStateNeverLeavesIllegalCurrentLevelAfterAnyOutcome() {
        for id in 1...LevelCatalog.count {
            for outcome in [LevelOutcome.win, .lose] {
                let action: PlayerAction = outcome == .win && level(id).win == .wait ? .timeout : .tapButton(id: "ghost")
                let next = engine.apply(outcome: outcome, action: action, level: level(id), state: .fresh)
                XCTAssertGreaterThanOrEqual(next.currentLevelID, 1)
                XCTAssertLessThanOrEqual(next.currentLevelID, LevelCatalog.count)
                XCTAssertNotNil(LevelCatalog.level(id: next.currentLevelID))
            }
        }
    }
}
