//
//  BaseUITestCase.swift
//  RecipeJoeUITests
//
//  Base test case class with test data management helpers
//

import XCTest

/// Base class for UI tests with test data management
class BaseUITestCase: XCTestCase {

    // MARK: - Properties

    var app: XCUIApplication!

    /// Track seeded recipe IDs for cleanup
    private var seededRecipeIds: [UUID] = []

    /// The test user's UUID (created/fetched during setup)
    private static var testUserId: UUID?

    /// Whether test data has been seeded for this test run
    private static var hasSeededTestData = false

    // MARK: - Setup / Teardown

    override func setUpWithError() throws {
        continueAfterFailure = false

        app = XCUIApplication()

        // Set locale to English for consistent test assertions
        app.launchArguments += ["-AppleLanguages", "(en)"]
        app.launchArguments += ["-AppleLocale", "en_US"]
        app.launchArguments += ["-appLanguage", "en"]

        // Mark as UI test mode
        app.launchArguments += ["-UITestMode", "true"]

        // Ensure test user exists and seed data (once per test run)
        try ensureTestUserAndData()
    }

    /// Ensures the test user exists and test data is seeded
    private func ensureTestUserAndData() throws {
        // Skip if no service key (can't manage test data)
        guard TestConfig.serviceRoleKey != nil else {
            print("⚠️ SUPABASE_SERVICE_ROLE_KEY not set - skipping test user setup")
            return
        }

        // Skip if no credentials configured
        guard let email = TestConfig.testUserEmail,
              let password = TestConfig.testUserPassword else {
            print("⚠️ TEST_USER_EMAIL or TEST_USER_PASSWORD not set - skipping test user setup")
            return
        }

        // Check if we already have the test user ID
        if BaseUITestCase.testUserId == nil {
            // Try to find existing user
            if let existingUserId = TestSupabaseClient.shared.getUserByEmailSync(email: email) {
                BaseUITestCase.testUserId = existingUserId
                print("✅ Found existing test user: \(existingUserId)")
            } else {
                // Create the test user
                if let newUserId = TestSupabaseClient.shared.createTestUserSync(email: email, password: password) {
                    BaseUITestCase.testUserId = newUserId
                    print("✅ Created test user: \(newUserId) with email: \(email)")
                } else {
                    print("⚠️ Failed to create test user - check SUPABASE_SERVICE_ROLE_KEY")
                }
            }
        }

        // Seed test recipes if not already done
        if !BaseUITestCase.hasSeededTestData, let userId = BaseUITestCase.testUserId {
            let existingCount = TestSupabaseClient.shared.countTestRecipesSync(userId: userId)
            if existingCount < 10 {
                // Clean up any partial data and re-seed
                TestSupabaseClient.shared.deleteTestRecipesSync(userId: userId)
                let seeded = TestSupabaseClient.shared.seedTestRecipesSync(userId: userId, count: 20)
                print("✅ Seeded \(seeded) test recipes")
            } else {
                print("✅ Test recipes already exist (\(existingCount) recipes)")
            }
            BaseUITestCase.hasSeededTestData = true
        }
    }

    override func tearDownWithError() throws {
        // Cleanup seeded test data
        cleanupSeededRecipes()
        app = nil
    }

    // MARK: - Authentication Helpers

    /// Require the user to be authenticated before proceeding
    /// Will automatically sign in with test credentials if auth screen is shown
    /// - Throws: XCTSkip if credentials not configured or sign-in fails
    @MainActor
    func requireAuthentication() throws {
        // First check if already authenticated
        let tabBar = app.tabBars.firstMatch
        if tabBar.waitForExistence(timeout: 3) {
            return // Already authenticated
        }

        // Not authenticated - try to sign in with test credentials
        guard let email = TestConfig.testUserEmail,
              let password = TestConfig.testUserPassword else {
            throw XCTSkip("TEST_USER_EMAIL and TEST_USER_PASSWORD environment variables not set")
        }

        // Look for the email text field (sign-in screen)
        let emailField = app.textFields["emailTextField"]
        guard emailField.waitForExistence(timeout: TestConfig.authTimeout) else {
            throw XCTSkip("Neither authenticated nor showing sign-in screen")
        }

        // Enter email
        emailField.tap()
        emailField.typeText(email)

        // Enter password
        let passwordField = app.secureTextFields["passwordTextField"]
        guard passwordField.waitForExistence(timeout: 3) else {
            throw XCTSkip("Password field not found")
        }
        passwordField.tap()
        passwordField.typeText(password)

        // Tap sign in button
        let signInButton = app.buttons["emailAuthButton"]
        guard signInButton.waitForExistence(timeout: 3) else {
            throw XCTSkip("Sign in button not found")
        }
        signInButton.tap()

        // Wait for authentication to complete
        guard tabBar.waitForExistence(timeout: TestConfig.authTimeout) else {
            // Check for error message
            let errorMessage = app.staticTexts["authErrorMessage"]
            if errorMessage.exists {
                throw XCTSkip("Sign-in failed - check test credentials")
            }
            throw XCTSkip("Sign-in did not complete in time")
        }
    }

