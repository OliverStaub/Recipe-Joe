//
//  RecipeImportUITests.swift
//  RecipeJoeUITests
//
//  UI tests for recipe URL import functionality
//

import XCTest

final class RecipeImportUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testURLTextFieldExists() throws {
        let app = XCUIApplication()
        app.launch()

        // Navigate to Add Recipe tab
        app.tabBars.buttons["Add Recipe"].tap()

        // Verify URL text field exists
        let urlTextField = app.textFields["urlTextField"]
        XCTAssertTrue(urlTextField.waitForExistence(timeout: 5),
                      "URL text field should exist")
    }

    @MainActor
    func testActionButtonExists() throws {
        let app = XCUIApplication()
        app.launch()

        // Navigate to Add Recipe tab
        app.tabBars.buttons["Add Recipe"].tap()

        // Verify action button exists
        let actionButton = app.buttons["actionButton"]
        XCTAssertTrue(actionButton.waitForExistence(timeout: 5),
                      "Action button should exist")
    }

    @MainActor
    func testActionButtonDisabledWhenNoURL() throws {
        let app = XCUIApplication()
        app.launch()

        // Navigate to Add Recipe tab
        app.tabBars.buttons["Add Recipe"].tap()

        // Verify action button is disabled when URL is empty
        let actionButton = app.buttons["actionButton"]
        XCTAssertTrue(actionButton.waitForExistence(timeout: 5))
        XCTAssertFalse(actionButton.isEnabled,
                       "Action button should be disabled when URL is empty")
    }

    @MainActor
    func testActionButtonEnabledWhenURLEntered() throws {
        let app = XCUIApplication()
        app.launch()

        // Navigate to Add Recipe tab
        app.tabBars.buttons["Add Recipe"].tap()

        // Enter a URL
        let urlTextField = app.textFields["urlTextField"]
        XCTAssertTrue(urlTextField.waitForExistence(timeout: 5))
        urlTextField.tap()
        urlTextField.typeText("https://example.com/recipe")

        // Verify action button is now enabled
        let actionButton = app.buttons["actionButton"]
        XCTAssertTrue(actionButton.isEnabled,
                      "Action button should be enabled when URL is entered")
    }

    @MainActor
    func testPlatformIconsVisible() throws {
        let app = XCUIApplication()
        app.launch()

        // Navigate to Add Recipe tab
        app.tabBars.buttons["Add Recipe"].tap()

        // Verify platform icons are visible
        let platformIcons = app.otherElements["platformIcons"]
        XCTAssertTrue(platformIcons.waitForExistence(timeout: 5),
                      "Platform icons should be visible")
    }

    @MainActor
    func testNewRecipeTitleVisible() throws {
        let app = XCUIApplication()
        app.launch()

        // Navigate to Add Recipe tab
        app.tabBars.buttons["Add Recipe"].tap()

        // Verify title is visible
        let title = app.staticTexts["newRecipeTitle"]
        XCTAssertTrue(title.waitForExistence(timeout: 5),
                      "New Recipe title should be visible")
    }
}
