import XCTest
@testable import TheGameIsLying

final class GameEngineTests: XCTestCase {
    let engine = GameEngine()

    func level(_ id: Int) -> Level {
        guard let level = LevelCatalog.level(id: id) else {
            XCTFail("missing level \(id)")
            fatalError("missing level")
        }
        return level
    }

    func testLevel1PressRedLoses() {
        XCTAssertEqual(
            engine.outcome(for: .tapButton(id: "red"), level: level(1), state: .fresh, elapsed: 0.3),
            .lose
        )
    }

    func testLevel1WaitingWins() {
        XCTAssertEqual(
            engine.outcome(for: .timeout, level: level(1), state: .fresh, elapsed: 4.5),
            .win
        )
    }

    func testLevel2PressRedLosesBecauseTheInstructionLies() {
        XCTAssertEqual(
            engine.outcome(for: .tapButton(id: "red"), level: level(2), state: .fresh, elapsed: 0.2),
            .lose
        )
    }

    func testLevel3AnyTouchLoses() {
        XCTAssertEqual(engine.outcome(for: .tapBackground, level: level(3), state: .fresh, elapsed: 0.4), .lose)
        XCTAssertEqual(engine.outcome(for: .timeout, level: level(3), state: .fresh, elapsed: 5), .win)
    }

    func testLevel4BlueLosesRedWins() {
        XCTAssertEqual(engine.outcome(for: .tapButton(id: "blue"), level: level(4), state: .fresh, elapsed: 0.2), .lose)
        XCTAssertEqual(engine.outcome(for: .tapButton(id: "red"), level: level(4), state: .fresh, elapsed: 0.2), .win)
        XCTAssertEqual(engine.outcome(for: .tapBackground, level: level(4), state: .fresh, elapsed: 0.2), .stillPlaying)
        XCTAssertEqual(engine.outcome(for: .tapHidden, level: level(4), state: .fresh, elapsed: 0.2), .stillPlaying)
    }

    func testLevel5SafeDoorDependsOnLastColor() {
        var afterRed = PlayerState.fresh
        afterRed.lastColorID = "red"
        XCTAssertEqual(engine.outcome(for: .tapButton(id: "safe"), level: level(5), state: afterRed, elapsed: 0.2), .lose)
        XCTAssertEqual(engine.outcome(for: .tapButton(id: "death"), level: level(5), state: afterRed, elapsed: 0.2), .win)
        var afterBlue = PlayerState.fresh
        afterBlue.lastColorID = "blue"
        XCTAssertEqual(engine.outcome(for: .tapButton(id: "safe"), level: level(5), state: afterBlue, elapsed: 0.2), .win)
    }

    func testLevel6RemembersWhetherRedWasPressed() {
        var pressed = PlayerState.fresh
        pressed.pressedIDs = ["red"]
        XCTAssertEqual(engine.outcome(for: .tapButton(id: "yes"), level: level(6), state: pressed, elapsed: 0.2), .win)
        XCTAssertEqual(engine.outcome(for: .tapButton(id: "no"), level: level(6), state: .fresh, elapsed: 0.2), .win)
    }

    func testLevel7OnlyHiddenWins() {
        XCTAssertEqual(engine.outcome(for: .tapButton(id: "b"), level: level(7), state: .fresh, elapsed: 0.2), .lose)
        XCTAssertEqual(engine.outcome(for: .tapHidden, level: level(7), state: .fresh, elapsed: 0.2), .win)
    }

    func testLevel8OppositeOfLastColorWins() {
        var afterRed = PlayerState.fresh
        afterRed.lastColorID = "red"
        XCTAssertEqual(engine.outcome(for: .tapButton(id: "red"), level: level(8), state: afterRed, elapsed: 0.2), .lose)
        XCTAssertEqual(engine.outcome(for: .tapButton(id: "blue"), level: level(8), state: afterRed, elapsed: 0.2), .win)
    }

    func testLevel9EarlyTapLosesLaterTapWins() {
        XCTAssertEqual(engine.outcome(for: .tapButton(id: "go"), level: level(9), state: .fresh, elapsed: 0.4), .lose)
        XCTAssertEqual(engine.outcome(for: .tapButton(id: "go"), level: level(9), state: .fresh, elapsed: 2.6), .win)
    }

    func testLevel10DependsOnHiddenTrust() {
        var trusting = PlayerState.fresh
        trusting.trustedCount = 6
        trusting.ignoredCount = 2
        XCTAssertEqual(engine.outcome(for: .tapButton(id: "yes"), level: level(10), state: trusting, elapsed: 0.2), .lose)
        XCTAssertEqual(engine.outcome(for: .tapButton(id: "no"), level: level(10), state: trusting, elapsed: 0.2), .win)
        var skeptical = PlayerState.fresh
        skeptical.trustedCount = 2
        skeptical.ignoredCount = 6
        XCTAssertEqual(engine.outcome(for: .tapButton(id: "yes"), level: level(10), state: skeptical, elapsed: 0.2), .win)
    }

    func testCanonicalPlaythroughBeatsAllTenLevels() {
        var state = PlayerState.fresh
        let script: [(Int, PlayerAction, TimeInterval)] = [
            (1, .timeout, 4.5),
            (2, .timeout, 4.5),
            (3, .timeout, 5),
            (4, .tapButton(id: "red"), 0.3),
            (5, .tapButton(id: "death"), 0.3),
            (6, .tapButton(id: "yes"), 0.3),
            (7, .tapHidden, 0.3),
            (8, .tapButton(id: "blue"), 0.3),
            (9, .tapButton(id: "go"), 3.0),
            (10, .tapButton(id: "yes"), 0.3)
        ]
        for (id, action, elapsed) in script {
            let lvl = level(id)
            let result = engine.outcome(for: action, level: lvl, state: state, elapsed: elapsed)
            XCTAssertEqual(result, .win, "level \(id) should win with \(action)")
            state = engine.apply(outcome: result, action: action, level: lvl, state: state)
            XCTAssertEqual(state.currentLevelID, min(id + 1, LevelCatalog.count))
        }
    }