    /// Check if the app is showing the authenticated state
    @MainActor
    func isAuthenticated() -> Bool {
        let tabBar = app.tabBars.firstMatch
        return tabBar.waitForExistence(timeout: TestConfig.authTimeout)
    }

    /// Sign out the current user (for tests that need to start signed out)
    @MainActor
    func signOut() {
        guard isAuthenticated() else { return }

        openSettings()

        let signOutButton = app.buttons["signOutButton"]
        guard signOutButton.waitForExistence(timeout: 5) else { return }
        signOutButton.tap()

        // Confirm sign out in alert
        let confirmButton = app.alerts.buttons["Sign Out"]
        if confirmButton.waitForExistence(timeout: 3) {
            confirmButton.tap()
        }

        // Wait for auth screen
        Thread.sleep(forTimeInterval: 2)
    }

    // MARK: - Test Data Seeding

    /// Seed a single test recipe (synchronous)
    /// - Parameter name: Recipe name (will be prefixed with test identifier)
    /// - Returns: The created recipe's UUID, or nil if seeding failed
    func seedRecipe(name: String = "Test Recipe") -> UUID? {
        guard let userId = TestConfig.testUserId else {
            print("⚠️ TestConfig.testUserId not set - cannot seed recipes")
            return nil
        }

        if let recipeId = TestSupabaseClient.shared.seedTestRecipeSync(userId: userId, name: name) {
            seededRecipeIds.append(recipeId)
            return recipeId
        }
        return nil
    }

    // MARK: - Cleanup

    /// Clean up all seeded test recipes (called in tearDown)
    private func cleanupSeededRecipes() {
        guard let userId = TestConfig.testUserId else { return }

        // Delete all test recipes for this user
        TestSupabaseClient.shared.deleteTestRecipesSync(userId: userId)
        seededRecipeIds.removeAll()
    }

    /// Manually cleanup all test recipes for the test user
    func cleanupAllTestRecipes() {
        guard let userId = TestConfig.testUserId else { return }
        TestSupabaseClient.shared.deleteTestRecipesSync(userId: userId)
    }

    // MARK: - Navigation Helpers

    /// Navigate to the Add Recipe tab
    @MainActor
    func navigateToAddRecipe() {
        let addTab = app.tabBars.buttons["Add Recipe"]
        if addTab.waitForExistence(timeout: TestConfig.standardTimeout) {
            addTab.tap()
        }
    }

    /// Navigate to the Home tab
    @MainActor
    func navigateToHome() {
        let homeTab = app.tabBars.buttons["Home"]
        if homeTab.waitForExistence(timeout: TestConfig.standardTimeout) {
            homeTab.tap()
        }
    }

    /// Navigate to the Search tab
    @MainActor
    func navigateToSearch() {
        let searchTab = app.tabBars.buttons["Search"]
        if searchTab.waitForExistence(timeout: TestConfig.standardTimeout) {
            searchTab.tap()
        }
    }

    /// Open the Settings sheet
    @MainActor
    func openSettings() {
        let settingsButton = app.buttons["settingsButton"]
        if settingsButton.waitForExistence(timeout: TestConfig.standardTimeout) {
            settingsButton.tap()
        }
    }

    // MARK: - Wait Helpers

    /// Wait for either of two elements to appear
    @MainActor
    func waitForEither(_ element1: XCUIElement, _ element2: XCUIElement, timeout: TimeInterval) -> XCUIElement? {
        let start = Date()
        while Date().timeIntervalSince(start) < timeout {
            if element1.exists { return element1 }
            if element2.exists { return element2 }
            Thread.sleep(forTimeInterval: 0.5)
        }
        return nil
    }
}
