//
//  NavigationUITests.swift
//  RecipeJoeUITests
//
//  UI tests for app navigation:
//  - Tab bar and tabs
//  - Settings sheet
//  - Filter bar
//  - Search tab (iOS 26 Liquid Glass)
//

import XCTest

/// UI tests for app navigation and structure
final class NavigationUITests: BaseUITestCase {

    // MARK: - Launch Tests

    @MainActor
    func testLaunchPerformance() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            app.launch()
        }
    }

    // MARK: - Tab Bar Tests

    @MainActor
    func testTabBarExists() throws {
        app.launch()
        try requireAuthentication()

        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.exists, "Tab bar should exist")
    }

    @MainActor
    func testAllTabsExist() throws {
        app.launch()
        try requireAuthentication()

        let tabBar = app.tabBars.firstMatch

        XCTAssertTrue(tabBar.buttons["Home"].exists, "Home tab should exist")
        XCTAssertTrue(tabBar.buttons["Add Recipe"].exists, "Add Recipe tab should exist")
        XCTAssertTrue(tabBar.buttons["Search"].exists, "Search tab should exist")
    }

    @MainActor
    func testHomeTabContent() throws {
        app.launch()
        try requireAuthentication()

        // Home tab should be selected by default
        XCTAssertTrue(app.navigationBars["RecipeJoe"].exists, "RecipeJoe navigation bar should be visible on Home tab")

        // Check for empty state OR recipe list
        let emptyState = app.staticTexts["No Recipes Yet"]
        let recipeList = app.collectionViews["recipeList"]
        XCTAssertTrue(emptyState.waitForExistence(timeout: TestConfig.standardTimeout) || recipeList.waitForExistence(timeout: TestConfig.standardTimeout),
                      "Home should show either empty state or recipe list")
    }

    @MainActor
    func testAddRecipeTabContent() throws {
        app.launch()
        try requireAuthentication()

        navigateToAddRecipe()

        // Wait for view to load
        let urlTextField = app.textFields["urlTextField"]
        XCTAssertTrue(urlTextField.waitForExistence(timeout: TestConfig.standardTimeout), "URL text field should exist")

        let actionButton = app.buttons["actionButton"]
        XCTAssertTrue(actionButton.waitForExistence(timeout: TestConfig.standardTimeout), "Action button should exist")
    }

    @MainActor
    func testAddRecipeButtonStateChange() throws {
        app.launch()
        try requireAuthentication()

        navigateToAddRecipe()

        let urlTextField = app.textFields["urlTextField"]
        let actionButton = app.buttons["actionButton"]

        XCTAssertTrue(actionButton.exists, "Action button should exist")

        // Enter URL
        urlTextField.tap()
        urlTextField.typeText("https://www.example.com/recipe")

        XCTAssertTrue(actionButton.exists, "Action button should still exist after entering URL")

        // Clear the text field
        urlTextField.tap()
        if let value = urlTextField.value as? String, !value.isEmpty {
            let deleteString = String(repeating: XCUIKeyboardKey.delete.rawValue, count: value.count)
            urlTextField.typeText(deleteString)
        }

        XCTAssertTrue(actionButton.exists, "Action button should exist after clearing URL")
    }

    // MARK: - Search Tab Tests (iOS 26 Liquid Glass)

    @MainActor
    func testSearchTabContent() throws {
        app.launch()
        try requireAuthentication()

        navigateToSearch()

        XCTAssertTrue(app.navigationBars["Search"].exists, "Search navigation bar should be visible")
        XCTAssertTrue(app.staticTexts["Search Recipes"].exists, "Search Recipes text should be visible")
        XCTAssertTrue(app.staticTexts["Search by name, category, cuisine, or ingredients"].exists, "Search instruction text should be visible")
    }

    @MainActor
    func testSearchTabHasSearchBar() throws {
        app.launch()
        try requireAuthentication()

        navigateToSearch()

        let searchField = app.searchFields.firstMatch
        XCTAssertTrue(searchField.exists, "Search field should exist in Search tab")
    }

    @MainActor
    func testLiquidGlassSearchTabIsSeparated() throws {
        app.launch()
        try requireAuthentication()

        let tabBar = app.tabBars.firstMatch
        let searchTab = tabBar.buttons["Search"]

        XCTAssertTrue(searchTab.exists, "Liquid Glass search tab should exist")
        XCTAssertTrue(searchTab.isHittable, "Search tab should be tappable")
    }

    // MARK: - Settings Tests

    @MainActor
    func testSettingsButtonExists() throws {
        app.launch()
        try requireAuthentication()

        let settingsButton = app.buttons["settingsButton"]
        XCTAssertTrue(settingsButton.waitForExistence(timeout: TestConfig.standardTimeout), "Settings button should exist in Home toolbar")
    }

    @MainActor
    func testSettingsButtonOpensSheet() throws {
        app.launch()
        try requireAuthentication()

        openSettings()

        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: TestConfig.standardTimeout), "Settings navigation bar should appear")
    }

    @MainActor
    func testSettingsShowsVersion() throws {
        app.launch()
        try requireAuthentication()

        openSettings()

        XCTAssertTrue(app.staticTexts["Version"].waitForExistence(timeout: TestConfig.standardTimeout), "Version label should exist in Settings")
    }

    @MainActor
    func testSettingsCanBeDismissed() throws {
        app.launch()
        try requireAuthentication()

        openSettings()
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: TestConfig.standardTimeout), "Settings should be open")

        // Swipe down to dismiss
        app.swipeDown()

        // Wait for sheet to dismiss
        let homeNavBar = app.navigationBars["RecipeJoe"]
        XCTAssertTrue(homeNavBar.waitForExistence(timeout: TestConfig.standardTimeout), "Should be back on Home screen after dismissing Settings")
    }

    // MARK: - Filter Bar Tests

    @MainActor
    func testFilterBarAppearsWithRecipes() throws {
        app.launch()
        try requireAuthentication()

        XCTAssertTrue(app.navigationBars["RecipeJoe"].waitForExistence(timeout: TestConfig.standardTimeout), "Home screen should load")

        let recipeList = app.collectionViews["recipeList"]
        let emptyState = app.staticTexts["No Recipes Yet"]

        let hasRecipes = recipeList.waitForExistence(timeout: TestConfig.authTimeout)
        let isEmpty = emptyState.exists

        if hasRecipes {
            let filterBar = app.scrollViews["filterBar"]
            XCTAssertTrue(filterBar.waitForExistence(timeout: TestConfig.standardTimeout), "Filter bar should appear when recipes exist")
            XCTAssertTrue(app.buttons["All"].exists || app.staticTexts["All"].exists, "All filter should be visible")
        } else if isEmpty {
            let filterBar = app.scrollViews["filterBar"]
            XCTAssertFalse(filterBar.exists, "Filter bar should not appear when no recipes exist")
        }
    }

    @MainActor
    func testFilterBarHasTimeFilters() throws {
        app.launch()
        try requireAuthentication()

        XCTAssertTrue(app.navigationBars["RecipeJoe"].waitForExistence(timeout: TestConfig.standardTimeout), "Home screen should load")

        let recipeList = app.collectionViews["recipeList"]
        guard recipeList.waitForExistence(timeout: TestConfig.authTimeout) else {
            throw XCTSkip("No recipes available to test filter bar")
        }

        let filterBar = app.scrollViews["filterBar"]
        XCTAssertTrue(filterBar.waitForExistence(timeout: TestConfig.standardTimeout), "Filter bar should exist")

        let allButton = filterBar.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'All' OR label CONTAINS[c] 'Alli'")).firstMatch
        XCTAssertTrue(allButton.exists, "All time filter should exist")
    }
}
