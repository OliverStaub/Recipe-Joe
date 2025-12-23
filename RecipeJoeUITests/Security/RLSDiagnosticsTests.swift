//
//  RLSDiagnosticsTests.swift
//  RecipeJoeUITests
//
//  Diagnostic tests to identify RLS issues.
//  These tests help identify why test data might be visible to other users.
//

import XCTest

/// Diagnostic tests for RLS issues
final class RLSDiagnosticsTests: XCTestCase {

    // MARK: - Diagnostic Tests

    /// Diagnose if there are recipes with NULL user_id (visible to no one with RLS, but suggests data issue)
    func testDiagnoseRecipesWithNullUserId() throws {
        guard let serviceKey = TestConfig.serviceRoleKey else {
            throw XCTSkip("SUPABASE_SERVICE_ROLE_KEY not set")
        }

        // Use service role to query ALL recipes regardless of RLS
        guard let url = URL(string: "\(TestConfig.supabaseURL)/rest/v1/recipes?select=id,name,user_id&user_id=is.null") else {
            XCTFail("Invalid URL")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(serviceKey, forHTTPHeaderField: "apikey")

        let semaphore = DispatchSemaphore(value: 0)
        var foundRecipes: [[String: Any]] = []

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let data = data,
               let recipes = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
                foundRecipes = recipes
            }
            semaphore.signal()
        }.resume()

        _ = semaphore.wait(timeout: .now() + 15)

