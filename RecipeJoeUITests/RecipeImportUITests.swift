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

    /// Helper to check if user is authenticated (main tab bar is visible)
    /// Throws XCTSkip if not authenticated since these tests require authentication
    @MainActor
    func requireAuthentication() throws {
        let tabBar = app.tabBars.firstMatch
        guard tabBar.waitForExistence(timeout: 5) else {
            throw XCTSkip("User is not authenticated - these tests require authentication")
        }
    }

    @MainActor
    func testURLTextFieldExists() throws {
        app.launch()
        try requireAuthentication()

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
        try requireAuthentication()

        // Navigate to Add Recipe tab
        app.tabBars.buttons["Add Recipe"].tap()

        // Verify action button exists
        let actionButton = app.buttons["actionButton"]
        XCTAssertTrue(actionButton.waitForExistence(timeout: 5),
                      "Action button should exist")
    }

    @MainActor
    func testActionButtonShowsMenuWhenNoURL() throws {
        app.launch()
        try requireAuthentication()

        // Navigate to Add Recipe tab
        app.tabBars.buttons["Add Recipe"].tap()

        // Verify action button exists and is enabled (it's now a menu)
        let actionButton = app.buttons["actionButton"]
        XCTAssertTrue(actionButton.waitForExistence(timeout: 5))
        XCTAssertTrue(actionButton.isEnabled,
                      "Action button should be enabled (shows menu when no URL)")
    }

    @MainActor
    func testActionButtonEnabledWhenURLEntered() throws {
        app.launch()
        try requireAuthentication()

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
        try requireAuthentication()

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
        try requireAuthentication()

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
        try requireAuthentication()

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
        try requireAuthentication()

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
        try requireAuthentication()

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
        try requireAuthentication()

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

    // MARK: - Media Import Tests (Photos/PDFs)

    @MainActor
    func testPlusButtonShowsMenuWithImportOptions() throws {
        app.launch()
        try requireAuthentication()

        // Navigate to Add Recipe tab
        app.tabBars.buttons["Add Recipe"].tap()

        // Ensure URL field is empty (shows menu)
        let urlTextField = app.textFields["urlTextField"]
        XCTAssertTrue(urlTextField.waitForExistence(timeout: 5))

        // Tap the action button (plus button when no URL)
        let actionButton = app.buttons["actionButton"]
        XCTAssertTrue(actionButton.waitForExistence(timeout: 5))
        actionButton.tap()

        // Verify menu options appear
        // Note: Menu items may have different accessibility depending on iOS version
        let photoLibraryButton = app.buttons["Photo Library"]
        let takePhotoButton = app.buttons["Take Photo"]
        let importPDFButton = app.buttons["Import PDF"]

        // At least one of the menu buttons should exist
        XCTAssertTrue(
            photoLibraryButton.waitForExistence(timeout: 2) ||
            takePhotoButton.exists ||
            importPDFButton.exists,
            "Menu should show import options when plus button is tapped"
        )
    }

    @MainActor
    func testMenuHidesWhenURLEntered() throws {
        app.launch()
        try requireAuthentication()

        // Navigate to Add Recipe tab
        app.tabBars.buttons["Add Recipe"].tap()

        // Enter a URL
        let urlTextField = app.textFields["urlTextField"]
        XCTAssertTrue(urlTextField.waitForExistence(timeout: 5))
        urlTextField.tap()
        urlTextField.typeText("https://example.com/recipe")

        // Tap the action button
        let actionButton = app.buttons["actionButton"]
        XCTAssertTrue(actionButton.waitForExistence(timeout: 5))
        actionButton.tap()

        // The button should trigger URL import, not show a menu
        // Photo Library menu option should NOT exist
        let photoLibraryButton = app.buttons["Photo Library"]
        XCTAssertFalse(photoLibraryButton.waitForExistence(timeout: 1),
                       "Menu should not appear when URL is entered")
    }
}
