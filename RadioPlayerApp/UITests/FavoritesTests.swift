import XCTest

final class FavoritesTests: XCTestCase {

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

    private func navigateToFavorites() {
        navigateToSidebarIfNeeded()
        let row = app.staticTexts["Favorites"]
        if row.waitForExistence(timeout: 5) {
            row.tap()
        }
    }

    private func navigateToAllShows() {
        navigateToSidebarIfNeeded()
        let row = app.staticTexts["All Shows"]
        if row.waitForExistence(timeout: 3) {
            row.tap()
        }
    }

    // MARK: - Tests

    func testFavoritesRowVisibleInSidebar() {
        navigateToSidebarIfNeeded()
        XCTAssertTrue(
            app.staticTexts["Favorites"].waitForExistence(timeout: 5),
            "Favorites row should be visible in sidebar"
        )
    }

    /// Favorites with no starred shows must show an empty state, not crash or show stale data.
    func testFavoritesEmptyStateShown() {
        navigateToFavorites()
        XCTAssertTrue(
            app.staticTexts["No Favorites"].waitForExistence(timeout: 5),
            "Empty state 'No Favorites' should appear when no shows are favorited"
        )
    }

    /// Starring a show from its detail view must make it appear in Favorites.
    func testStarringShowAddsItToFavorites() {
        navigateToAllShows()

        let dragnet = app.buttons["Dragnet: Big Crime"]
        guard dragnet.waitForExistence(timeout: 10) else {
            XCTFail("Dragnet show card not found")
            return
        }
        dragnet.tap()

        // Wait for show detail to load, then tap the star button
        guard app.navigationBars["Dragnet: Big Crime"].waitForExistence(timeout: 8) else {
            XCTFail("Did not navigate to show detail")
            return
        }

        let starButton = app.buttons["Add to Favorites"]
        guard starButton.waitForExistence(timeout: 5) else {
            // Already favorited from a previous test run — that's fine, the test below still works
            let alreadyFavorited = app.buttons["Remove from Favorites"]
            if !alreadyFavorited.waitForExistence(timeout: 2) {
                XCTFail("Neither Add nor Remove Favorites button found")
                return
            }
            // Already starred — navigate to Favorites and verify it's there
            navigateToSidebarIfNeeded()
            navigateToFavorites()
            XCTAssertTrue(
                app.staticTexts["Dragnet: Big Crime"].waitForExistence(timeout: 5),
                "Favorited show should appear in Favorites"
            )
            return
        }
        starButton.tap()

        // Navigate to Favorites and verify the show appears
        navigateToSidebarIfNeeded()
        navigateToFavorites()

        XCTAssertTrue(
            app.staticTexts["Dragnet: Big Crime"].waitForExistence(timeout: 5),
            "Show should appear in Favorites after tapping the star"
        )

        // Cleanup: un-star the show so this test is repeatable
        app.staticTexts["Dragnet: Big Crime"].firstMatch.tap()
        if app.buttons["Remove from Favorites"].waitForExistence(timeout: 5) {
            app.buttons["Remove from Favorites"].tap()
        }
    }
}