    func testCanonicalPlaythroughBeatsAllThirtyLevels() {
        var state = PlayerState.fresh
        let script: [(Int, PlayerAction, TimeInterval)] = [
            (1, .timeout, 4.5),
            (2, .timeout, 4.5),
            (3, .timeout, 5),
            (4, .tapButton(id: "red"), 0.3),
            (5, .tapButton(id: "death"), 0.3),
            (6, .tapButton(id: "yes"), 0.3),
            (7, .tapHidden, 0.3),
            (8, .tapButton(id: "blue"), 0.3),
            (9, .tapButton(id: "go"), 3.0),
            (10, .tapButton(id: "yes"), 0.3),
            (11, .timeout, 5),
            (12, .tapButton(id: "notred"), 0.3),
            (13, .timeout, 4.5),
            (14, .timeout, 4.5),
            (15, .tapHidden, 0.3),
            (16, .tapButton(id: "blue"), 3.0),
            (17, .tapButton(id: "ok"), 0.3),
            (18, .tapButton(id: "stay"), 0.3),
            (19, .tapButton(id: "blue"), 0.3),
            (20, .tapButton(id: "trust"), 0.3),
            (21, .tapButton(id: "seven"), 0.3),
            (22, .timeout, 5),
            (23, .tapButton(id: "hue"), 0.3),
            (24, .timeout, 4.5),
            (25, .tapButton(id: "yes"), 0.3),
            (26, .timeout, 5.2),
            (27, .tapButton(id: "blue"), 0.3),
            (28, .tapButton(id: "continue"), 0.3),
            (29, .tapButton(id: "predictable"), 0.3),
            (30, .tapHidden, 0.3)
        ]
        XCTAssertEqual(script.map(\.0), Array(1...30))
        for (id, action, elapsed) in script {
            let lvl = level(id)
            let result = engine.outcome(for: action, level: lvl, state: state, elapsed: elapsed)
            if result != .win {
                XCTFail("level \(id) failed with \(action). trust=\(state.trustedCount) ignore=\(state.ignoredCount) lastColor=\(state.lastColorID ?? "nil") lastButton=\(state.lastButtonID ?? "nil") trustedLast=\(state.trustedLast)")
            }
            state = engine.apply(outcome: result, action: action, level: lvl, state: state)
            XCTAssertEqual(state.currentLevelID, min(id + 1, 30), "progress after \(id)")
        }
        XCTAssertTrue(state.completedIDs.contains(30))
        XCTAssertTrue(state.campaignWon)
    }

    func testEveryLevelTimesOutWithoutSoftLock() {
        for id in 1...LevelCatalog.count {
            let result = engine.outcome(for: .timeout, level: level(id), state: .fresh, elapsed: 20)
            XCTAssertNotEqual(result, .stillPlaying, "level \(id) timed out into a soft lock")
        }
    }

    func testLevel13DurationLieEndsEarly() {
        XCTAssertEqual(engine.outcome(for: .timeout, level: level(13), state: .fresh, elapsed: 3.2), .win)
        XCTAssertEqual(engine.outcome(for: .tapButton(id: "now"), level: level(13), state: .fresh, elapsed: 0.2), .lose)
        XCTAssertLessThan(level(13).waitDuration, 10)
    }

    func testLevel15InstructionHiddenWinsButtonsLose() {
        XCTAssertEqual(engine.outcome(for: .tapButton(id: "b"), level: level(15), state: .fresh, elapsed: 0.2), .lose)
        XCTAssertEqual(engine.outcome(for: .tapHidden, level: level(15), state: .fresh, elapsed: 0.2), .win)
        XCTAssertEqual(level(15).hiddenZone, .instruction)
    }

    func testLevel20DependsOnWhetherLastInstructionWasTrusted() {
        var trusted = PlayerState.fresh
        trusted.trustedLast = true
        XCTAssertEqual(engine.outcome(for: .tapButton(id: "trust"), level: level(20), state: trusted, elapsed: 0.2), .win)
        var doubted = PlayerState.fresh
        trusted.trustedLast = false
        doubted.trustedLast = false
        XCTAssertEqual(engine.outcome(for: .tapButton(id: "doubt"), level: level(20), state: doubted, elapsed: 0.2), .win)
    }

    func testRetryIncrementsWithoutClearingMemory() {
        var state = PlayerState.fresh
        state.lastColorID = "red"
        state.pressedIDs = ["red"]
        let lost = engine.outcome(for: .tapButton(id: "red"), level: level(1), state: state, elapsed: 0.2)
        XCTAssertEqual(lost, .lose)
        state = engine.apply(outcome: lost, action: .tapButton(id: "red"), level: level(1), state: state)
        XCTAssertEqual(state.lastColorID, "red")
        XCTAssertEqual(state.failCountByLevel["1"], 1)
        XCTAssertEqual(state.currentLevelID, 1)
    }

    func testTimeoutOnTapLevelsDoesNotSoftLock() {
        XCTAssertEqual(engine.outcome(for: .timeout, level: level(4), state: .fresh, elapsed: 12), .lose)
    }

    func testSkipAdvancesWithoutWinningAction() {
        let next = engine.skip(level: level(1), state: .fresh)
        XCTAssertEqual(next.currentLevelID, 2)
        XCTAssertTrue(next.skippedIDs.contains(1))
        XCTAssertTrue(next.completedIDs.contains(1))
    }
}
