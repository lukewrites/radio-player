import XCTest

final class LibraryTests: XCTestCase {

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

    // MARK: - Helpers

    private func navigateToSidebarIfNeeded() {
        let backButton = app.navigationBars.buttons["Radio Player"]
        if backButton.waitForExistence(timeout: 3) {
            backButton.tap()
        }
    }

    private func navigateToLibrary() {
        navigateToSidebarIfNeeded()
        let library = app.staticTexts["Library"]
        if library.waitForExistence(timeout: 5) {
            library.tap()
        }
    }

    // MARK: - Tests

    func testLibraryRowVisibleInSidebar() {
        navigateToSidebarIfNeeded()
        XCTAssertTrue(
            app.staticTexts["Library"].waitForExistence(timeout: 5),
            "Library row should be visible in sidebar"
        )
    }

    func testLibraryOpensWithCorrectTitle() {
        navigateToLibrary()
        XCTAssertTrue(
            app.navigationBars["Library"].waitForExistence(timeout: 5),
            "Library navigation title should be 'Library'"
        )
    }

    func testLibraryHasThreeTabs() {
        navigateToLibrary()
        XCTAssertTrue(app.buttons["Continue"].waitForExistence(timeout: 5),
                      "Library should have a 'Continue' tab")
        XCTAssertTrue(app.buttons["Completed"].waitForExistence(timeout: 3),
                      "Library should have a 'Completed' tab")
        XCTAssertTrue(app.buttons["Downloads"].waitForExistence(timeout: 3),
                      "Library should have a 'Downloads' tab")
    }

    func testLibraryContinueTabShowsEmptyState() {
        navigateToLibrary()
        // In a fresh UI test session with no playback, Continue should show the empty state
        XCTAssertTrue(
            app.staticTexts["Nothing In Progress"].waitForExistence(timeout: 5),
            "Continue tab should show empty state when no episodes are in progress"
        )
    }

    func testLibraryCompletedTabShowsEmptyState() {
        navigateToLibrary()
        app.buttons["Completed"].tap()
        XCTAssertTrue(
            app.staticTexts["Nothing Completed"].waitForExistence(timeout: 5),
            "Completed tab should show empty state when no episodes are completed"
        )
    }

    func testLibraryDownloadsTabShowsEmptyState() {
        navigateToLibrary()
        app.buttons["Downloads"].tap()
        XCTAssertTrue(
            app.staticTexts["No Downloads"].waitForExistence(timeout: 5),
            "Downloads tab should show empty state when nothing is downloaded"
        )
    }

    func testLibraryTabSwitching() {
        navigateToLibrary()

        // Switch to Completed
        app.buttons["Completed"].tap()
        XCTAssertTrue(
            app.staticTexts["Nothing Completed"].waitForExistence(timeout: 3),
            "Switching to Completed tab should show its content"
        )

        // Switch to Downloads
        app.buttons["Downloads"].tap()
        XCTAssertTrue(
            app.staticTexts["No Downloads"].waitForExistence(timeout: 3),
            "Switching to Downloads tab should show its content"
        )

        // Switch back to Continue
        app.buttons["Continue"].tap()
        XCTAssertTrue(
            app.staticTexts["Nothing In Progress"].waitForExistence(timeout: 3),
            "Switching back to Continue tab should show its content"
        )
    }
}
