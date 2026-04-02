import XCTest

final class AppLaunchTests: XCTestCase {

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

    func testAppLaunchesSuccessfully() {
        XCTAssertTrue(app.state == .runningForeground)
    }

    func testNavigationBarVisible() {
        // The navigation bar should always be visible (either showing collection
        // title or sidebar). The back button to "Radio Player" confirms we're
        // in compact NavigationSplitView content column.
        let navBar = app.navigationBars.firstMatch
        XCTAssertTrue(navBar.waitForExistence(timeout: 5), "A navigation bar should be visible")
    }

    func testSidebarReachableViaBackButton() {
        // iPhone: back button labeled "Radio Player"
        if app.navigationBars.buttons["Radio Player"].waitForExistence(timeout: 2) {
            app.navigationBars.buttons["Radio Player"].tap()
        }
        // iPad portrait: system sidebar toggle
        else if app.buttons["Show Sidebar"].waitForExistence(timeout: 2) {
            app.buttons["Show Sidebar"].tap()
        }
        // Wide iPad: sidebar already visible, nothing to tap

        XCTAssertTrue(app.staticTexts["All Shows"].waitForExistence(timeout: 5),
                      "All Shows should be visible in sidebar")
    }

    func testLibraryRowVisible() {
        // Navigate to sidebar (handles iPhone back button and iPad Show Sidebar toggle)
        if app.navigationBars.buttons["Radio Player"].waitForExistence(timeout: 2) {
            app.navigationBars.buttons["Radio Player"].tap()
        } else if app.buttons["Show Sidebar"].waitForExistence(timeout: 2) {
            app.buttons["Show Sidebar"].tap()
        }

        // Library is near the bottom — scroll sidebar to bring it into the accessibility tree
        let sidebar = app.tables.firstMatch
        if sidebar.waitForExistence(timeout: 3) {
            sidebar.swipeUp()
        }

        XCTAssertTrue(app.staticTexts["Library"].waitForExistence(timeout: 5),
                      "Library row should be visible in sidebar")
    }
}