        if foundRecipes.isEmpty {
            print("✅ No recipes with NULL user_id found - this is correct")
        } else {
            // Log warning but don't fail - this is a diagnostic test
            print("⚠️ WARNING: Found \(foundRecipes.count) recipes with NULL user_id:")
            for recipe in foundRecipes {
                let id = recipe["id"] as? String ?? "unknown"
                let name = recipe["name"] as? String ?? "unknown"
                print("   - \(name) (id: \(id))")
            }
            print("⚠️ These recipes should be deleted or assigned to a user")
        }
    }

    /// Diagnose if there are test recipes ([TEST] prefix) in the database
    func testDiagnoseTestRecipesInDatabase() throws {
        guard let serviceKey = TestConfig.serviceRoleKey else {
            throw XCTSkip("SUPABASE_SERVICE_ROLE_KEY not set")
        }

        let encodedPrefix = "%5BTEST%5D" // URL-encoded "[TEST]"
        guard let url = URL(string: "\(TestConfig.supabaseURL)/rest/v1/recipes?select=id,name,user_id&name=like.\(encodedPrefix)*") else {
            XCTFail("Invalid URL")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(serviceKey, forHTTPHeaderField: "apikey")

        let semaphore = DispatchSemaphore(value: 0)
        var foundRecipes: [[String: Any]] = []

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let data = data,
               let recipes = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
                foundRecipes = recipes
            }
            semaphore.signal()
        }.resume()

        _ = semaphore.wait(timeout: .now() + 15)

        print("\n📊 TEST DATA DIAGNOSIS:")
        print("Found \(foundRecipes.count) recipes with [TEST] prefix:")

        var userIdCounts: [String: Int] = [:]
        for recipe in foundRecipes {
            let userId = recipe["user_id"] as? String ?? "NULL"
            let name = recipe["name"] as? String ?? "unknown"
            userIdCounts[userId, default: 0] += 1
            print("   - \(name) | user_id: \(userId)")
        }

        print("\n📈 Recipes per user_id:")
        for (userId, count) in userIdCounts.sorted(by: { $0.value > $1.value }) {
            print("   - \(userId): \(count) recipes")
        }

        // This is informational - we want to see what test data exists
        if foundRecipes.isEmpty {
            print("✅ No test recipes found - database is clean")
        } else {
            print("⚠️ Test recipes exist in database - may need cleanup")
        }
    }

    /// Verify RLS is actually enabled on recipes table
    func testVerifyRLSIsEnabled() throws {
        guard let serviceKey = TestConfig.serviceRoleKey else {
            throw XCTSkip("SUPABASE_SERVICE_ROLE_KEY not set")
        }

        // This query checks if RLS is enabled on the recipes table
        // Using the pg_tables view via PostgREST isn't straightforward,
        // so we test RLS behavior instead

        let testRunId = UUID().uuidString.prefix(8)
        let testEmail = "rls_verify_\(testRunId)@recipejoe.test"
        let password = TestConfig.testPasswordForNewUsers

        // Create test user
        guard let userId = TestSupabaseClient.shared.createTestUserSync(email: testEmail, password: password) else {
            XCTFail("Failed to create test user")
            return
        }
        defer {
            TestSupabaseClient.shared.deleteAllRecipesSync(userId: userId)
            TestSupabaseClient.shared.deleteUserSync(userId: userId)
        }

        // Create recipe with service role (bypasses RLS)
        let recipeId = TestSupabaseClient.shared.seedTestRecipeSync(
            userId: userId,
            name: "RLS Verify Recipe"
        )
        XCTAssertNotNil(recipeId, "Should create recipe")

        // Try to fetch WITHOUT auth (should return empty if RLS is working)
        guard let url = URL(string: "\(TestConfig.supabaseURL)/rest/v1/recipes?id=eq.\(recipeId!.uuidString)") else {
            XCTFail("Invalid URL")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        // Use anon key (not service role) to respect RLS
        if let anonKey = TestConfig.supabaseAnonKey {
            request.setValue(anonKey, forHTTPHeaderField: "apikey")
        }
        // NO auth header - simulating unauthenticated request

        let semaphore = DispatchSemaphore(value: 0)
        var foundRecipes: [[String: Any]] = []

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let data = data,
               let recipes = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
                foundRecipes = recipes
            }
            semaphore.signal()
        }.resume()

        _ = semaphore.wait(timeout: .now() + 15)

        if foundRecipes.isEmpty {
            print("✅ RLS is working - unauthenticated request cannot see the recipe")
        } else {
            print("❌ RLS FAILURE - unauthenticated request can see recipes!")
            XCTFail("RLS is not working - unauthenticated users can see recipes")
        }
    }

    /// Test that a user cannot see another user's recipes (core RLS test)
    func testUserCannotSeeOtherUsersRecipes() throws {
        guard let serviceKey = TestConfig.serviceRoleKey else {
            throw XCTSkip("SUPABASE_SERVICE_ROLE_KEY not set")
        }

        let testRunId = UUID().uuidString.prefix(8)

        // Create user A
        let userAEmail = "rls_userA_\(testRunId)@recipejoe.test"
        guard let userAId = TestSupabaseClient.shared.createTestUserSync(
            email: userAEmail,
            password: TestConfig.testPasswordForNewUsers
        ) else {
            XCTFail("Failed to create user A")
            return
        }

        // Create user B
        let userBEmail = "rls_userB_\(testRunId)@recipejoe.test"
        guard let userBId = TestSupabaseClient.shared.createTestUserSync(
            email: userBEmail,
            password: TestConfig.testPasswordForNewUsers
        ) else {
            TestSupabaseClient.shared.deleteUserSync(userId: userAId)
            XCTFail("Failed to create user B")
            return
        }

        defer {
            TestSupabaseClient.shared.deleteAllRecipesSync(userId: userAId)
            TestSupabaseClient.shared.deleteAllRecipesSync(userId: userBId)
            TestSupabaseClient.shared.deleteUserSync(userId: userAId)
            TestSupabaseClient.shared.deleteUserSync(userId: userBId)
        }

        // Create recipe for user A
        let recipeAId = TestSupabaseClient.shared.seedTestRecipeSync(
            userId: userAId,
            name: "User A Secret Recipe"
        )
        XCTAssertNotNil(recipeAId)

        // Sign in as user B
        guard let userBToken = TestSupabaseClient.shared.signInSync(
            email: userBEmail,
            password: TestConfig.testPasswordForNewUsers
        ) else {
            XCTFail("Failed to sign in as user B")
            return
        }

        // User B tries to fetch all recipes
        let userBRecipes = TestSupabaseClient.shared.fetchRecipesSync(authToken: userBToken)

        // User B should NOT see user A's recipe
        if userBRecipes.contains(recipeAId!) {
            print("❌ RLS FAILURE - User B can see User A's recipe!")
            XCTFail("RLS not working: User B can see User A's recipe")
        } else {
            print("✅ RLS is working - User B cannot see User A's recipe")
        }
    }

    /// Clean up all test data from the database
    func testCleanupAllTestData() throws {
        guard let serviceKey = TestConfig.serviceRoleKey else {
            throw XCTSkip("SUPABASE_SERVICE_ROLE_KEY not set")
        }

        // First, find all test recipes
        let encodedPrefix = "%5BTEST%5D" // URL-encoded "[TEST]"
        guard let findUrl = URL(string: "\(TestConfig.supabaseURL)/rest/v1/recipes?select=id&name=like.\(encodedPrefix)*") else {
            XCTFail("Invalid URL")
            return
        }

        var findRequest = URLRequest(url: findUrl)
        findRequest.httpMethod = "GET"
        findRequest.setValue(serviceKey, forHTTPHeaderField: "apikey")

        let findSemaphore = DispatchSemaphore(value: 0)
        var recipeIds: [String] = []

        URLSession.shared.dataTask(with: findRequest) { data, response, error in
            if let data = data,
               let recipes = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
                recipeIds = recipes.compactMap { $0["id"] as? String }
            }
            findSemaphore.signal()
        }.resume()

        _ = findSemaphore.wait(timeout: .now() + 15)

        print("Found \(recipeIds.count) test recipes to clean up")

        if recipeIds.isEmpty {
            print("✅ No test data to clean up")
            return
        }

        // Delete all test recipes (cascade will delete steps and ingredients)
        guard let deleteUrl = URL(string: "\(TestConfig.supabaseURL)/rest/v1/recipes?name=like.\(encodedPrefix)*") else {
            XCTFail("Invalid URL")
            return
        }

        var deleteRequest = URLRequest(url: deleteUrl)
        deleteRequest.httpMethod = "DELETE"
        deleteRequest.setValue(serviceKey, forHTTPHeaderField: "apikey")

        let deleteSemaphore = DispatchSemaphore(value: 0)
        var deleteSuccess = false

        URLSession.shared.dataTask(with: deleteRequest) { data, response, error in
            if let httpResponse = response as? HTTPURLResponse {
                deleteSuccess = (200...299).contains(httpResponse.statusCode)
                print("Delete response: \(httpResponse.statusCode)")
            }
            deleteSemaphore.signal()
        }.resume()

        _ = deleteSemaphore.wait(timeout: .now() + 30)

        if deleteSuccess {
            print("✅ Successfully cleaned up \(recipeIds.count) test recipes")
        } else {
            XCTFail("Failed to clean up test data")
        }
    }
}
