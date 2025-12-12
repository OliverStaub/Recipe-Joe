//
//  RecipeImportUITests.swift
//  RecipeJoeUITests
//
//  UI tests for recipe URL import functionality
//

import XCTest

final class RecipeImportUITests: XCTestCase {

    /// Configured app instance with English locale for consistent UI tests
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false

        // Configure app to launch in English for consistent UI tests
        app = XCUIApplication()

        // Set system locale to English
        app.launchArguments += ["-AppleLanguages", "(en)"]
        app.launchArguments += ["-AppleLocale", "en_US"]

        // Reset the app's internal language setting to English via UserDefaults
        app.launchArguments += ["-appLanguage", "en"]
    }

    override func tearDownWithError() throws {
        app = nil
    }

    @MainActor
    func testURLTextFieldExists() throws {
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
        app.launch()

        // Navigate to Add Recipe tab
        app.tabBars.buttons["Add Recipe"].tap()

        // Verify platform icons are visible by checking for the "Supports:" label
        let supportsLabel = app.staticTexts["Supports:"]
        XCTAssertTrue(supportsLabel.waitForExistence(timeout: 5),
                      "Platform icons section should be visible")
    }

    @MainActor
    func testNewRecipeTitleVisible() throws {
        app.launch()

        // Navigate to Add Recipe tab
        app.tabBars.buttons["Add Recipe"].tap()

        // Verify title is visible
        let title = app.staticTexts["newRecipeTitle"]
        XCTAssertTrue(title.waitForExistence(timeout: 5),
                      "New Recipe title should be visible")
    }

    // MARK: - Video Import Tests

    @MainActor
    func testTimestampFieldsAppearForYouTubeURL() throws {
        app.launch()

        // Navigate to Add Recipe tab
        app.tabBars.buttons["Add Recipe"].tap()

        // Enter a YouTube URL
        let urlTextField = app.textFields["urlTextField"]
        XCTAssertTrue(urlTextField.waitForExistence(timeout: 5))
        urlTextField.tap()
        urlTextField.typeText("https://www.youtube.com/watch?v=dQw4w9WgXcQ")

        // Verify timestamp section appears
        let videoSection = app.staticTexts["YouTube Video"]
        XCTAssertTrue(videoSection.waitForExistence(timeout: 3),
                      "Video timestamp section should appear for YouTube URL")
    }

    @MainActor
    func testTimestampFieldsAppearForTikTokURL() throws {
        app.launch()

        // Navigate to Add Recipe tab
        app.tabBars.buttons["Add Recipe"].tap()

        // Enter a TikTok URL
        let urlTextField = app.textFields["urlTextField"]
        XCTAssertTrue(urlTextField.waitForExistence(timeout: 5))
        urlTextField.tap()
        urlTextField.typeText("https://www.tiktok.com/@chef/video/1234567890")

        // Verify timestamp section appears
        let videoSection = app.staticTexts["TikTok Video"]
        XCTAssertTrue(videoSection.waitForExistence(timeout: 3),
                      "Video timestamp section should appear for TikTok URL")
    }

    @MainActor
    func testTimestampFieldsHiddenForRegularURL() throws {
        app.launch()

        // Navigate to Add Recipe tab
        app.tabBars.buttons["Add Recipe"].tap()

        // Enter a regular recipe website URL
        let urlTextField = app.textFields["urlTextField"]
        XCTAssertTrue(urlTextField.waitForExistence(timeout: 5))
        urlTextField.tap()
        urlTextField.typeText("https://www.allrecipes.com/recipe/12345")

        // Wait a moment for UI to update
        Thread.sleep(forTimeInterval: 0.5)

        // Verify timestamp section does NOT appear
        let videoSection = app.staticTexts["Video"]
        XCTAssertFalse(videoSection.exists,
                       "Video timestamp section should NOT appear for regular URLs")
    }

    @MainActor
    func testTimestampFieldsDisappearWhenURLCleared() throws {
        app.launch()

        // Navigate to Add Recipe tab
        app.tabBars.buttons["Add Recipe"].tap()

        // Enter a YouTube URL
        let urlTextField = app.textFields["urlTextField"]
        XCTAssertTrue(urlTextField.waitForExistence(timeout: 5))
        urlTextField.tap()
        urlTextField.typeText("https://www.youtube.com/watch?v=dQw4w9WgXcQ")

        // Verify timestamp section appears
        let videoSection = app.staticTexts["YouTube Video"]
        XCTAssertTrue(videoSection.waitForExistence(timeout: 3))

        // Clear the URL field
        urlTextField.tap()
        // Select all and delete
        urlTextField.doubleTap()
        if app.menuItems["Select All"].waitForExistence(timeout: 1) {
            app.menuItems["Select All"].tap()
        }
        app.keys["delete"].tap()

        // Wait a moment for UI to update
        Thread.sleep(forTimeInterval: 0.5)

        // Verify timestamp section disappears
        XCTAssertFalse(app.staticTexts["YouTube Video"].exists,
                       "Video timestamp section should disappear when URL is cleared")
    }
}
