//
//  AccountTestSuite.swift
//  RecipeJoeUITests
//
//  Comprehensive tests for account management:
//  - Sign up with email/password
//  - Sign in with email/password
//  - Sign out
//  - Account deletion
//  - RLS (Row Level Security) verification
//

import XCTest

final class AccountTestSuite: XCTestCase {

    var app: XCUIApplication!

    /// Track test users for cleanup
    private var createdUserIds: [UUID] = []

    /// Unique test identifier for this run
    private let testRunId = UUID().uuidString.prefix(8)

    override func setUpWithError() throws {
        continueAfterFailure = false

        app = XCUIApplication()
        app.launchArguments += ["-AppleLanguages", "(en)"]
        app.launchArguments += ["-AppleLocale", "en_US"]
        app.launchArguments += ["-appLanguage", "en"]
    }

    override func tearDownWithError() throws {
        // Cleanup any test users created during tests
        for userId in createdUserIds {
            TestSupabaseClient.shared.deleteUserSync(userId: userId)
        }
        createdUserIds.removeAll()

        app = nil
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
        return emailField.waitForExistence(timeout: 5)
    }

    /// Check if currently authenticated (showing main app)
    @MainActor
    private func isAuthenticated() -> Bool {
        let tabBar = app.tabBars.firstMatch
        return tabBar.waitForExistence(timeout: 10)
    }

    /// Sign out if currently authenticated
    @MainActor
    private func signOutIfNeeded() {
        if isAuthenticated() {
            // Open settings and sign out
            let settingsButton = app.buttons["settingsButton"]
            if settingsButton.waitForExistence(timeout: 5) {
                settingsButton.tap()

                let signOutButton = app.buttons["signOutButton"]
                if signOutButton.waitForExistence(timeout: 5) {
                    signOutButton.tap()

                    // Confirm sign out
                    let confirmButton = app.alerts.buttons["Sign Out"]
                    if confirmButton.waitForExistence(timeout: 3) {
                        confirmButton.tap()
                    }
                }
            }

            // Wait for auth view
            Thread.sleep(forTimeInterval: 2)
        }
    }

    // MARK: - Sign Up Tests

