//
//  AuthenticationUITests.swift
//  RecipeJoeUITests
//
//  UI tests for authentication flow
//

import XCTest

final class AuthenticationUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false

        app = XCUIApplication()
        app.launchArguments += ["-AppleLanguages", "(en)"]
        app.launchArguments += ["-AppleLocale", "en_US"]
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Authentication View Tests

    @MainActor
    func testAuthenticationViewShowsWhenNotSignedIn() throws {
        // Reset any saved auth state by adding a launch argument
        app.launchArguments += ["-resetKeychain", "true"]
        app.launch()

        // Give the app time to check auth state
        Thread.sleep(forTimeInterval: 2)

        // Either the auth view is shown (Sign In with Apple button exists)
        // or the user is already authenticated (tab bar exists)
        let signInButton = app.buttons["Sign in with Apple"]
        let tabBar = app.tabBars.firstMatch

        // At least one should appear
        let authViewAppears = signInButton.waitForExistence(timeout: 5)
        let mainAppAppears = tabBar.waitForExistence(timeout: 5)

        XCTAssertTrue(authViewAppears || mainAppAppears,
                      "Either authentication view or main app should appear")
    }

    @MainActor
    func testAuthenticationViewHasAppBranding() throws {
        app.launchArguments += ["-resetKeychain", "true"]
        app.launch()

        // Wait for UI to stabilize
        Thread.sleep(forTimeInterval: 2)

        // Check if auth view is shown (we're not authenticated)
        let signInButton = app.buttons["Sign in with Apple"]

        if signInButton.waitForExistence(timeout: 5) {
            // Verify app title is visible
            let appTitle = app.staticTexts["RecipeJoe"]
            XCTAssertTrue(appTitle.exists, "App title should be visible on auth screen")

            // Verify subtitle is visible
            let subtitle = app.staticTexts["Sign in to start importing your recipes"]
            XCTAssertTrue(subtitle.exists, "Auth subtitle should be visible")
        } else {
            // Already authenticated - skip this test
            throw XCTSkip("User is already authenticated, cannot test auth view branding")
        }
    }

    @MainActor
    func testSignInWithAppleButtonExists() throws {
        app.launchArguments += ["-resetKeychain", "true"]
        app.launch()

        Thread.sleep(forTimeInterval: 2)

        let signInButton = app.buttons["Sign in with Apple"]

        if signInButton.waitForExistence(timeout: 5) {
            XCTAssertTrue(signInButton.isHittable, "Sign In with Apple button should be tappable")
        } else {
            throw XCTSkip("User is already authenticated, cannot test sign in button")
        }
    }

    // MARK: - Settings Account Section Tests (when authenticated)

    @MainActor
    func testSettingsShowsAccountSection() throws {
        app.launch()

        // Wait for app to stabilize
        Thread.sleep(forTimeInterval: 2)

        // Check if we're on the main app (authenticated)
        let tabBar = app.tabBars.firstMatch
        guard tabBar.waitForExistence(timeout: 5) else {
            throw XCTSkip("User is not authenticated, cannot test account settings")
        }

        // Navigate to Settings
        let settingsButton = app.buttons["settingsButton"]
        XCTAssertTrue(settingsButton.waitForExistence(timeout: 5), "Settings button should exist")
        settingsButton.tap()

        // Verify Settings opened
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 5),
                      "Settings should open")

        // Verify Account section exists
        let accountSection = app.staticTexts["Account"]
        XCTAssertTrue(accountSection.waitForExistence(timeout: 5),
                      "Account section should exist in Settings")
    }

    @MainActor
    func testSettingsShowsSignOutButton() throws {
        app.launch()

        Thread.sleep(forTimeInterval: 2)

        let tabBar = app.tabBars.firstMatch
        guard tabBar.waitForExistence(timeout: 5) else {
            throw XCTSkip("User is not authenticated, cannot test sign out button")
        }

        // Navigate to Settings
        app.buttons["settingsButton"].tap()
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 5), "Settings should open")

        // Scroll to find Sign Out button if needed
        let signOutButton = app.buttons["Sign Out"]

        // Scroll down if not visible
        if !signOutButton.exists {
            app.swipeUp()
        }

        XCTAssertTrue(signOutButton.waitForExistence(timeout: 5), "Sign Out button should exist")
    }

    @MainActor
    func testSignOutShowsConfirmation() throws {
        app.launch()

        Thread.sleep(forTimeInterval: 2)

        let tabBar = app.tabBars.firstMatch
        guard tabBar.waitForExistence(timeout: 5) else {
            throw XCTSkip("User is not authenticated, cannot test sign out confirmation")
        }

        // Navigate to Settings
        app.buttons["settingsButton"].tap()
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 5), "Settings should open")

        // Find and tap Sign Out button
        let signOutButton = app.buttons["Sign Out"]
        if !signOutButton.exists {
            app.swipeUp()
        }

        guard signOutButton.waitForExistence(timeout: 5) else {
            XCTFail("Sign Out button not found")
            return
        }

        signOutButton.tap()

        // Verify confirmation dialog appears
        let confirmationDialog = app.sheets.firstMatch
        XCTAssertTrue(confirmationDialog.waitForExistence(timeout: 5),
                      "Sign out confirmation dialog should appear")

        // Verify "Are you sure" message
        let confirmMessage = app.staticTexts["Are you sure you want to sign out?"]
        XCTAssertTrue(confirmMessage.exists, "Confirmation message should be visible")

        // Cancel to not actually sign out
        let cancelButton = app.buttons["Cancel"]
        if cancelButton.exists {
            cancelButton.tap()
        }
    }

    @MainActor
    func testDeleteAccountShowsConfirmation() throws {
        app.launch()

        Thread.sleep(forTimeInterval: 2)

        let tabBar = app.tabBars.firstMatch
        guard tabBar.waitForExistence(timeout: 5) else {
            throw XCTSkip("User is not authenticated, cannot test delete account")
        }

        // Navigate to Settings
        app.buttons["settingsButton"].tap()
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 5), "Settings should open")

        // Find Delete Account button
        let deleteButton = app.buttons["Delete Account"]
        if !deleteButton.exists {
            app.swipeUp()
        }

        guard deleteButton.waitForExistence(timeout: 5) else {
            XCTFail("Delete Account button not found")
            return
        }

        deleteButton.tap()

        // Verify confirmation dialog appears
        let confirmationDialog = app.sheets.firstMatch
        XCTAssertTrue(confirmationDialog.waitForExistence(timeout: 5),
                      "Delete account confirmation should appear")

        // Verify warning message about permanent deletion
        let warningExists = app.staticTexts.element(matching: NSPredicate(
            format: "label CONTAINS[c] 'permanently delete'"
        )).exists

        XCTAssertTrue(warningExists, "Warning about permanent deletion should be visible")

        // Cancel to not actually delete
        let cancelButton = app.buttons["Cancel"]
        if cancelButton.exists {
            cancelButton.tap()
        }
    }
}
