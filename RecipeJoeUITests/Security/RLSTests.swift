//
//  RLSTests.swift
//  RecipeJoeUITests
//
//  Tests for Supabase Row Level Security (RLS) policies.
//  These are API-level tests that verify data isolation between users.
//
//  Note: These tests don't use UI, but live in UITests target
//  because they need TestSupabaseClient for admin operations.
//

import XCTest

/// Tests for Supabase Row Level Security (RLS) policies
final class RLSTests: XCTestCase {

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

    // MARK: - RLS Tests

    /// Test that users can only see their own recipes
    func testUsersCanOnlySeeOwnRecipes() throws {
        guard TestConfig.serviceRoleKey != nil else {
            throw XCTSkip("SUPABASE_SERVICE_ROLE_KEY not set - cannot run RLS tests")
        }

        // Create two test users
        let user1Email = "rls_user1_\(testRunId)@recipejoe.test"
        let user2Email = "rls_user2_\(testRunId)@recipejoe.test"
        let password = TestConfig.testPasswordForNewUsers

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
        let password = TestConfig.testPasswordForNewUsers

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
