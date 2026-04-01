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
        // On iPhone compact, tap back to reach the sidebar (CollectionListView)
        let backButton = app.navigationBars.buttons["Radio Player"]
        guard backButton.waitForExistence(timeout: 5) else {
            // Already on the sidebar or wide layout — look for the list directly
            let oldTimeRadio = app.staticTexts["Old Time Radio"]
            XCTAssertTrue(oldTimeRadio.waitForExistence(timeout: 5),
                          "Old Time Radio should be visible in sidebar")
            return
        }
        backButton.tap()

        let oldTimeRadio = app.staticTexts["Old Time Radio"]
        XCTAssertTrue(oldTimeRadio.waitForExistence(timeout: 5),
                      "Old Time Radio should be visible after navigating to sidebar")
    }

    func testLibraryRowVisible() {
        // Navigate back to sidebar if needed
        let backButton = app.navigationBars.buttons["Radio Player"]
        if backButton.waitForExistence(timeout: 3) {
            backButton.tap()
        }

        let library = app.staticTexts["Library"]
        XCTAssertTrue(library.waitForExistence(timeout: 5), "Library row should be visible in sidebar")
    }
}
