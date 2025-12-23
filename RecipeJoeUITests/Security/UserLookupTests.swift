//
//  UserLookupTests.swift
//  RecipeJoeUITests
//
//  Tests to verify user lookup correctly identifies users by email.
//  This prevents the critical bug where test data was created for the wrong user.
//

import XCTest

/// Tests for user lookup functionality
final class UserLookupTests: XCTestCase {

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

    // MARK: - User Lookup Tests

    /// Test that getUserByEmailSync returns the correct user when multiple users exist
    func testGetUserByEmailReturnsCorrectUser() throws {
        guard TestConfig.serviceRoleKey != nil else {
            throw XCTSkip("SUPABASE_SERVICE_ROLE_KEY not set")
        }

        // Create two test users with distinct emails
        let user1Email = "lookup_user1_\(testRunId)@recipejoe.test"
        let user2Email = "lookup_user2_\(testRunId)@recipejoe.test"
        let password = TestConfig.testPasswordForNewUsers

        guard let user1Id = createTestUser(email: user1Email, password: password) else {
            XCTFail("Failed to create user 1")
            return
        }

        guard let user2Id = createTestUser(email: user2Email, password: password) else {
            XCTFail("Failed to create user 2")
            return
        }

        // Verify we got different user IDs
        XCTAssertNotEqual(user1Id, user2Id, "Users should have different IDs")

        // Now test that lookup returns the correct user
        let foundUser1 = TestSupabaseClient.shared.getUserByEmailSync(email: user1Email)
        let foundUser2 = TestSupabaseClient.shared.getUserByEmailSync(email: user2Email)

        XCTAssertEqual(foundUser1, user1Id, "Looking up user1 email should return user1 ID")
        XCTAssertEqual(foundUser2, user2Id, "Looking up user2 email should return user2 ID")
    }

    /// Test that getUserByEmailSync returns nil for non-existent email
    func testGetUserByEmailReturnsNilForNonExistent() throws {
        guard TestConfig.serviceRoleKey != nil else {
            throw XCTSkip("SUPABASE_SERVICE_ROLE_KEY not set")
        }

        let nonExistentEmail = "definitely_not_exists_\(testRunId)@recipejoe.test"
        let result = TestSupabaseClient.shared.getUserByEmailSync(email: nonExistentEmail)

        XCTAssertNil(result, "Lookup for non-existent email should return nil")
    }

    /// Test that getUserByEmailSync is case-insensitive
    func testGetUserByEmailIsCaseInsensitive() throws {
        guard TestConfig.serviceRoleKey != nil else {
            throw XCTSkip("SUPABASE_SERVICE_ROLE_KEY not set")
        }

        let email = "CaseSensitive_\(testRunId)@recipejoe.test"
        let password = TestConfig.testPasswordForNewUsers

        guard let userId = createTestUser(email: email.lowercased(), password: password) else {
            XCTFail("Failed to create user")
            return
        }

        // Try to find with different casing
        let foundUpper = TestSupabaseClient.shared.getUserByEmailSync(email: email.uppercased())
        let foundLower = TestSupabaseClient.shared.getUserByEmailSync(email: email.lowercased())
        let foundMixed = TestSupabaseClient.shared.getUserByEmailSync(email: email)

        // All should find the same user
        XCTAssertEqual(foundUpper, userId, "Uppercase lookup should find user")
        XCTAssertEqual(foundLower, userId, "Lowercase lookup should find user")
        XCTAssertEqual(foundMixed, userId, "Mixed case lookup should find user")
    }

    /// Critical test: Verify that test recipes are created for the correct user
    func testRecipesCreatedForCorrectUser() throws {
        guard TestConfig.serviceRoleKey != nil else {
            throw XCTSkip("SUPABASE_SERVICE_ROLE_KEY not set")
        }

        // Create a test user
        let testEmail = "recipe_owner_\(testRunId)@recipejoe.test"
        let password = TestConfig.testPasswordForNewUsers

        guard let testUserId = createTestUser(email: testEmail, password: password) else {
            XCTFail("Failed to create test user")
            return
        }

        // Create a recipe for this user
        let recipeId = TestSupabaseClient.shared.seedTestRecipeSync(
            userId: testUserId,
            name: "Owner Verification Recipe"
        )
        XCTAssertNotNil(recipeId, "Should create recipe")

        // Sign in as the test user and verify they can see the recipe
        guard let token = TestSupabaseClient.shared.signInSync(email: testEmail, password: password) else {
            XCTFail("Failed to sign in as test user")
            return
        }

        let userRecipes = TestSupabaseClient.shared.fetchRecipesSync(authToken: token)

        // The user should see their recipe
        XCTAssertTrue(userRecipes.contains(recipeId!), "User should see their own recipe")
    }

    /// Verify that the configured test user email is correctly looked up
    func testConfiguredTestUserLookup() throws {
        guard TestConfig.serviceRoleKey != nil else {
            throw XCTSkip("SUPABASE_SERVICE_ROLE_KEY not set")
        }

        guard let testEmail = TestConfig.testUserEmail else {
            throw XCTSkip("TEST_USER_EMAIL not configured")
        }

        // Look up the test user
        let testUserId = TestSupabaseClient.shared.getUserByEmailSync(email: testEmail)

        if testUserId != nil {
            print("✅ Configured test user found with ID: \(testUserId!)")

            // Verify it's the correct user by signing in
            if let password = TestConfig.testUserPassword,
               let token = TestSupabaseClient.shared.signInSync(email: testEmail, password: password) {
                print("✅ Successfully signed in as test user")

                // Fetch recipes to ensure we're authenticated correctly
                _ = TestSupabaseClient.shared.fetchRecipesSync(authToken: token)
            }
        } else {
            print("⚠️ Configured test user not found - will be created on next test run")
        }
    }

    /// Test that different users cannot see each other's test recipes (RLS verification)
    func testRLSPreventsDataLeakage() throws {
        guard TestConfig.serviceRoleKey != nil else {
            throw XCTSkip("SUPABASE_SERVICE_ROLE_KEY not set")
        }

        // Create two test users
        let user1Email = "rls_test1_\(testRunId)@recipejoe.test"
        let user2Email = "rls_test2_\(testRunId)@recipejoe.test"
        let password = TestConfig.testPasswordForNewUsers

        guard let user1Id = createTestUser(email: user1Email, password: password) else {
            XCTFail("Failed to create user 1")
            return
        }

        guard let user2Id = createTestUser(email: user2Email, password: password) else {
            XCTFail("Failed to create user 2")
            return
        }

        // Create recipe for user 1
        let recipeId = TestSupabaseClient.shared.seedTestRecipeSync(
            userId: user1Id,
            name: "User1 Private Recipe"
        )
        XCTAssertNotNil(recipeId, "Should create recipe for user 1")

        // Sign in as user 2 and try to access user 1's recipe
        guard let user2Token = TestSupabaseClient.shared.signInSync(email: user2Email, password: password) else {
            XCTFail("Failed to sign in as user 2")
            return
        }

        let user2Recipes = TestSupabaseClient.shared.fetchRecipesSync(authToken: user2Token)

        // User 2 should NOT see user 1's recipe
        XCTAssertFalse(
            user2Recipes.contains(recipeId!),
            "CRITICAL: User 2 can see User 1's recipe - RLS is not working!"
        )
    }
}
