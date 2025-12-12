//
//  RecipeJoeUITests.swift
//  RecipeJoeUITests
//
//  Created by Oliver Staub on 23.11.2025.
//

import XCTest

final class RecipeJoeUITests: XCTestCase {

    /// Configured app instance with English locale for consistent UI tests
    var app: XCUIApplication!

    override func setUpWithError() throws {
        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // Configure app to launch in English for consistent UI tests
        app = XCUIApplication()

        // Set system locale to English
        app.launchArguments += ["-AppleLanguages", "(en)"]
        app.launchArguments += ["-AppleLocale", "en_US"]

        // Reset the app's internal language setting to English via UserDefaults
        // This overrides the app's own language preference stored in UserDefaults
        app.launchArguments += ["-appLanguage", "en"]
    }

    override func tearDownWithError() throws {
        app = nil
    }

    @MainActor
    func testExample() throws {
        // UI tests must launch the application that they test.
        app.launch()

        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

    @MainActor
    func testLaunchPerformance() throws {
        // This measures how long it takes to launch your application.
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            app.launch()
        }
    }

    // MARK: - Tab Bar Tests

    @MainActor
    func testTabBarExists() throws {
        app.launch()

        // Verify tab bar exists
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.exists, "Tab bar should exist")
    }

    @MainActor
    func testAllTabsExist() throws {
        app.launch()

        let tabBar = app.tabBars.firstMatch

        // Verify all three tabs exist (Home, Add Recipe, and Search with liquid glass)
        XCTAssertTrue(tabBar.buttons["Home"].exists, "Home tab should exist")
        XCTAssertTrue(tabBar.buttons["Add Recipe"].exists, "Add Recipe tab should exist")
        XCTAssertTrue(tabBar.buttons["Search"].exists, "Search tab should exist (separated with liquid glass effect)")
    }

    @MainActor
    func testHomeTabContent() throws {
        app.launch()

        // Home tab should be selected by default
        XCTAssertTrue(app.navigationBars["RecipeJoe"].exists, "RecipeJoe navigation bar should be visible on Home tab")
        // Check for empty state OR recipe list (depends on whether recipes exist)
        let emptyState = app.staticTexts["No Recipes Yet"]
        let recipeList = app.collectionViews["recipeList"]
        XCTAssertTrue(emptyState.waitForExistence(timeout: 5) || recipeList.waitForExistence(timeout: 5),
                      "Home should show either empty state or recipe list")
    }

    @MainActor
    func testAddRecipeTabContent() throws {
        app.launch()

        // Switch to Add Recipe tab
        let addRecipeTab = app.tabBars.buttons["Add Recipe"]
        XCTAssertTrue(addRecipeTab.waitForExistence(timeout: 5), "Add Recipe tab should exist")
        addRecipeTab.tap()

        // Wait a moment for the view to load
        Thread.sleep(forTimeInterval: 1)

        // Verify URL text field exists (most important element)
        let urlTextField = app.textFields["urlTextField"]
        XCTAssertTrue(urlTextField.waitForExistence(timeout: 5), "URL text field should exist")

        // Verify action button exists
        let actionButton = app.buttons["actionButton"]
        XCTAssertTrue(actionButton.waitForExistence(timeout: 5), "Action button should exist")
    }

    @MainActor
    func testAddRecipeButtonStateChange() throws {
        app.launch()

        // Switch to Add Recipe tab
        app.tabBars.buttons["Add Recipe"].tap()

        // Get references to UI elements
        let urlTextField = app.textFields["urlTextField"]
        let actionButton = app.buttons["actionButton"]

        // Verify button exists in default state (plus icon)
        XCTAssertTrue(actionButton.exists, "Action button should exist")

        // Tap text field and enter URL
        urlTextField.tap()
        urlTextField.typeText("https://www.example.com/recipe")

        // Button should still exist (now in send/go state)
        XCTAssertTrue(actionButton.exists, "Action button should still exist after entering URL")

        // Clear the text field
        urlTextField.tap()
        // Select all and delete (clearing the field)
        if let value = urlTextField.value as? String, !value.isEmpty {
            let deleteString = String(repeating: XCUIKeyboardKey.delete.rawValue, count: value.count)
            urlTextField.typeText(deleteString)
        }

        // Button should still exist (back to plus icon state)
        XCTAssertTrue(actionButton.exists, "Action button should exist after clearing URL")
    }

    // MARK: - Search Tab Tests (iOS 26 Liquid Glass)

    @MainActor
    func testSearchTabContent() throws {
        app.launch()

        // Switch to Search tab
        app.tabBars.buttons["Search"].tap()

        // Verify Search view content
        XCTAssertTrue(app.navigationBars["Search"].exists, "Search navigation bar should be visible")
        XCTAssertTrue(app.staticTexts["Search Recipes"].exists, "Search Recipes text should be visible")
        XCTAssertTrue(app.staticTexts["Search by name, category, cuisine, or ingredients"].exists, "Search instruction text should be visible")
    }

    @MainActor
    func testSearchTabHasSearchBar() throws {
        app.launch()

        // Switch to Search tab
        app.tabBars.buttons["Search"].tap()

        // Verify search field exists (iOS 26 searchable modifier)
        let searchField = app.searchFields.firstMatch
        XCTAssertTrue(searchField.exists, "Search field should exist in Search tab")
    }

    @MainActor
    func testLiquidGlassSearchTabIsSeparated() throws {
        app.launch()

        let tabBar = app.tabBars.firstMatch

        // The Search tab should exist as a separate button with role: .search
        // In iOS 26 Liquid Glass, this appears separated from other tabs
        let searchTab = tabBar.buttons["Search"]
        XCTAssertTrue(searchTab.exists, "Liquid Glass search tab should exist")
        XCTAssertTrue(searchTab.isHittable, "Search tab should be tappable")
    }

    // MARK: - Settings Tests

    @MainActor
    func testSettingsButtonExists() throws {
        app.launch()

        // Settings button should be in the Home tab toolbar
        let settingsButton = app.buttons["settingsButton"]
        XCTAssertTrue(settingsButton.waitForExistence(timeout: 5), "Settings button should exist in Home toolbar")
    }

    @MainActor
    func testSettingsButtonOpensSheet() throws {
        app.launch()

        // Tap settings button
        let settingsButton = app.buttons["settingsButton"]
        XCTAssertTrue(settingsButton.waitForExistence(timeout: 5), "Settings button should exist")
        settingsButton.tap()

        // Verify Settings view appears
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 5), "Settings navigation bar should appear")
    }

    @MainActor
    func testSettingsShowsVersion() throws {
        app.launch()

        // Open settings
        app.buttons["settingsButton"].tap()

        // Verify version info exists
        XCTAssertTrue(app.staticTexts["Version"].waitForExistence(timeout: 5), "Version label should exist in Settings")
    }

    @MainActor
    func testSettingsCanBeDismissed() throws {
        app.launch()

        // Open settings
        app.buttons["settingsButton"].tap()
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 5), "Settings should be open")

        // Swipe down to dismiss
        app.swipeDown()

        // Wait for sheet to dismiss and verify we're back on Home
        Thread.sleep(forTimeInterval: 1)
        XCTAssertTrue(app.navigationBars["RecipeJoe"].exists, "Should be back on Home screen after dismissing Settings")
    }

    // MARK: - Filter Bar Tests

    @MainActor
    func testFilterBarAppearsWithRecipes() throws {
        app.launch()

        // Wait for the home screen to load
        XCTAssertTrue(app.navigationBars["RecipeJoe"].waitForExistence(timeout: 5), "Home screen should load")

        // Check if we have recipes (recipe list exists) or empty state
        let recipeList = app.collectionViews["recipeList"]
        let emptyState = app.staticTexts["No Recipes Yet"]

        // Wait for either state
        let hasRecipes = recipeList.waitForExistence(timeout: 10)
        let isEmpty = emptyState.exists

        if hasRecipes {
            // If recipes exist, filter bar should be visible
            let filterBar = app.scrollViews["filterBar"]
            XCTAssertTrue(filterBar.waitForExistence(timeout: 5), "Filter bar should appear when recipes exist")

            // Verify filter chips are visible
            XCTAssertTrue(app.buttons["All"].exists || app.staticTexts["All"].exists, "All filter should be visible")
        } else if isEmpty {
            // If no recipes, filter bar should NOT be visible
            let filterBar = app.scrollViews["filterBar"]
            XCTAssertFalse(filterBar.exists, "Filter bar should not appear when no recipes exist")
        }
    }

    @MainActor
    func testFilterBarHasTimeFilters() throws {
        app.launch()

        // Wait for home screen and recipes to load
        XCTAssertTrue(app.navigationBars["RecipeJoe"].waitForExistence(timeout: 5), "Home screen should load")

        let recipeList = app.collectionViews["recipeList"]
        guard recipeList.waitForExistence(timeout: 10) else {
            // Skip test if no recipes - can't test filters without data
            throw XCTSkip("No recipes available to test filter bar")
        }

        // Filter bar should exist
        let filterBar = app.scrollViews["filterBar"]
        XCTAssertTrue(filterBar.waitForExistence(timeout: 5), "Filter bar should exist")

        // Check for time filter buttons (they contain clock icons and text)
        // The "All" button should be selected by default
        let allButton = filterBar.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'All' OR label CONTAINS[c] 'Alli'")).firstMatch
        XCTAssertTrue(allButton.exists, "All time filter should exist")
    }
}
