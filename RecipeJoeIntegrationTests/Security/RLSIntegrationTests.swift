//
//  RLSIntegrationTests.swift
//  RecipeJoeIntegrationTests
//
//  Integration tests for Supabase Row Level Security (RLS) policies
//  These are API-level tests that verify data isolation between users
//

import Testing
import Foundation

@Suite("Row Level Security Integration Tests")
struct RLSIntegrationTests {

    /// Track test users for cleanup
    private let testRunId = UUID().uuidString.prefix(8)

    // MARK: - Helper Methods

    private func generateTestEmail(prefix: String) -> String {
        return "\(prefix)_\(testRunId)@recipejoe.test"
    }

    // MARK: - RLS Tests

    @Test("Users can only see their own recipes")
    func testUsersCanOnlySeeOwnRecipes() async throws {
        guard IntegrationTestConfig.serviceRoleKey != nil else {
            print("⚠️ Skipping: SUPABASE_SERVICE_ROLE_KEY not set")
            return
        }

        let client = IntegrationTestClient.shared
        let password = IntegrationTestConfig.testPasswordForNewUsers

        // Create two test users
        let user1Email = generateTestEmail(prefix: "rls_user1")
        let user2Email = generateTestEmail(prefix: "rls_user2")

        var user1Id: UUID?
        var user2Id: UUID?

        defer {
            // Cleanup
            Task {
                if let id = user1Id {
                    try? await client.deleteTestRecipes(userId: id)
                    try? await client.deleteTestUser(userId: id)
                }
                if let id = user2Id {
                    try? await client.deleteTestRecipes(userId: id)
                    try? await client.deleteTestUser(userId: id)
                }
            }
        }

        // Create users
        user1Id = try await client.createTestUser(email: user1Email, password: password)
        user2Id = try await client.createTestUser(email: user2Email, password: password)

        guard let u1Id = user1Id, let u2Id = user2Id else {
            Issue.record("Failed to create test users")
            return
        }

        // Seed recipes for each user
        let user1RecipeId = try await client.seedTestRecipe(userId: u1Id, name: "User1 Recipe")
        let user2RecipeId = try await client.seedTestRecipe(userId: u2Id, name: "User2 Recipe")

        // Sign in as user 1 and fetch recipes
        let user1Auth = try await client.signIn(email: user1Email, password: password)
        let user1Recipes = try await client.fetchRecipes(authToken: user1Auth.accessToken)

        // User 1 should only see their own recipe
        #expect(user1Recipes.contains(user1RecipeId), "User 1 should see their own recipe")
        #expect(!user1Recipes.contains(user2RecipeId), "User 1 should NOT see user 2's recipe")

        // Sign in as user 2 and fetch recipes
        let user2Auth = try await client.signIn(email: user2Email, password: password)
        let user2Recipes = try await client.fetchRecipes(authToken: user2Auth.accessToken)

        // User 2 should only see their own recipe
        #expect(user2Recipes.contains(user2RecipeId), "User 2 should see their own recipe")
        #expect(!user2Recipes.contains(user1RecipeId), "User 2 should NOT see user 1's recipe")
    }

    @Test("Unauthenticated users cannot access recipes")
    func testUnauthenticatedCannotAccessRecipes() async throws {
        guard IntegrationTestConfig.serviceRoleKey != nil else {
            print("⚠️ Skipping: SUPABASE_SERVICE_ROLE_KEY not set")
            return
        }

        let client = IntegrationTestClient.shared
        let password = IntegrationTestConfig.testPasswordForNewUsers

        // Create a user with a recipe
        let email = generateTestEmail(prefix: "rls_noauth")
        var userId: UUID?

        defer {
            Task {
                if let id = userId {
                    try? await client.deleteTestRecipes(userId: id)
                    try? await client.deleteTestUser(userId: id)
                }
            }
        }

        userId = try await client.createTestUser(email: email, password: password)

        guard let uid = userId else {
            Issue.record("Failed to create test user")
            return
        }

        // Seed a recipe
        _ = try await client.seedTestRecipe(userId: uid, name: "Private Recipe")

        // Try to fetch without authentication
        let unauthRecipes = try await client.fetchRecipesUnauthenticated()

        // RLS should block access - either empty array or error
        #expect(unauthRecipes.isEmpty, "Unauthenticated request should return no recipes (RLS active)")
    }

    @Test("Invalid token cannot access recipes")
    func testInvalidTokenCannotAccessRecipes() async throws {
        guard IntegrationTestConfig.serviceRoleKey != nil else {
            print("⚠️ Skipping: SUPABASE_SERVICE_ROLE_KEY not set")
            return
        }

        let client = IntegrationTestClient.shared
        let password = IntegrationTestConfig.testPasswordForNewUsers

        // Create a user with a recipe
        let email = generateTestEmail(prefix: "rls_invalidtoken")
        var userId: UUID?

        defer {
            Task {
                if let id = userId {
                    try? await client.deleteTestRecipes(userId: id)
                    try? await client.deleteTestUser(userId: id)
                }
            }
        }

        userId = try await client.createTestUser(email: email, password: password)

        guard let uid = userId else {
            Issue.record("Failed to create test user")
            return
        }

        // Seed a recipe
        _ = try await client.seedTestRecipe(userId: uid, name: "Private Recipe")

        // Try to fetch with invalid token
        do {
            let recipes = try await client.fetchRecipes(authToken: "invalid_token_12345")
            // Should either throw or return empty
            #expect(recipes.isEmpty, "Invalid token should not return recipes")
        } catch {
            // Expected - invalid token should be rejected
            print("✅ Invalid token correctly rejected")
        }
    }
}
