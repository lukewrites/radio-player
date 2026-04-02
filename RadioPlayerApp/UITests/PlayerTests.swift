import XCTest

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
        // If already on the All Shows collection browser, nothing to do.
        // The app launches with selectedCollection = .oldTimeRadio, so compact
        // NavigationSplitView may already be showing the collection browser.
        // Navigating back then re-tapping an already-selected sidebar item does
        // not trigger re-navigation in compact mode, so we skip the round-trip.
        if app.navigationBars["All Shows"].waitForExistence(timeout: 3) {
            return
        }
        // Otherwise we are on the sidebar — tap All Shows to navigate there.
        let row = app.staticTexts["All Shows"]
        if row.waitForExistence(timeout: 5) {
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
        // Navigate to collection browser and tap a show
        navigateToCollectionBrowser()

        // Show cards have accessibilityLabel set to the show title — use buttons[]
        let dragnet = app.buttons["Dragnet: Big Crime"]
        guard dragnet.waitForExistence(timeout: 12) else {
            XCTFail("Show card button 'Dragnet: Big Crime' not found in mock data")
            return
        }
        dragnet.tap()

        // Wait for ShowDetailView navigation bar to confirm navigation succeeded
        guard app.navigationBars["Dragnet: Big Crime"].waitForExistence(timeout: 8) else {
            XCTFail("Did not navigate to ShowDetailView — nav bar 'Dragnet: Big Crime' not found")
            return
        }

        // Episode list should appear (mock metadata has 2 MP3 files)
        let episode = app.staticTexts["The Big Crime"]
        XCTAssertTrue(episode.waitForExistence(timeout: 8),
                      "Episode 'The Big Crime' should appear after tapping show")
    }
}
