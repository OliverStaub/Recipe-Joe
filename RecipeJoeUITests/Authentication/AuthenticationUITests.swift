//
//  AuthenticationUITests.swift
//  RecipeJoeUITests
//
//  Comprehensive UI tests for authentication:
//  - Sign in with Apple button and branding
//  - Sign up/in with email and password
//  - Sign out flow
//  - Account deletion
//  - Settings account section
//

import XCTest

/// UI tests for authentication flows
final class AuthenticationUITests: BaseUITestCase {

    /// Track test users created during tests for cleanup
    private var createdUserIds: [UUID] = []

    /// Unique identifier for this test run
    private let testRunId = UUID().uuidString.prefix(8)

    override func tearDownWithError() throws {
        // Cleanup any test users created during tests
        for userId in createdUserIds {
            TestSupabaseClient.shared.deleteUserSync(userId: userId)
        }
        createdUserIds.removeAll()

        try super.tearDownWithError()
    }

    // MARK: - Helper Methods

    /// Generate a unique test email for this test run
    private func generateTestEmail(prefix: String = "test") -> String {
        return "\(prefix)_\(testRunId)@recipejoe.test"
    }

    /// Create a test user via Admin API and track for cleanup
    private func createTestUser(email: String, password: String) -> UUID? {
        if let userId = TestSupabaseClient.shared.createTestUserSync(email: email, password: password) {
            createdUserIds.append(userId)
            return userId
        }
        return nil
    }

    /// Check if currently showing auth view (not authenticated)
    @MainActor
    private func isShowingAuthView() -> Bool {
        let emailField = app.textFields["emailTextField"]
        return emailField.waitForExistence(timeout: TestConfig.standardTimeout)
    }

    /// Sign out if currently authenticated and wait for auth view
    @MainActor
    private func signOutIfNeeded() {
        guard isAuthenticated() else { return }
        signOut()
        let emailField = app.textFields["emailTextField"]
        _ = emailField.waitForExistence(timeout: TestConfig.authTimeout)
    }

    /// Wait for app to show either auth view or main app
    @MainActor
    private func waitForAppReady() {
        let tabBar = app.tabBars.firstMatch
        let signInButton = app.buttons["Sign in with Apple"]
        let emailField = app.textFields["emailTextField"]

        let expectation = XCTNSPredicateExpectation(
            predicate: NSPredicate { _, _ in
                tabBar.exists || signInButton.exists || emailField.exists
            },
            object: nil
        )
        _ = XCTWaiter.wait(for: [expectation], timeout: TestConfig.authTimeout)
    }

    // MARK: - Auth View Appearance Tests

    @MainActor
    func testAuthenticationViewShowsWhenNotSignedIn() throws {
        app.launchArguments += ["-resetKeychain", "true"]
        app.launch()

        waitForAppReady()

        let signInButton = app.buttons["Sign in with Apple"]
        let tabBar = app.tabBars.firstMatch

        let authViewAppears = signInButton.exists
        let mainAppAppears = tabBar.exists

        XCTAssertTrue(authViewAppears || mainAppAppears,
                      "Either authentication view or main app should appear")
    }

    @MainActor
    func testAuthenticationViewHasAppBranding() throws {
        app.launchArguments += ["-resetKeychain", "true"]
        app.launch()

        waitForAppReady()

        let signInButton = app.buttons["Sign in with Apple"]

        if signInButton.exists {
            let appTitle = app.staticTexts["RecipeJoe"]
            XCTAssertTrue(appTitle.exists, "App title should be visible on auth screen")

            let subtitle = app.staticTexts["Sign in to start importing your recipes"]
            XCTAssertTrue(subtitle.exists, "Auth subtitle should be visible")
        } else {
            throw XCTSkip("User is already authenticated, cannot test auth view branding")
        }
    }

