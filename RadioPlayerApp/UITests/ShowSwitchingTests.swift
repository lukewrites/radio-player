import XCTest

/// Regression tests for the stale-state bug where switching between shows
/// kept the previous show's thumbnail and episode list visible.
final class ShowSwitchingTests: XCTestCase {

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

    private func navigateToAllShows() {
        navigateToSidebarIfNeeded()
        let row = app.staticTexts["All Shows"]
        if row.waitForExistence(timeout: 3) {
            row.tap()
        }
    }

    // MARK: - Tests

    /// Tapping a second show after viewing the first must update the navigation title.
    /// Regression: ShowDetailView reused @State viewModel/show when SwiftUI kept the
    /// same view identity, so the title stayed on Show A while navigating to Show B.
    func testSwitchingShowsUpdatesNavigationTitle() {
        navigateToAllShows()

        // Open first show
        let dragnet = app.buttons["Dragnet: Big Crime"]
        guard dragnet.waitForExistence(timeout: 10) else {
            XCTFail("Dragnet show card not found")
            return
        }
        dragnet.tap()
        XCTAssertTrue(
            app.navigationBars["Dragnet: Big Crime"].waitForExistence(timeout: 8),
            "Navigation title should be 'Dragnet: Big Crime' after tapping first show"
        )

        // Go back and open a different show
        let backButton = app.navigationBars.buttons.firstMatch
        backButton.tap()

        let adventurer = app.buttons["The Adventurer"]
        guard adventurer.waitForExistence(timeout: 5) else {
            XCTFail("The Adventurer show card not found")
            return
        }
        adventurer.tap()

        XCTAssertTrue(
            app.navigationBars["The Adventurer"].waitForExistence(timeout: 8),
            "Navigation title must update to 'The Adventurer' — stale title from previous show is the regression"
        )
    }

    /// After switching shows, the episode list must reload for the new show.
    /// Regression: stale viewModel showed the first show's episodes even after
    /// navigating to a different show.
    func testSwitchingShowsLoadsEpisodes() {
        navigateToAllShows()

        let dragnet = app.buttons["Dragnet: Big Crime"]
        guard dragnet.waitForExistence(timeout: 10) else {
            XCTFail("Dragnet show card not found")
            return
        }
        dragnet.tap()

        // Wait for episodes to actually load on first show
        XCTAssertTrue(
            app.staticTexts["The Big Crime"].waitForExistence(timeout: 10),
            "Episodes should load for Dragnet"
        )

        // Navigate back and open second show
        app.navigationBars.buttons.firstMatch.tap()

        let adventurer = app.buttons["The Adventurer"]
        guard adventurer.waitForExistence(timeout: 5) else {
            XCTFail("The Adventurer show card not found")
            return
        }
        adventurer.tap()

        // Episodes should reload for The Adventurer (mock returns same episodes)
        XCTAssertTrue(
            app.staticTexts["The Big Crime"].waitForExistence(timeout: 10),
            "Episode list should load for the new show"
        )
        XCTAssertTrue(
            app.navigationBars["The Adventurer"].exists,
            "Navigation title must be The Adventurer, not the previous show"
        )
    }

    // MARK: - Category switching

    /// Tapping a different sidebar category must update the collection browser title.
    /// Regression: CollectionBrowserView reused stale @State viewModel when collection changed.
    func testSwitchingCategoryUpdatesTitle() {
        navigateToSidebarIfNeeded()

        let comedy = app.staticTexts["Comedy"]
        guard comedy.waitForExistence(timeout: 5) else {
            XCTFail("Comedy row not found in sidebar")
            return
        }
        comedy.tap()

        XCTAssertTrue(
            app.navigationBars["Comedy"].waitForExistence(timeout: 8),
            "Navigation title must update to 'Comedy' when tapping Comedy in sidebar"
        )
    }

    /// After switching categories, the show grid must reload for the new collection.
    func testSwitchingCategoryLoadsShows() {
        navigateToSidebarIfNeeded()

        let comedy = app.staticTexts["Comedy"]
        guard comedy.waitForExistence(timeout: 5) else {
            XCTFail("Comedy row not found in sidebar")
            return
        }
        comedy.tap()

        // Mock data returns same 2 shows for any collection query
        XCTAssertTrue(
            app.staticTexts["Dragnet: Big Crime"].waitForExistence(timeout: 10),
            "Shows should load when navigating to Comedy collection"
        )
    }

    /// Switching from one category back to another must reload, not show stale content.
    func testSwitchingCategoryTwiceUpdatesTitle() {
        navigateToSidebarIfNeeded()

        let comedy = app.staticTexts["Comedy"]
        guard comedy.waitForExistence(timeout: 5) else {
            XCTFail("Comedy row not found")
            return
        }
        comedy.tap()
        XCTAssertTrue(app.navigationBars["Comedy"].waitForExistence(timeout: 5))

        navigateToSidebarIfNeeded()

        let drama = app.staticTexts["Drama"]
        guard drama.waitForExistence(timeout: 3) else {
            XCTFail("Drama row not found")
            return
        }
        drama.tap()

        XCTAssertTrue(
            app.navigationBars["Drama"].waitForExistence(timeout: 8),
            "Title must update to Drama after switching from Comedy"
        )
    }
}
