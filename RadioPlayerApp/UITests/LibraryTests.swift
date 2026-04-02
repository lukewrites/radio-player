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
        // iPhone: tap the "Radio Player" back button
        if app.navigationBars.buttons["Radio Player"].waitForExistence(timeout: 2) {
            app.navigationBars.buttons["Radio Player"].tap()
            return
        }
        // iPad portrait: tap the "Show Sidebar" toggle the split view adds automatically
        if app.buttons["Show Sidebar"].waitForExistence(timeout: 2) {
            app.buttons["Show Sidebar"].tap()
            return
        }
        // Wide iPad landscape: sidebar is always visible, nothing to do
    }

    private func navigateToLibrary() {
        navigateToSidebarIfNeeded()
        let library = app.staticTexts["Library"]
        guard library.waitForExistence(timeout: 5) else { return }
        library.tap()
    }

    // MARK: - Tests

    func testLibraryRowVisibleInSidebar() {
        navigateToSidebarIfNeeded()
        XCTAssertTrue(app.staticTexts["Library"].waitForExistence(timeout: 5),
                      "Library row should be visible in sidebar")
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
        guard app.navigationBars["Library"].waitForExistence(timeout: 5) else {
            XCTFail("Library did not open"); return
        }
        // Library uses a segmented Picker — options appear as segmented control buttons
        let picker = app.segmentedControls.firstMatch
        XCTAssertTrue(picker.waitForExistence(timeout: 5), "Segmented picker should be visible")
        XCTAssertTrue(picker.buttons["Continue"].exists,  "Library should have a 'Continue' tab")
        XCTAssertTrue(picker.buttons["Completed"].exists, "Library should have a 'Completed' tab")
        XCTAssertTrue(picker.buttons["Downloads"].exists, "Library should have a 'Downloads' tab")
    }

    func testLibraryContinueTabShowsEmptyState() {
        navigateToLibrary()
        guard app.navigationBars["Library"].waitForExistence(timeout: 5) else {
            XCTFail("Library did not open"); return
        }
        XCTAssertTrue(
            app.staticTexts["Nothing In Progress"].waitForExistence(timeout: 5),
            "Continue tab should show empty state when no episodes are in progress"
        )
    }

    func testLibraryCompletedTabShowsEmptyState() {
        navigateToLibrary()
        guard app.navigationBars["Library"].waitForExistence(timeout: 5) else {
            XCTFail("Library did not open"); return
        }
        app.segmentedControls.firstMatch.buttons["Completed"].tap()
        XCTAssertTrue(
            app.staticTexts["Nothing Completed"].waitForExistence(timeout: 5),
            "Completed tab should show empty state when no episodes are completed"
        )
    }

    func testLibraryDownloadsTabShowsEmptyState() {
        navigateToLibrary()
        guard app.navigationBars["Library"].waitForExistence(timeout: 5) else {
            XCTFail("Library did not open"); return
        }
        app.segmentedControls.firstMatch.buttons["Downloads"].tap()
        XCTAssertTrue(
            app.staticTexts["No Downloads"].waitForExistence(timeout: 5),
            "Downloads tab should show empty state when nothing is downloaded"
        )
    }

    func testLibraryTabSwitching() {
        navigateToLibrary()
        guard app.navigationBars["Library"].waitForExistence(timeout: 5) else {
            XCTFail("Library did not open"); return
        }
        let picker = app.segmentedControls.firstMatch

        picker.buttons["Completed"].tap()
        XCTAssertTrue(app.staticTexts["Nothing Completed"].waitForExistence(timeout: 3))

        picker.buttons["Downloads"].tap()
        XCTAssertTrue(app.staticTexts["No Downloads"].waitForExistence(timeout: 3))

        picker.buttons["Continue"].tap()
        XCTAssertTrue(app.staticTexts["Nothing In Progress"].waitForExistence(timeout: 3))
    }
}