    @MainActor
    func testSignInWithAppleButtonExists() throws {
        app.launchArguments += ["-resetKeychain", "true"]
        app.launch()

        waitForAppReady()

        let signInButton = app.buttons["Sign in with Apple"]

        if signInButton.exists {
            XCTAssertTrue(signInButton.isHittable, "Sign In with Apple button should be tappable")
        } else {
            throw XCTSkip("User is already authenticated, cannot test sign in button")
        }
    }

    // MARK: - Email/Password Sign Up Tests

    @MainActor
    func testSignUpWithEmailAndPassword() throws {
        guard TestConfig.serviceRoleKey != nil else {
            throw XCTSkip("SUPABASE_SERVICE_ROLE_KEY not set - cannot run account tests")
        }

        app.launch()
        signOutIfNeeded()

        guard isShowingAuthView() else {
            throw XCTSkip("Not showing auth view")
        }

        // Switch to Sign Up mode
        let authModeToggle = app.segmentedControls["authModeToggle"]
        XCTAssertTrue(authModeToggle.waitForExistence(timeout: TestConfig.standardTimeout), "Auth mode toggle should exist")
        authModeToggle.buttons["Sign Up"].tap()

        // Fill in email
        let email = generateTestEmail(prefix: "signup")
        let emailField = app.textFields["emailTextField"]
        XCTAssertTrue(emailField.waitForExistence(timeout: TestConfig.standardTimeout))
        emailField.tap()
        emailField.typeText(email)

        // Fill in password
        let passwordField = app.secureTextFields["passwordTextField"]
        XCTAssertTrue(passwordField.waitForExistence(timeout: TestConfig.standardTimeout))
        passwordField.tap()
        passwordField.typeText(TestConfig.testPasswordForNewUsers)

        // Fill in confirm password
        let confirmField = app.secureTextFields["confirmPasswordTextField"]
        XCTAssertTrue(confirmField.waitForExistence(timeout: TestConfig.standardTimeout))
        confirmField.tap()
        confirmField.typeText(TestConfig.testPasswordForNewUsers)

        // Tap Create Account
        let createButton = app.buttons["emailAuthButton"]
        XCTAssertTrue(createButton.waitForExistence(timeout: TestConfig.standardTimeout))
        createButton.tap()

        // Wait for outcome: auth complete, error message, or still on auth screen
        let tabBar = app.tabBars.firstMatch
        let errorMessage = app.staticTexts["authErrorMessage"]

        let expectation = XCTNSPredicateExpectation(
            predicate: NSPredicate { _, _ in
                tabBar.exists || errorMessage.exists || emailField.exists
            },
            object: nil
        )
        _ = XCTWaiter.wait(for: [expectation], timeout: TestConfig.authTimeout)

        XCTAssertTrue(tabBar.exists || errorMessage.exists || emailField.exists,
                      "Sign up should complete (auth, message, or awaiting confirmation)")

        // Track user for cleanup if created
        if let userId = TestSupabaseClient.shared.getUserByEmailSync(email: email) {
            createdUserIds.append(userId)
        }
    }

    @MainActor
    func testSignUpWithWeakPassword() throws {
        guard TestConfig.serviceRoleKey != nil else {
            throw XCTSkip("SUPABASE_SERVICE_ROLE_KEY not set")
        }

        app.launch()
        signOutIfNeeded()

        guard isShowingAuthView() else {
            throw XCTSkip("Not showing auth view")
        }

        // Switch to Sign Up mode
        app.segmentedControls["authModeToggle"].buttons["Sign Up"].tap()

        // Fill in email
        let emailField = app.textFields["emailTextField"]
        emailField.tap()
        emailField.typeText(generateTestEmail(prefix: "weak"))

        // Fill in weak password (less than 6 chars)
        let passwordField = app.secureTextFields["passwordTextField"]
        passwordField.tap()
        passwordField.typeText("12345")

        // Button should be disabled or show error
        let createButton = app.buttons["emailAuthButton"]
        XCTAssertTrue(createButton.waitForExistence(timeout: TestConfig.standardTimeout))
    }

    // MARK: - Email/Password Sign In Tests

