import XCTest

final class CampaignPlaythroughUITests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    func testPlayAllThirtyLevelsStartToFinish() {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing"]
        app.launch()
        XCTAssertTrue(app.buttons["home.play"].waitForExistence(timeout: 8))
        tapElement(app.buttons["home.play"], name: "home.play")

        play(app, 1, .wait(12))
        play(app, 2, .wait(12))
        play(app, 3, .wait(12))
        play(app, 4, .tap("red"))
        play(app, 5, .tap("death"))
        play(app, 6, .tap("yes"))
        play(app, 7, .title)
        play(app, 8, .tap("blue"))
        play(app, 9, .delayTap(2.8, "go"))
        play(app, 10, .tap("yes"))
        play(app, 11, .wait(12))
        play(app, 12, .tap("notred"))
        play(app, 13, .wait(12))
        play(app, 14, .wait(12))
        play(app, 15, .instruction)
        play(app, 16, .delayTap(2.8, "blue"))
        play(app, 17, .tap("ok"))
        play(app, 18, .tap("stay"))
        play(app, 19, .tap("blue"))
        play(app, 20, .tap("trust"))
        play(app, 21, .tap("seven"))
        play(app, 22, .wait(12))
        play(app, 23, .tap("hue"))
        play(app, 24, .wait(12))
        play(app, 25, .tap("yes"))
        play(app, 26, .wait(12))
        play(app, 27, .tap("blue"))
        play(app, 28, .tap("continue"))
        play(app, 29, .tap("predictable"))
        play(app, 30, .title)

        XCTAssertTrue(
            app.buttons["finished.again"].waitForExistence(timeout: 8)
            || app.staticTexts["YOU SURVIVED."].waitForExistence(timeout: 2)
        )
        attach(app, "campaign-complete")
    }

    private enum Move {
        case wait(TimeInterval)
        case tap(String)
        case title
        case instruction
        case delayTap(TimeInterval, String)
    }

    private func play(_ app: XCUIApplication, _ id: Int, _ move: Move) {
        let expected = String(format: "LEVEL %02d", id)
        XCTAssertTrue(app.buttons["game.levelTitle"].waitForExistence(timeout: 8), "missing \(expected)")
        XCTAssertEqual(app.buttons["game.levelTitle"].label, expected, "wrong level before move \(id)")
        XCTAssertFalse(app.buttons["result.retry"].exists, "already failed before playing \(expected)")

        switch move {
        case .wait:
            break
        case .tap(let buttonID):
            tapElement(app.buttons["game.button.\(buttonID)"], name: "\(buttonID) on \(expected)")
        case .title:
            tapElement(app.buttons["game.levelTitle"], name: "title on \(expected)")
        case .instruction:
            tapElement(app.descendants(matching: .any)["game.instruction"], name: "instruction on \(expected)")
        case .delayTap(let delay, let buttonID):
            Thread.sleep(forTimeInterval: delay)
            tapElement(app.buttons["game.button.\(buttonID)"], name: "\(buttonID) on \(expected)")
        }

        XCTAssertTrue(
            app.buttons["result.next"].waitForExistence(timeout: waitTimeout(move)),
            "did not win \(expected); retry=\(app.buttons["result.retry"].exists)"
        )
        XCTAssertFalse(app.staticTexts["GAME OVER"].exists, "lost \(expected)")
        tapNext(app, from: id)
    }

    private func tapElement(_ element: XCUIElement, name: String) {
        XCTAssertTrue(element.waitForExistence(timeout: 4), "missing \(name)")
        if element.isHittable {
            element.tap()
        } else {
            element.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        }
    }

    private func tapNext(_ app: XCUIApplication, from id: Int) {
        let next = app.buttons["result.next"]
        XCTAssertTrue(next.waitForExistence(timeout: 4))
        next.tap()
        if id == 30 {
            return
        }
        let expected = String(format: "LEVEL %02d", id + 1)
        if !app.buttons["game.levelTitle"].waitForExistence(timeout: 6) || app.buttons["game.levelTitle"].label != expected {
            if next.exists { next.tap() }
            XCTAssertTrue(app.buttons["game.levelTitle"].waitForExistence(timeout: 6), "stuck after winning level \(id)")
        }
        XCTAssertFalse(app.buttons["result.retry"].exists, "lost after NEXT from level \(id)")
        XCTAssertEqual(app.buttons["game.levelTitle"].label, expected, "wrong level after \(id)")
    }

    private func waitTimeout(_ move: Move) -> TimeInterval {
        switch move {
        case .wait(let timeout):
            return timeout
        default:
            return 8
        }
    }

    private func attach(_ app: XCUIApplication, _ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
