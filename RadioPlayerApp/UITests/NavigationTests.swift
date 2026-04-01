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
        // The collection browser should have a navigation title visible in the nav bar
        // After the .task fix, the nav title is always set regardless of viewModel state
        let navBar = app.navigationBars["Old Time Radio"]
        if !navBar.waitForExistence(timeout: 3) {
            // Might be on sidebar — tap Old Time Radio to navigate
            navigateToSidebarIfNeeded()
            let row = app.staticTexts["Old Time Radio"]
            guard row.waitForExistence(timeout: 5) else {
                XCTFail("Could not find Old Time Radio row in sidebar")
                return
            }
            row.tap()
        }
        let browser = app.navigationBars["Old Time Radio"]
        XCTAssertTrue(browser.waitForExistence(timeout: 5),
                      "Old Time Radio navigation title should appear in collection browser")
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
}
