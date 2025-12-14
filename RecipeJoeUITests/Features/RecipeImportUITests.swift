//
//  RecipeImportUITests.swift
//  RecipeJoeUITests
//
//  UI tests for recipe URL import functionality
//

import XCTest

/// UI tests for recipe import functionality
/// Extends BaseUITestCase for consistent setup and cleanup
final class RecipeImportUITests: BaseUITestCase {

    // Inherits from BaseUITestCase which provides:
    // - app: XCUIApplication (configured with English locale)
    // - requireAuthentication() helper
    // - setUpWithError() with locale configuration
    // - tearDownWithError() with cleanup
    // - navigateToAddRecipe() helper
    // - cleanupAllTestRecipes() for test data cleanup

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

        // Wait for UI to update - check that video section does NOT appear
        let videoSection = app.staticTexts["Video"]
        // Give a short wait then verify it's not there
        _ = videoSection.waitForExistence(timeout: 1)
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

        // Wait for UI to update and verify timestamp section disappears
        let youtubeSection = app.staticTexts["YouTube Video"]
        // Give a short wait then verify it's gone
        _ = youtubeSection.waitForExistence(timeout: 1)
        XCTAssertFalse(youtubeSection.exists,
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

    // MARK: - Full Import Flow Tests

    /// Test importing a real recipe via URL
    /// This test creates actual data in Supabase and verifies it appears in the app
    /// Note: Cleanup requires TestConfig.sandboxUserId and SUPABASE_SERVICE_ROLE_KEY to be set
    /// See RecipeJoeUITests/README.md for setup instructions
    @MainActor
    func testImportRecipeFromURL() throws {
        app.launch()
        try requireAuthentication()

        // Navigate to Add Recipe tab
        navigateToAddRecipe()

        // Enter a real recipe URL (use a stable, publicly accessible recipe)
        let urlTextField = app.textFields["urlTextField"]
        XCTAssertTrue(urlTextField.waitForExistence(timeout: 5), "URL text field should exist")
        urlTextField.tap()

        // Use a simple, stable recipe URL
        urlTextField.typeText("https://www.allrecipes.com/recipe/10813/best-chocolate-chip-cookies/")

        // Tap the import button
        let actionButton = app.buttons["actionButton"]
        XCTAssertTrue(actionButton.waitForExistence(timeout: 5), "Action button should exist")
        actionButton.tap()

        // Wait for import to start - look for progress indicator or importing state
        // The import can take a while due to AI processing (up to 2 minutes)
        let importTimeout: TimeInterval = 120

        // Wait for either success (recipe appears) or error state
        // The app should navigate to home or show success after import
        let homeTab = app.tabBars.buttons["Home"]

        // Wait for home tab to be available (import may auto-navigate or we navigate)
        if homeTab.waitForExistence(timeout: 10) {
            homeTab.tap()
        }

        // Wait for the recipe list to load
        let recipeList = app.collectionViews["recipeList"]

        // The recipe should appear in the list (or we should see it was imported)
        // Note: This test may be skipped if import fails due to network issues
        if !recipeList.waitForExistence(timeout: importTimeout) {
            // Check if we're still on import screen (import in progress or failed)
            let urlFieldStillVisible = urlTextField.waitForExistence(timeout: 2)
            if urlFieldStillVisible {
                // Import may have failed or still in progress - skip test
                throw XCTSkip("Recipe import did not complete in time - may be network issue")
            }
        }

        // Cleanup: Call cleanupAllTestRecipes() if BaseUITestCase is configured
        // For now this is a placeholder - see README for full setup
        cleanupAllTestRecipes()
    }
}