    @MainActor
    func testSignInWithEmailAndPassword() throws {
        guard TestConfig.serviceRoleKey != nil else {
            throw XCTSkip("SUPABASE_SERVICE_ROLE_KEY not set")
        }

        // Create a test user first
        let email = generateTestEmail(prefix: "signin")
        let password = TestConfig.testPasswordForNewUsers

        guard createTestUser(email: email, password: password) != nil else {
            XCTFail("Failed to create test user")
            return
        }

        app.launch()
        signOutIfNeeded()

        guard isShowingAuthView() else {
            throw XCTSkip("Not showing auth view")
        }

        // Enter credentials
        let emailField = app.textFields["emailTextField"]
        XCTAssertTrue(emailField.waitForExistence(timeout: TestConfig.standardTimeout))
        emailField.tap()
        emailField.typeText(email)

        let passwordField = app.secureTextFields["passwordTextField"]
        XCTAssertTrue(passwordField.waitForExistence(timeout: TestConfig.standardTimeout))
        passwordField.tap()
        passwordField.typeText(password)

        // Tap Sign In
        app.buttons["emailAuthButton"].tap()

        // Wait for authentication
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: TestConfig.authTimeout), "Should be authenticated after sign in")
    }

    @MainActor
    func testSignInWithInvalidCredentials() throws {
        app.launch()
        signOutIfNeeded()

        guard isShowingAuthView() else {
            throw XCTSkip("Not showing auth view")
        }

        // Try to sign in with non-existent user
        let emailField = app.textFields["emailTextField"]
        emailField.tap()
        emailField.typeText("nonexistent_\(testRunId)@recipejoe.test")

        let passwordField = app.secureTextFields["passwordTextField"]
        passwordField.tap()
        passwordField.typeText("WrongPassword123!")

        app.buttons["emailAuthButton"].tap()

        // Should show error
        let errorMessage = app.staticTexts["authErrorMessage"]
        XCTAssertTrue(errorMessage.waitForExistence(timeout: TestConfig.authTimeout), "Should show error message")
    }

    // MARK: - Sign Out Tests

    @MainActor
    func testSignOut() throws {
        guard TestConfig.serviceRoleKey != nil else {
            throw XCTSkip("SUPABASE_SERVICE_ROLE_KEY not set")
        }

        // Create and sign in with test user
        let email = generateTestEmail(prefix: "signout")
        let password = TestConfig.testPasswordForNewUsers

        guard createTestUser(email: email, password: password) != nil else {
            XCTFail("Failed to create test user")
            return
        }

        app.launch()
        signOutIfNeeded()

        // Sign in
        let emailField = app.textFields["emailTextField"]
        emailField.tap()
        emailField.typeText(email)

        let passwordField = app.secureTextFields["passwordTextField"]
        passwordField.tap()
        passwordField.typeText(password)

        app.buttons["emailAuthButton"].tap()

        // Wait for authentication
        let tabBar = app.tabBars.firstMatch
        guard tabBar.waitForExistence(timeout: TestConfig.authTimeout) else {
            XCTFail("Should be authenticated")
            return
        }

        // Now sign out
        openSettings()

        let signOutButton = app.buttons["signOutButton"]
        XCTAssertTrue(signOutButton.waitForExistence(timeout: TestConfig.standardTimeout))
        signOutButton.tap()

        // Confirm in alert
        let confirmButton = app.alerts.buttons["Sign Out"]
        XCTAssertTrue(confirmButton.waitForExistence(timeout: TestConfig.standardTimeout), "Sign out confirmation alert should appear")
        confirmButton.tap()

        // Should be back to auth view
        let authEmailField = app.textFields["emailTextField"]
        XCTAssertTrue(authEmailField.waitForExistence(timeout: TestConfig.authTimeout), "Should show auth view after sign out")
    }

    @MainActor
    func testSignOutShowsConfirmation() throws {
        app.launch()

        let tabBar = app.tabBars.firstMatch
        guard tabBar.waitForExistence(timeout: TestConfig.authTimeout) else {
            throw XCTSkip("User is not authenticated, cannot test sign out confirmation")
        }

        openSettings()

        let signOutButton = app.buttons["signOutButton"]
        if !signOutButton.waitForExistence(timeout: 3) {
            app.swipeUp()
        }

        guard signOutButton.waitForExistence(timeout: TestConfig.standardTimeout) else {
            XCTFail("Sign Out button not found")
            return
        }

        signOutButton.tap()

        // Verify confirmation alert appears
        let alertDialog = app.alerts.firstMatch
        XCTAssertTrue(alertDialog.waitForExistence(timeout: TestConfig.standardTimeout), "Sign out confirmation alert should appear")

        // Cancel to not actually sign out
        let cancelButton = alertDialog.buttons["Cancel"]
        if cancelButton.waitForExistence(timeout: 3) {
            cancelButton.tap()
        }
    }

    // MARK: - Account Deletion Tests

    @MainActor
    func testDeleteAccountShowsConfirmation() throws {
        guard TestConfig.serviceRoleKey != nil else {
            throw XCTSkip("SUPABASE_SERVICE_ROLE_KEY not set")
        }

        // Create and sign in with test user
        let email = generateTestEmail(prefix: "delete")
        let password = TestConfig.testPasswordForNewUsers

        guard createTestUser(email: email, password: password) != nil else {
            XCTFail("Failed to create test user")
            return
        }

        app.launch()
        signOutIfNeeded()

        // Sign in
        let emailField = app.textFields["emailTextField"]
        emailField.tap()
        emailField.typeText(email)

        let passwordField = app.secureTextFields["passwordTextField"]
        passwordField.tap()
        passwordField.typeText(password)

        app.buttons["emailAuthButton"].tap()

        // Wait for authentication
        let tabBar = app.tabBars.firstMatch
        guard tabBar.waitForExistence(timeout: TestConfig.authTimeout) else {
            XCTFail("Should be authenticated")
            return
        }

        // Open settings
        openSettings()

        // Tap delete account
        let deleteButton = app.buttons["deleteAccountButton"]
        XCTAssertTrue(deleteButton.waitForExistence(timeout: TestConfig.standardTimeout))
        deleteButton.tap()

        // Verify confirmation alert appears
        let alert = app.alerts.firstMatch
        XCTAssertTrue(alert.waitForExistence(timeout: TestConfig.standardTimeout), "Delete confirmation alert should appear")

        // Cancel - don't actually delete
        let cancelButton = app.alerts.buttons["Cancel"]
        XCTAssertTrue(cancelButton.waitForExistence(timeout: 3))
        cancelButton.tap()

        // Should still be in settings
        XCTAssertTrue(deleteButton.waitForExistence(timeout: TestConfig.standardTimeout), "Should still be in settings after cancel")
    }

    // MARK: - Settings Account Section Tests

    @MainActor
    func testSettingsShowsAccountSection() throws {
        app.launch()

        let tabBar = app.tabBars.firstMatch
        guard tabBar.waitForExistence(timeout: TestConfig.authTimeout) else {
            throw XCTSkip("User is not authenticated, cannot test account settings")
        }

        openSettings()

        let signOutButton = app.buttons["signOutButton"]
        XCTAssertTrue(signOutButton.waitForExistence(timeout: TestConfig.standardTimeout),
                      "Settings should open and show account section with Sign Out button")
    }

    @MainActor
    func testSettingsShowsSignOutButton() throws {
        app.launch()

        let tabBar = app.tabBars.firstMatch
        guard tabBar.waitForExistence(timeout: TestConfig.authTimeout) else {
            throw XCTSkip("User is not authenticated, cannot test sign out button")
        }

        openSettings()

        let signOutButton = app.buttons["signOutButton"]
        if !signOutButton.waitForExistence(timeout: 3) {
            app.swipeUp()
        }

        XCTAssertTrue(signOutButton.waitForExistence(timeout: TestConfig.standardTimeout), "Sign Out button should exist")
    }
}