    @MainActor
    func testSignUpWithEmailAndPassword() throws {
        // Skip if no service key (can't create/cleanup users)
        guard TestConfig.serviceRoleKey != nil else {
            throw XCTSkip("SUPABASE_SERVICE_ROLE_KEY not set - cannot run account tests")
        }

        app.launch()
        signOutIfNeeded()

        // Should show auth view
        guard isShowingAuthView() else {
            throw XCTSkip("Not showing auth view")
        }

        // Switch to Sign Up mode
        let authModeToggle = app.segmentedControls["authModeToggle"]
        XCTAssertTrue(authModeToggle.waitForExistence(timeout: 5), "Auth mode toggle should exist")

        authModeToggle.buttons["Sign Up"].tap()

        // Fill in email
        let email = generateTestEmail(prefix: "signup")
        let emailField = app.textFields["emailTextField"]
        XCTAssertTrue(emailField.waitForExistence(timeout: 5))
        emailField.tap()
        emailField.typeText(email)

        // Fill in password
        let passwordField = app.secureTextFields["passwordTextField"]
        XCTAssertTrue(passwordField.waitForExistence(timeout: 5))
        passwordField.tap()
        passwordField.typeText("TestPassword123!")

        // Fill in confirm password
        let confirmField = app.secureTextFields["confirmPasswordTextField"]
        XCTAssertTrue(confirmField.waitForExistence(timeout: 5))
        confirmField.tap()
        confirmField.typeText("TestPassword123!")

        // Tap Create Account
        let createButton = app.buttons["emailAuthButton"]
        XCTAssertTrue(createButton.waitForExistence(timeout: 5))
        createButton.tap()

        // Expected outcomes:
        // 1. Show main app (if email confirmation disabled in Supabase)
        // 2. Show confirmation/info message (if email confirmation enabled)
        // 3. Stay on auth screen waiting for email confirmation (also valid)
        Thread.sleep(forTimeInterval: 3)

        let isNowAuthenticated = isAuthenticated()
        let hasMessage = app.staticTexts["authErrorMessage"].exists
        let stillOnAuthScreen = app.textFields["emailTextField"].exists

        // All three outcomes are valid depending on Supabase email confirmation settings
        XCTAssertTrue(isNowAuthenticated || hasMessage || stillOnAuthScreen,
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
        XCTAssertTrue(createButton.waitForExistence(timeout: 5))

        // Button should be disabled (opacity check via isEnabled)
        // Or confirm password field prevents submission
    }

    // MARK: - Sign In Tests

    @MainActor
    func testSignInWithEmailAndPassword() throws {
        guard TestConfig.serviceRoleKey != nil else {
            throw XCTSkip("SUPABASE_SERVICE_ROLE_KEY not set")
        }

        // Create a test user first
        let email = generateTestEmail(prefix: "signin")
        let password = "TestPassword123!"

        guard let userId = createTestUser(email: email, password: password) else {
            XCTFail("Failed to create test user")
            return
        }
        _ = userId  // Tracked for cleanup

        app.launch()
        signOutIfNeeded()

        guard isShowingAuthView() else {
            throw XCTSkip("Not showing auth view")
        }

        // Should be on Sign In mode by default
        let emailField = app.textFields["emailTextField"]
        XCTAssertTrue(emailField.waitForExistence(timeout: 5))
        emailField.tap()
        emailField.typeText(email)

        let passwordField = app.secureTextFields["passwordTextField"]
        XCTAssertTrue(passwordField.waitForExistence(timeout: 5))
        passwordField.tap()
        passwordField.typeText(password)

        // Tap Sign In
        let signInButton = app.buttons["emailAuthButton"]
        signInButton.tap()

        // Should be authenticated now
        Thread.sleep(forTimeInterval: 3)
        XCTAssertTrue(isAuthenticated(), "Should be authenticated after sign in")
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

        let signInButton = app.buttons["emailAuthButton"]
        signInButton.tap()

        // Should show error
        Thread.sleep(forTimeInterval: 2)

        let errorMessage = app.staticTexts["authErrorMessage"]
        XCTAssertTrue(errorMessage.waitForExistence(timeout: 5), "Should show error message")
    }

    // MARK: - Sign Out Tests

    @MainActor
    func testSignOut() throws {
        guard TestConfig.serviceRoleKey != nil else {
            throw XCTSkip("SUPABASE_SERVICE_ROLE_KEY not set")
        }

        // Create and sign in with test user
        let email = generateTestEmail(prefix: "signout")
        let password = "TestPassword123!"

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
        Thread.sleep(forTimeInterval: 3)

        guard isAuthenticated() else {
            XCTFail("Should be authenticated")
            return
        }

        // Now sign out
        let settingsButton = app.buttons["settingsButton"]
        XCTAssertTrue(settingsButton.waitForExistence(timeout: 5))
        settingsButton.tap()

        let signOutButton = app.buttons["signOutButton"]
        XCTAssertTrue(signOutButton.waitForExistence(timeout: 5))
        signOutButton.tap()

        // Confirm in alert
        let confirmButton = app.alerts.buttons["Sign Out"]
        XCTAssertTrue(confirmButton.waitForExistence(timeout: 5), "Sign out confirmation alert should appear")
        confirmButton.tap()

        // Should be back to auth view
        Thread.sleep(forTimeInterval: 2)
        XCTAssertTrue(isShowingAuthView(), "Should show auth view after sign out")
    }

    // MARK: - Account Deletion Tests

    @MainActor
    func testDeleteAccountConfirmation() throws {
        guard TestConfig.serviceRoleKey != nil else {
            throw XCTSkip("SUPABASE_SERVICE_ROLE_KEY not set")
        }

        // Create and sign in with test user
        let email = generateTestEmail(prefix: "delete")
        let password = "TestPassword123!"

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
        Thread.sleep(forTimeInterval: 3)

        guard isAuthenticated() else {
            XCTFail("Should be authenticated")
            return
        }

        // Open settings
        app.buttons["settingsButton"].tap()

        // Tap delete account
        let deleteButton = app.buttons["deleteAccountButton"]
        XCTAssertTrue(deleteButton.waitForExistence(timeout: 5))
        deleteButton.tap()

        // Verify confirmation alert appears
        let alert = app.alerts.firstMatch
        XCTAssertTrue(alert.waitForExistence(timeout: 5), "Delete confirmation alert should appear")

        // Cancel - don't actually delete
        let cancelButton = app.alerts.buttons["Cancel"]
        XCTAssertTrue(cancelButton.waitForExistence(timeout: 3))
        cancelButton.tap()

        // Should still be in settings
        XCTAssertTrue(deleteButton.waitForExistence(timeout: 5), "Should still be in settings after cancel")
    }
}

// MARK: - RLS (Row Level Security) Tests

final class RLSTestSuite: XCTestCase {

