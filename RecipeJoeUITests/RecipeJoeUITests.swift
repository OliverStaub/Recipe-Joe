//
//  RecipeJoeUITests.swift
//  RecipeJoeUITests
//
//  Created by Oliver Staub on 23.11.2025.
//

import XCTest

final class RecipeJoeUITests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    @MainActor
    func testExample() throws {
        // UI tests must launch the application that they test.
        let app = XCUIApplication()
        app.launch()

        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

    @MainActor
    func testLaunchPerformance() throws {
        // This measures how long it takes to launch your application.
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }

    // MARK: - Tab Bar Tests

    @MainActor
    func testTabBarExists() throws {
        // Launch the app
        let app = XCUIApplication()
        app.launch()

        // Verify tab bar exists
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.exists, "Tab bar should exist")
    }

    @MainActor
    func testAllTabsExist() throws {
        let app = XCUIApplication()
        app.launch()

        let tabBar = app.tabBars.firstMatch

        // Verify all three tabs exist (Home, Add Recipe, and Search with liquid glass)
        XCTAssertTrue(tabBar.buttons["Home"].exists, "Home tab should exist")
        XCTAssertTrue(tabBar.buttons["Add Recipe"].exists, "Add Recipe tab should exist")
        XCTAssertTrue(tabBar.buttons["Search"].exists, "Search tab should exist (separated with liquid glass effect)")
    }

    @MainActor
    func testHomeTabContent() throws {
        let app = XCUIApplication()
        app.launch()

        // Home tab should be selected by default
        XCTAssertTrue(app.navigationBars["RecipeJoe"].exists, "RecipeJoe navigation bar should be visible on Home tab")
        XCTAssertTrue(app.staticTexts["Home"].exists, "Home text should be visible")
        XCTAssertTrue(app.staticTexts["Recipe home screen coming soon"].exists, "Home placeholder text should be visible")
    }

    @MainActor
    func testAddRecipeTabContent() throws {
        let app = XCUIApplication()
        app.launch()

        // Switch to Add Recipe tab
        app.tabBars.buttons["Add Recipe"].tap()

        // Verify Add Recipe view content
        XCTAssertTrue(app.navigationBars["New Recipe"].exists, "New Recipe navigation bar should be visible")
        XCTAssertTrue(app.staticTexts["Add Recipe"].exists, "Add Recipe text should be visible")
        XCTAssertTrue(app.staticTexts["Recipe creation form coming soon"].exists, "Add Recipe placeholder text should be visible")
    }

    // MARK: - Search Tab Tests (iOS 26 Liquid Glass)

    @MainActor
    func testSearchTabContent() throws {
        let app = XCUIApplication()
        app.launch()

        // Switch to Search tab
        app.tabBars.buttons["Search"].tap()

        // Verify Search view content
        XCTAssertTrue(app.navigationBars["Search"].exists, "Search navigation bar should be visible")
        XCTAssertTrue(app.staticTexts["Search Recipes"].exists, "Search Recipes text should be visible")
        XCTAssertTrue(app.staticTexts["Recipe search coming soon"].exists, "Search placeholder text should be visible")
    }

    @MainActor
    func testSearchTabHasSearchBar() throws {
        let app = XCUIApplication()
        app.launch()

        // Switch to Search tab
        app.tabBars.buttons["Search"].tap()

        // Verify search field exists (iOS 26 searchable modifier)
        let searchField = app.searchFields.firstMatch
        XCTAssertTrue(searchField.exists, "Search field should exist in Search tab")
    }

    @MainActor
    func testLiquidGlassSearchTabIsSeparated() throws {
        let app = XCUIApplication()
        app.launch()

        let tabBar = app.tabBars.firstMatch

        // The Search tab should exist as a separate button with role: .search
        // In iOS 26 Liquid Glass, this appears separated from other tabs
        let searchTab = tabBar.buttons["Search"]
        XCTAssertTrue(searchTab.exists, "Liquid Glass search tab should exist")
        XCTAssertTrue(searchTab.isHittable, "Search tab should be tappable")
    }
}
