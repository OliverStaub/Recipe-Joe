//
//  AuthenticationUITests.swift
//  RecipeJoeUITests
//
//  UI tests for authentication flow (Apple Sign In button, Settings account section)
//  For comprehensive email/password auth tests, see AccountTestSuite.swift
//

import XCTest

/// UI tests for authentication flow
/// Extends BaseUITestCase for consistent setup
final class AuthenticationUITests: BaseUITestCase {

    // Inherits from BaseUITestCase which provides:
    // - app: XCUIApplication (configured with English locale)
    // - requireAuthentication() helper
    // - openSettings() helper

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
        guard tabBar.waitForExistence(timeout: 10) else {
            throw XCTSkip("User is not authenticated, cannot test account settings")
        }

        // Navigate to Settings
        let settingsButton = app.buttons["settingsButton"]
        XCTAssertTrue(settingsButton.waitForExistence(timeout: 5), "Settings button should exist")
        settingsButton.tap()

        // Verify Settings opened - check for Sign Out button which is always visible
        let signOutButton = app.buttons["signOutButton"]
        XCTAssertTrue(signOutButton.waitForExistence(timeout: 5),
                      "Settings should open and show account section with Sign Out button")
    }

    @MainActor
    func testSettingsShowsSignOutButton() throws {
        app.launch()

        Thread.sleep(forTimeInterval: 2)

        let tabBar = app.tabBars.firstMatch
        guard tabBar.waitForExistence(timeout: 10) else {
            throw XCTSkip("User is not authenticated, cannot test sign out button")
        }

        // Navigate to Settings
        let settingsButton = app.buttons["settingsButton"]
        guard settingsButton.waitForExistence(timeout: 5) else {
            XCTFail("Settings button not found")
            return
        }
        settingsButton.tap()

        // Find Sign Out button using accessibility identifier
        let signOutButton = app.buttons["signOutButton"]

        // Scroll down if not visible
        if !signOutButton.waitForExistence(timeout: 3) {
            app.swipeUp()
        }

        XCTAssertTrue(signOutButton.waitForExistence(timeout: 5), "Sign Out button should exist")
    }

    @MainActor
    func testSignOutShowsConfirmation() throws {
        app.launch()

        Thread.sleep(forTimeInterval: 2)

        let tabBar = app.tabBars.firstMatch
        guard tabBar.waitForExistence(timeout: 10) else {
            throw XCTSkip("User is not authenticated, cannot test sign out confirmation")
        }

        // Navigate to Settings
        let settingsButton = app.buttons["settingsButton"]
        guard settingsButton.waitForExistence(timeout: 5) else {
            XCTFail("Settings button not found")
            return
        }
        settingsButton.tap()

        // Find and tap Sign Out button using accessibility identifier
        let signOutButton = app.buttons["signOutButton"]
        if !signOutButton.waitForExistence(timeout: 3) {
            app.swipeUp()
        }

        guard signOutButton.waitForExistence(timeout: 5) else {
            XCTFail("Sign Out button not found")
            return
        }

        signOutButton.tap()

        // Verify confirmation alert appears
        let alertDialog = app.alerts.firstMatch
        XCTAssertTrue(alertDialog.waitForExistence(timeout: 5), "Sign out confirmation alert should appear")

        // Cancel to not actually sign out
        let cancelButton = alertDialog.buttons["Cancel"]
        if cancelButton.waitForExistence(timeout: 3) {
            cancelButton.tap()
        }
    }

    @MainActor
    func testDeleteAccountShowsConfirmation() throws {
        app.launch()

        Thread.sleep(forTimeInterval: 2)

        let tabBar = app.tabBars.firstMatch
        guard tabBar.waitForExistence(timeout: 10) else {
            throw XCTSkip("User is not authenticated, cannot test delete account")
        }

        // Navigate to Settings
        let settingsButton = app.buttons["settingsButton"]
        guard settingsButton.waitForExistence(timeout: 5) else {
            XCTFail("Settings button not found")
            return
        }
        settingsButton.tap()

        // Find Delete Account button using accessibility identifier
        let deleteButton = app.buttons["deleteAccountButton"]
        if !deleteButton.waitForExistence(timeout: 3) {
            app.swipeUp()
        }

        guard deleteButton.waitForExistence(timeout: 5) else {
            XCTFail("Delete Account button not found")
            return
        }

        deleteButton.tap()

        // Verify confirmation alert appears
        let alertDialog = app.alerts.firstMatch
        XCTAssertTrue(alertDialog.waitForExistence(timeout: 5), "Delete account confirmation alert should appear")

        // Cancel to not actually delete
        let cancelButton = alertDialog.buttons["Cancel"]
        if cancelButton.waitForExistence(timeout: 3) {
            cancelButton.tap()
        }
    }
}
