import XCTest

final class NavigationTests: XCTestCase {

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

    private func navigateToSidebarIfNeeded() {
        let backButton = app.navigationBars.buttons["Radio Player"]
        if backButton.waitForExistence(timeout: 3) {
            backButton.tap()
        }
    }

    func testCollectionBrowserShowsTitle() {
        // The collection browser should have a navigation title visible in the nav bar.
        // Default selection is "All Shows" (the .oldTimeRadio catch-all).
        let navBar = app.navigationBars["All Shows"]
        if !navBar.waitForExistence(timeout: 3) {
            // Might be on sidebar — tap "All Shows" to navigate
            navigateToSidebarIfNeeded()
            let row = app.staticTexts["All Shows"]
            guard row.waitForExistence(timeout: 5) else {
                XCTFail("Could not find All Shows row in sidebar")
                return
            }
            row.tap()
        }
        let browser = app.navigationBars["All Shows"]
        XCTAssertTrue(browser.waitForExistence(timeout: 5),
                      "All Shows navigation title should appear in collection browser")
    }

    func testOldTimeRadioCollectionLoads() {
        // Mock API returns "Dragnet: Big Crime" and "The Adventurer"
        // Navigate to collection browser and verify shows appear
        let dragnetTitle = app.staticTexts["Dragnet: Big Crime"]
        if dragnetTitle.waitForExistence(timeout: 10) {
            // Already on collection browser with shows loaded
            return
        }

        // Try tapping from sidebar
        navigateToSidebarIfNeeded()
        let row = app.staticTexts["Old Time Radio"]
        guard row.waitForExistence(timeout: 5) else {
            XCTFail("Old Time Radio row not found in sidebar")
            return
        }
        row.tap()

        XCTAssertTrue(
            app.staticTexts["Dragnet: Big Crime"].waitForExistence(timeout: 10),
            "Show cards from mock data should appear in the collection browser"
        )
    }

    func testSettingsGearIsAccessible() {
        navigateToSidebarIfNeeded()
        let settings = app.buttons["Settings"]
        XCTAssertTrue(settings.waitForExistence(timeout: 5), "Settings gear button should be accessible in sidebar")
    }

    func testSettingsSheetOpens() {
        navigateToSidebarIfNeeded()
        let settings = app.buttons["Settings"]
        guard settings.waitForExistence(timeout: 5) else {
            XCTFail("Settings button not found")
            return
        }
        settings.tap()

        XCTAssertTrue(
            app.navigationBars["Settings"].waitForExistence(timeout: 3),
            "Settings sheet should open"
        )
    }

    func testGenreSectionsVisibleInSidebar() {
        navigateToSidebarIfNeeded()
        XCTAssertTrue(app.staticTexts["Drama"].waitForExistence(timeout: 5),
                      "Drama genre row should be visible in sidebar")
        XCTAssertTrue(app.staticTexts["Comedy"].waitForExistence(timeout: 3),
                      "Comedy genre row should be visible in sidebar")
        XCTAssertTrue(app.staticTexts["Mystery & Detective"].waitForExistence(timeout: 3),
                      "Mystery & Detective genre row should be visible in sidebar")
    }

    func testTappingGenreNavigatesToBrowser() {
        navigateToSidebarIfNeeded()
        let comedy = app.staticTexts["Comedy"]
        guard comedy.waitForExistence(timeout: 5) else {
            XCTFail("Comedy row not found in sidebar")
            return
        }
        comedy.tap()
        XCTAssertTrue(
            app.navigationBars["Comedy"].waitForExistence(timeout: 5),
            "Tapping Comedy should open its collection browser"
        )
    }
}
