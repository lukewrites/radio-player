import XCTest

@MainActor
final class PlayerTests: XCTestCase {

    private var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        app.launch()
    }

    override func tearDown() {
        app.terminate()
        super.tearDown()
    }

    private func navigateToCollectionBrowser() {
        // If on sidebar, tap "All Shows" to go to collection browser
        let backButton = app.navigationBars.buttons["Radio Player"]
        if backButton.waitForExistence(timeout: 2) {
            backButton.tap()
        }
        let row = app.staticTexts["All Shows"]
        if row.waitForExistence(timeout: 3) {
            row.tap()
        }
    }

    func testThemePickerShowsBothThemes() {
        // Navigate back to sidebar and open Settings
        let backButton = app.navigationBars.buttons["Radio Player"]
        if backButton.waitForExistence(timeout: 3) {
            backButton.tap()
        }

        let settings = app.buttons["Settings"]
        guard settings.waitForExistence(timeout: 5) else {
            XCTFail("Settings button not found")
            return
        }
        settings.tap()

        // Inline Picker options render as Buttons in iOS accessibility tree
        XCTAssertTrue(app.buttons["System"].waitForExistence(timeout: 3),
                      "System theme option should appear in settings")
        XCTAssertTrue(app.buttons["Midnight"].waitForExistence(timeout: 3),
                      "Midnight theme option should appear in settings")
    }

    func testShowCardNavigatesToEpisodeList() {
        navigateToCollectionBrowser()

        let dragnet = app.buttons["Dragnet: Big Crime"]
        guard dragnet.waitForExistence(timeout: 12) else {
            XCTFail("Show card button 'Dragnet: Big Crime' not found in mock data")
            return
        }
        dragnet.tap()

        guard app.navigationBars["Dragnet: Big Crime"].waitForExistence(timeout: 8) else {
            XCTFail("Did not navigate to ShowDetailView — nav bar 'Dragnet: Big Crime' not found")
            return
        }

        XCTAssertTrue(app.staticTexts["The Big Crime"].waitForExistence(timeout: 8),
                      "Episode 'The Big Crime' should appear after tapping show")
    }

    // MARK: - Playback

    /// Tapping an episode row must show the mini player.
    /// This verifies the full tap → play → currentEpisode set → MiniPlayerView appears chain.
    func testTappingEpisodeShowsMiniPlayer() {
        navigateToCollectionBrowser()

        let dragnet = app.buttons["Dragnet: Big Crime"]
        guard dragnet.waitForExistence(timeout: 12) else {
            XCTFail("Show card not found")
            return
        }
        dragnet.tap()

        guard app.staticTexts["The Big Crime"].waitForExistence(timeout: 10) else {
            XCTFail("Episode list did not load")
            return
        }

        app.staticTexts["The Big Crime"].firstMatch.tap()

        XCTAssertTrue(
            app.buttons["miniPlayer"].waitForExistence(timeout: 5),
            "Mini player should appear after tapping an episode"
        )
    }

    /// Tapping the mini player must open the full player sheet.
    func testMiniPlayerTapOpenFullPlayer() {
        navigateToCollectionBrowser()

        let dragnet = app.buttons["Dragnet: Big Crime"]
        guard dragnet.waitForExistence(timeout: 12) else {
            XCTFail("Show card not found")
            return
        }
        dragnet.tap()

        guard app.staticTexts["The Big Crime"].waitForExistence(timeout: 10) else {
            XCTFail("Episode list did not load")
            return
        }

        app.staticTexts["The Big Crime"].firstMatch.tap()

        let miniPlayer = app.buttons["miniPlayer"]
        guard miniPlayer.waitForExistence(timeout: 5) else {
            XCTFail("Mini player did not appear")
            return
        }
        miniPlayer.tap()

        // Full player has a Done button in the toolbar
        XCTAssertTrue(
            app.buttons["Done"].waitForExistence(timeout: 5),
            "Full player should open when tapping the mini player"
        )
    }

    /// Full player must show the sleep timer Set button.
    func testFullPlayerShowsSleepTimerSetButton() {
        navigateToCollectionBrowser()

        let dragnet = app.buttons["Dragnet: Big Crime"]
        guard dragnet.waitForExistence(timeout: 12) else {
            XCTFail("Show card not found")
            return
        }
        dragnet.tap()

        guard app.staticTexts["The Big Crime"].waitForExistence(timeout: 10) else {
            XCTFail("Episode list did not load")
            return
        }

        app.staticTexts["The Big Crime"].firstMatch.tap()

        let miniPlayer = app.buttons["miniPlayer"]
        guard miniPlayer.waitForExistence(timeout: 5) else {
            XCTFail("Mini player did not appear")
            return
        }
        miniPlayer.tap()

        XCTAssertTrue(
            app.buttons["Set"].waitForExistence(timeout: 5),
            "Full player should show 'Set' button for sleep timer"
        )
    }

    /// Full player must show all speed options.
    func testFullPlayerShowsSpeedOptions() {
        navigateToCollectionBrowser()

        let dragnet = app.buttons["Dragnet: Big Crime"]
        guard dragnet.waitForExistence(timeout: 12) else {
            XCTFail("Show card not found")
            return
        }
        dragnet.tap()

        guard app.staticTexts["The Big Crime"].waitForExistence(timeout: 10) else {
            XCTFail("Episode list did not load")
            return
        }

        app.staticTexts["The Big Crime"].firstMatch.tap()

        let miniPlayer = app.buttons["miniPlayer"]
        guard miniPlayer.waitForExistence(timeout: 5) else {
            XCTFail("Mini player did not appear")
            return
        }
        miniPlayer.tap()

        guard app.buttons["Done"].waitForExistence(timeout: 5) else {
            XCTFail("Full player did not open")
            return
        }

        XCTAssertTrue(app.buttons["1×"].waitForExistence(timeout: 3), "1× speed option should be visible")
        XCTAssertTrue(app.buttons["1.5×"].waitForExistence(timeout: 3), "1.5× speed option should be visible")
        XCTAssertTrue(app.buttons["2×"].waitForExistence(timeout: 3), "2× speed option should be visible")
    }
}
