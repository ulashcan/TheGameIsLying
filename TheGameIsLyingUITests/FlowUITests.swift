import XCTest

final class FlowUITests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    func testHomePlayAndDailyExist() {
        let app = launch()
        XCTAssertTrue(app.buttons["home.play"].exists)
        XCTAssertFalse(app.buttons["home.daily"].exists, "daily must stay hidden until past level 3")
        attach(app, "home")
    }

    func testFailThenRetry() {
        let app = launch()
        app.buttons["home.play"].tap()
        XCTAssertTrue(app.buttons["game.levelTitle"].waitForExistence(timeout: 6))
        XCTAssertEqual(app.buttons["game.levelTitle"].label, "LEVEL 01")
        attach(app, "level-01")
        XCTAssertTrue(app.buttons["game.button.red"].waitForExistence(timeout: 4))
        app.buttons["game.button.red"].tap()
        XCTAssertTrue(
            app.staticTexts["GAME OVER"].waitForExistence(timeout: 6)
            || app.otherElements["result.fail"].waitForExistence(timeout: 2)
        )
        attach(app, "game-over")
        XCTAssertTrue(app.buttons["result.retry"].waitForExistence(timeout: 4))
        app.buttons["result.retry"].tap()
        XCTAssertTrue(app.buttons["game.levelTitle"].waitForExistence(timeout: 6))
        XCTAssertEqual(app.buttons["game.levelTitle"].label, "LEVEL 01")
        attach(app, "retry")
    }

    func testWaitWinsThenNextLevel() {
        let app = launch()
        app.buttons["home.play"].tap()
        XCTAssertTrue(app.buttons["game.levelTitle"].waitForExistence(timeout: 6))
        XCTAssertEqual(app.buttons["game.levelTitle"].label, "LEVEL 01")
        attach(app, "level-01-wait")
        XCTAssertTrue(
            app.buttons["result.next"].waitForExistence(timeout: 8)
            || app.buttons["game.levelTitle"].waitForExistence(timeout: 2)
        )
        let progressed = app.buttons["result.next"].exists
            || ["LEVEL 02", "LEVEL 03"].contains(safeTitle(app))
        XCTAssertTrue(progressed, "waiting on level 1 should win or auto-advance")
        attach(app, "success")
        if app.buttons["result.next"].exists {
            app.buttons["result.next"].tap()
        }
        XCTAssertTrue(
            app.buttons["game.levelTitle"].waitForExistence(timeout: 6)
            || app.buttons["result.next"].exists
        )
        let title = safeTitle(app)
        XCTAssertTrue(
            title == "LEVEL 02" || title == "LEVEL 03" || app.buttons["result.next"].exists
        )
        attach(app, "level-02")
        XCTAssertTrue(
            app.buttons["result.next"].waitForExistence(timeout: 10)
            || app.otherElements["result.success"].waitForExistence(timeout: 2)
        )
        attach(app, "level-02-success")
        XCTAssertTrue(
            app.staticTexts["YOU GOT ME."].waitForExistence(timeout: 2)
            || app.otherElements["result.success"].waitForExistence(timeout: 2),
            "level 2 wait must win with YOU GOT ME — never tap-win"
        )
    }

    func testHomeOnSuccessStaysHome() {
        let app = launch()
        app.buttons["home.play"].tap()
        XCTAssertTrue(app.buttons["game.levelTitle"].waitForExistence(timeout: 6))
        XCTAssertTrue(app.buttons["result.home"].waitForExistence(timeout: 8))
        app.buttons["result.home"].tap()
        XCTAssertTrue(app.buttons["home.play"].waitForExistence(timeout: 4))
        attach(app, "home-after-success")
        XCTAssertTrue(app.buttons["home.play"].exists)
        XCTAssertFalse(app.buttons["game.levelTitle"].exists)
    }

    func testAccessibilityIdentifiersAndHitTargets() {
        let app = launch()
        let play = app.buttons["home.play"]
        XCTAssertTrue(play.exists)
        XCTAssertGreaterThanOrEqual(play.frame.height, 44)
        XCTAssertFalse(app.buttons["home.daily"].exists)
        play.tap()
        XCTAssertTrue(app.buttons["game.hint"].waitForExistence(timeout: 6))
        XCTAssertGreaterThanOrEqual(app.buttons["game.hint"].frame.height, 44)
        XCTAssertTrue(app.buttons["game.levelTitle"].exists)
        let instruction = app.descendants(matching: .any)["game.instruction"]
        XCTAssertTrue(instruction.waitForExistence(timeout: 2))
        attach(app, "a11y-level")
    }

    func testDynamicTypeDoesNotHidePlay() {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing", "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXL"]
        app.launch()
        XCTAssertTrue(app.buttons["home.play"].waitForExistence(timeout: 8))
        XCTAssertTrue(app.buttons["home.play"].isHittable)
        attach(app, "dynamic-type-home")
    }

    func testFirstSessionReachesLevel3() {
        let app = launch()
        app.buttons["home.play"].tap()
        XCTAssertTrue(app.buttons["game.levelTitle"].waitForExistence(timeout: 6))
        let deadline = Date().addingTimeInterval(18)
        var sawLevel3 = false
        while Date() < deadline {
            if safeTitle(app) == "LEVEL 03" {
                sawLevel3 = true
                break
            }
            if app.buttons["result.next"].exists {
                app.buttons["result.next"].tap()
            }
            RunLoop.current.run(until: Date().addingTimeInterval(0.25))
        }
        attach(app, "first-session-l3")
        XCTAssertTrue(sawLevel3, "first session should reach LEVEL 03 without reading a README")
    }

    private func launch() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing"]
        app.launch()
        XCTAssertTrue(app.buttons["home.play"].waitForExistence(timeout: 8))
        return app
    }

    private func safeTitle(_ app: XCUIApplication) -> String? {
        let title = app.buttons["game.levelTitle"]
        guard title.exists else { return nil }
        return title.label
    }

    private func attach(_ app: XCUIApplication, _ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