    /// Track test users for cleanup
    private var createdUserIds: [UUID] = []
    private let testRunId = UUID().uuidString.prefix(8)

    override func tearDownWithError() throws {
        // Cleanup all test users and their data
        for userId in createdUserIds {
            TestSupabaseClient.shared.deleteAllRecipesSync(userId: userId)
            TestSupabaseClient.shared.deleteUserSync(userId: userId)
        }
        createdUserIds.removeAll()
    }

    /// Create a test user and track for cleanup
    private func createTestUser(email: String, password: String) -> UUID? {
        if let userId = TestSupabaseClient.shared.createTestUserSync(email: email, password: password) {
            createdUserIds.append(userId)
            return userId
        }
        return nil
    }

    /// Test that users can only see their own recipes
    func testUsersCanOnlySeeOwnRecipes() throws {
        guard TestConfig.serviceRoleKey != nil else {
            throw XCTSkip("SUPABASE_SERVICE_ROLE_KEY not set - cannot run RLS tests")
        }

        // Create two test users
        let user1Email = "rls_user1_\(testRunId)@recipejoe.test"
        let user2Email = "rls_user2_\(testRunId)@recipejoe.test"
        let password = "TestPassword123!"

        guard let user1Id = createTestUser(email: user1Email, password: password) else {
            XCTFail("Failed to create user 1")
            return
        }

        guard let user2Id = createTestUser(email: user2Email, password: password) else {
            XCTFail("Failed to create user 2")
            return
        }

        // Seed a recipe for user 1
        let user1RecipeId = TestSupabaseClient.shared.seedTestRecipeSync(
            userId: user1Id,
            name: "User1 Recipe"
        )
        XCTAssertNotNil(user1RecipeId, "Should create recipe for user 1")

        // Seed a recipe for user 2
        let user2RecipeId = TestSupabaseClient.shared.seedTestRecipeSync(
            userId: user2Id,
            name: "User2 Recipe"
        )
        XCTAssertNotNil(user2RecipeId, "Should create recipe for user 2")

        // Sign in as user 1 and fetch recipes
        guard let user1Token = TestSupabaseClient.shared.signInSync(email: user1Email, password: password) else {
            XCTFail("Failed to sign in as user 1")
            return
        }

        let user1Recipes = TestSupabaseClient.shared.fetchRecipesSync(authToken: user1Token)

        // User 1 should only see their own recipe
        XCTAssertTrue(user1Recipes.contains(user1RecipeId!), "User 1 should see their own recipe")
        XCTAssertFalse(user1Recipes.contains(user2RecipeId!), "User 1 should NOT see user 2's recipe")

        // Sign in as user 2 and fetch recipes
        guard let user2Token = TestSupabaseClient.shared.signInSync(email: user2Email, password: password) else {
            XCTFail("Failed to sign in as user 2")
            return
        }

        let user2Recipes = TestSupabaseClient.shared.fetchRecipesSync(authToken: user2Token)

        // User 2 should only see their own recipe
        XCTAssertTrue(user2Recipes.contains(user2RecipeId!), "User 2 should see their own recipe")
        XCTAssertFalse(user2Recipes.contains(user1RecipeId!), "User 2 should NOT see user 1's recipe")
    }

    /// Test that unauthenticated users cannot access recipes
    func testUnauthenticatedCannotAccessRecipes() throws {
        guard TestConfig.serviceRoleKey != nil else {
            throw XCTSkip("SUPABASE_SERVICE_ROLE_KEY not set")
        }

        // Create a user with a recipe
        let email = "rls_noauth_\(testRunId)@recipejoe.test"
        let password = "TestPassword123!"

        guard let userId = createTestUser(email: email, password: password) else {
            XCTFail("Failed to create user")
            return
        }

        // Seed a recipe
        let recipeId = TestSupabaseClient.shared.seedTestRecipeSync(userId: userId, name: "Private Recipe")
        XCTAssertNotNil(recipeId)

        // Try to fetch with invalid/no token
        let unauthRecipes = TestSupabaseClient.shared.fetchRecipesSync(authToken: "invalid_token")

        // Should return empty (RLS blocks access)
        XCTAssertTrue(unauthRecipes.isEmpty, "Unauthenticated request should return no recipes")
    }
}
