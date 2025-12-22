//
//  TestSupabaseClient.swift
//  RecipeJoeUITests
//
//  Supabase REST client for test data and user management
//  Uses synchronous calls suitable for XCTest setUp/tearDown
//

import Foundation

/// Supabase client for UI test data and user management
/// Uses synchronous methods to work in XCTest setUp/tearDown
final class TestSupabaseClient {

    // MARK: - Singleton

    static let shared = TestSupabaseClient()

    private init() {}

    // MARK: - User Management (Admin API)

    /// Create a test user with email/password via Admin API
    /// - Parameters:
    ///   - email: Test user's email
    ///   - password: Test user's password
    /// - Returns: The created user's UUID, or nil on failure
    func createTestUserSync(email: String, password: String) -> UUID? {
        guard let serviceKey = TestConfig.serviceRoleKey else {
            print("⚠️ TestSupabaseClient: SUPABASE_SERVICE_ROLE_KEY not set, cannot create user")
            return nil
        }

        guard let url = URL(string: "\(TestConfig.supabaseURL)/auth/v1/admin/users") else {
            return nil
        }

        let userData: [String: Any] = [
            "email": email,
            "password": password,
            "email_confirm": true  // Auto-confirm for testing
        ]

        guard let body = try? JSONSerialization.data(withJSONObject: userData) else {
            return nil
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        // New Supabase API keys: use secret key directly in apikey header (not Bearer)
        request.setValue(serviceKey, forHTTPHeaderField: "apikey")
        request.httpBody = body

        var userId: UUID?
        let semaphore = DispatchSemaphore(value: 0)

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let httpResponse = response as? HTTPURLResponse {
                print("📡 Create user response status: \(httpResponse.statusCode)")
            }
            if let data = data,
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let idString = json["id"] as? String,
               let uuid = UUID(uuidString: idString) {
                userId = uuid
                print("✅ Created user with ID: \(uuid)")
            } else if let error = error {
                print("❌ TestSupabaseClient create user network error: \(error)")
            } else if let data = data {
                let responseString = String(data: data, encoding: .utf8) ?? "Unable to decode"
                print("❌ TestSupabaseClient create user failed. Response: \(responseString)")
            }
            semaphore.signal()
        }.resume()

        _ = semaphore.wait(timeout: .now() + 15)
        return userId
    }

    /// Delete a user via Admin API
    /// SAFETY: Only deletes users with @recipejoe.test email domain to prevent accidental production data loss
    /// - Parameter userId: The user's UUID to delete
    func deleteUserSync(userId: UUID) {
        guard let serviceKey = TestConfig.serviceRoleKey else {
            print("⚠️ TestSupabaseClient: SUPABASE_SERVICE_ROLE_KEY not set, cannot delete user")
            return
        }

        // SAFETY CHECK: First get the user's email and verify it's a test account
        guard let email = getUserEmailByIdSync(userId: userId) else {
            print("🚫 SAFETY: Cannot delete user \(userId) - could not verify email")
            return
        }

        guard email.hasSuffix("@recipejoe.test") else {
            print("🚫 SAFETY: Refusing to delete non-test user!")
            print("🚫 Email: \(email)")
            print("🚫 Only users with @recipejoe.test emails can be deleted by tests")
            return
        }

        print("✅ Verified test user, proceeding with deletion: \(email)")

        guard let url = URL(string: "\(TestConfig.supabaseURL)/auth/v1/admin/users/\(userId.uuidString)") else {
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        // New Supabase API keys: use secret key directly in apikey header (not Bearer)
        request.setValue(serviceKey, forHTTPHeaderField: "apikey")

        let semaphore = DispatchSemaphore(value: 0)

        URLSession.shared.dataTask(with: request) { _, response, error in
            if let error = error {
                print("⚠️ TestSupabaseClient delete user error: \(error)")
            } else if let httpResponse = response as? HTTPURLResponse,
                      !(200...299).contains(httpResponse.statusCode) {
                print("⚠️ TestSupabaseClient delete user failed with status: \(httpResponse.statusCode)")
            } else {
                print("✅ Successfully deleted test user: \(email)")
            }
            semaphore.signal()
        }.resume()

        _ = semaphore.wait(timeout: .now() + 10)
    }

    /// Get user email by ID via Admin API (for safety verification)
    /// - Parameter userId: The user's UUID
    /// - Returns: The user's email if found
    private func getUserEmailByIdSync(userId: UUID) -> String? {
        guard let serviceKey = TestConfig.serviceRoleKey else {
            return nil
        }

        guard let url = URL(string: "\(TestConfig.supabaseURL)/auth/v1/admin/users/\(userId.uuidString)") else {
            return nil
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(serviceKey, forHTTPHeaderField: "apikey")

        var email: String?
        let semaphore = DispatchSemaphore(value: 0)

        URLSession.shared.dataTask(with: request) { data, _, _ in
            if let data = data,
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let userEmail = json["email"] as? String {
                email = userEmail
            }
            semaphore.signal()
        }.resume()

        _ = semaphore.wait(timeout: .now() + 10)
        return email
    }

    /// Get user by email via Admin API
    /// - Parameter email: The user's email
    /// - Returns: The user's UUID if found
    func getUserByEmailSync(email: String) -> UUID? {
        guard let serviceKey = TestConfig.serviceRoleKey else {
            return nil
        }

        let encodedEmail = email.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? email
        guard let url = URL(string: "\(TestConfig.supabaseURL)/auth/v1/admin/users?email=\(encodedEmail)") else {
            return nil
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        // New Supabase API keys: use secret key directly in apikey header (not Bearer)
        request.setValue(serviceKey, forHTTPHeaderField: "apikey")

        var userId: UUID?
        let semaphore = DispatchSemaphore(value: 0)

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let httpResponse = response as? HTTPURLResponse {
                print("📡 Get user by email response status: \(httpResponse.statusCode)")
            }
            if let data = data,
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let users = json["users"] as? [[String: Any]] {
                print("📋 Found \(users.count) users matching email")
                if let firstUser = users.first,
                   let idString = firstUser["id"] as? String {
                    userId = UUID(uuidString: idString)
                    print("✅ Found user: \(idString)")
                }
            } else if let data = data {
                let responseString = String(data: data, encoding: .utf8) ?? "Unable to decode"
                print("❌ Get user by email failed. Response: \(responseString)")
            }
            semaphore.signal()
        }.resume()

        _ = semaphore.wait(timeout: .now() + 10)
        return userId
    }

    // MARK: - Recipe Fetching (for RLS tests)

    /// Fetch recipes for a user (requires auth token)
    /// - Parameters:
    ///   - authToken: The user's JWT token
    /// - Returns: Array of recipe IDs the user can see
    func fetchRecipesSync(authToken: String) -> [UUID] {
        guard let url = URL(string: "\(TestConfig.supabaseURL)/rest/v1/recipes?select=id") else {
            return []
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        if let anonKey = TestConfig.supabaseAnonKey {
            request.setValue(anonKey, forHTTPHeaderField: "apikey")
        }
        request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")

        var recipeIds: [UUID] = []
        let semaphore = DispatchSemaphore(value: 0)

        URLSession.shared.dataTask(with: request) { data, _, _ in
            if let data = data,
               let recipes = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
                recipeIds = recipes.compactMap { recipe in
                    guard let idString = recipe["id"] as? String else { return nil }
                    return UUID(uuidString: idString)
                }
            }
            semaphore.signal()
        }.resume()

        _ = semaphore.wait(timeout: .now() + 10)
        return recipeIds
    }

    /// Sign in and get auth token
    /// - Parameters:
    ///   - email: User's email
    ///   - password: User's password
    /// - Returns: JWT access token if successful
    func signInSync(email: String, password: String) -> String? {
        guard let url = URL(string: "\(TestConfig.supabaseURL)/auth/v1/token?grant_type=password") else {
            return nil
        }

        let credentials: [String: String] = [
            "email": email,
            "password": password
        ]

        guard let body = try? JSONSerialization.data(withJSONObject: credentials) else {
            return nil
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let anonKey = TestConfig.supabaseAnonKey {
            request.setValue(anonKey, forHTTPHeaderField: "apikey")
        }
        request.httpBody = body

        var accessToken: String?
        let semaphore = DispatchSemaphore(value: 0)

        URLSession.shared.dataTask(with: request) { data, _, _ in
            if let data = data,
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let token = json["access_token"] as? String {
                accessToken = token
            }
            semaphore.signal()
        }.resume()

        _ = semaphore.wait(timeout: .now() + 10)
        return accessToken
    }

    // MARK: - Cleanup Methods

    /// Delete all recipes for a specific user (synchronous for tearDown)
    /// - Parameter userId: The user's UUID
    func deleteAllRecipesSync(userId: UUID) {
        guard let serviceKey = TestConfig.serviceRoleKey else {
            print("⚠️ TestSupabaseClient: SUPABASE_SERVICE_ROLE_KEY not set, skipping cleanup")
            return
        }

        let urlString = "\(TestConfig.supabaseURL)/rest/v1/recipes?user_id=eq.\(userId.uuidString)"
        guard let url = URL(string: urlString) else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        // New Supabase API keys: use secret key directly in apikey header (not Bearer)
        request.setValue(serviceKey, forHTTPHeaderField: "apikey")

        let semaphore = DispatchSemaphore(value: 0)

        URLSession.shared.dataTask(with: request) { _, response, error in
            if let error = error {
                print("⚠️ TestSupabaseClient cleanup error: \(error)")
            } else if let httpResponse = response as? HTTPURLResponse,
                      !(200...299).contains(httpResponse.statusCode) {
                print("⚠️ TestSupabaseClient cleanup failed with status: \(httpResponse.statusCode)")
            }
            semaphore.signal()
        }.resume()

        // Wait up to 10 seconds for cleanup
        _ = semaphore.wait(timeout: .now() + 10)
    }

    /// Delete only test recipes (those with the test prefix) for a user
    /// - Parameter userId: The user's UUID
    func deleteTestRecipesSync(userId: UUID) {
        guard let serviceKey = TestConfig.serviceRoleKey else {
            print("⚠️ TestSupabaseClient: SUPABASE_SERVICE_ROLE_KEY not set, skipping cleanup")
            return
        }

        // URL encode the prefix for the LIKE query
        let encodedPrefix = TestConfig.testRecipePrefix
            .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? TestConfig.testRecipePrefix

        let urlString = "\(TestConfig.supabaseURL)/rest/v1/recipes?user_id=eq.\(userId.uuidString)&name=like.\(encodedPrefix)*"
        guard let url = URL(string: urlString) else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        // New Supabase API keys: use secret key directly in apikey header (not Bearer)
        request.setValue(serviceKey, forHTTPHeaderField: "apikey")

        let semaphore = DispatchSemaphore(value: 0)

        URLSession.shared.dataTask(with: request) { _, response, error in
            if let error = error {
                print("⚠️ TestSupabaseClient cleanup error: \(error)")
            }
            semaphore.signal()
        }.resume()

        _ = semaphore.wait(timeout: .now() + 10)
    }

    // MARK: - Seeding Methods

    /// Seed a test recipe (synchronous)
    /// - Parameters:
    ///   - userId: The user's UUID
    ///   - name: Recipe name
    ///   - category: Recipe category
    ///   - cuisine: Recipe cuisine
    ///   - totalTimeMinutes: Total cook time in minutes
    /// - Returns: The created recipe's UUID, or nil on failure
    func seedTestRecipeSync(
        userId: UUID,
        name: String = "Test Recipe",
        category: String = "Main Course",
        cuisine: String = "Italian",
        totalTimeMinutes: Int = 45
    ) -> UUID? {
        guard let serviceKey = TestConfig.serviceRoleKey else {
            print("⚠️ TestSupabaseClient: SUPABASE_SERVICE_ROLE_KEY not set, cannot seed")
            return nil
        }

        let recipeId = UUID()
        let testName = "\(TestConfig.testRecipePrefix)\(name)"
        let prepTime = max(5, totalTimeMinutes / 3)
        let cookTime = totalTimeMinutes - prepTime

        let recipe: [String: Any] = [
            "id": recipeId.uuidString,
            "user_id": userId.uuidString,
            "name": testName,
            "description": "Test recipe created by UI tests",
            "category": category,
            "cuisine": cuisine,
            "prep_time_minutes": prepTime,
            "cook_time_minutes": cookTime,
            "total_time_minutes": totalTimeMinutes,
            "recipe_yield": "4 servings",
            "rating": 0,
            "is_favorite": false
        ]

        guard let url = URL(string: "\(TestConfig.supabaseURL)/rest/v1/recipes"),
              let body = try? JSONSerialization.data(withJSONObject: recipe) else {
            return nil
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("return=representation", forHTTPHeaderField: "Prefer")
        // New Supabase API keys: use secret key directly in apikey header (not Bearer)
        request.setValue(serviceKey, forHTTPHeaderField: "apikey")
        request.httpBody = body

        var success = false
        let semaphore = DispatchSemaphore(value: 0)

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let httpResponse = response as? HTTPURLResponse {
                if (200...299).contains(httpResponse.statusCode) {
                    success = true
                    print("✅ Recipe seeded successfully")
                } else {
                    let body = data.flatMap { String(data: $0, encoding: .utf8) } ?? "no body"
                    print("❌ Recipe seed failed - HTTP \(httpResponse.statusCode): \(body)")
                }
            } else if let error = error {
                print("❌ Recipe seed network error: \(error)")
            }
            semaphore.signal()
        }.resume()

        _ = semaphore.wait(timeout: .now() + 10)
        return success ? recipeId : nil
    }

    /// Seed multiple diverse test recipes for UI testing
    /// - Parameter userId: The user's UUID
    /// - Returns: Number of recipes successfully created
    func seedTestRecipesSync(userId: UUID, count: Int = 20) -> Int {
        let testRecipes: [(name: String, category: String, cuisine: String, time: Int)] = [
            // Quick recipes (under 30 min)
            ("Quick Pasta Aglio e Olio", "Main Course", "Italian", 20),
            ("5-Minute Avocado Toast", "Breakfast", "American", 5),
            ("Simple Greek Salad", "Salad", "Greek", 15),
            ("Microwave Mug Cake", "Dessert", "American", 10),
            ("Quick Stir Fry", "Main Course", "Chinese", 25),

            // Medium recipes (30-60 min)
            ("Classic Beef Tacos", "Main Course", "Mexican", 35),
            ("Homemade Pizza", "Main Course", "Italian", 45),
            ("Chicken Curry", "Main Course", "Indian", 50),
            ("Vegetable Soup", "Soup", "American", 40),
            ("Banana Bread", "Dessert", "American", 55),
            ("Pad Thai", "Main Course", "Thai", 35),
            ("Caesar Salad", "Salad", "Italian", 30),

            // Long recipes (over 60 min)
            ("Slow Cooked Pulled Pork", "Main Course", "American", 240),
            ("Beef Bourguignon", "Main Course", "French", 180),
            ("Homemade Lasagna", "Main Course", "Italian", 90),
            ("Sourdough Bread", "Bread", "French", 300),
            ("Roast Chicken", "Main Course", "French", 75),
            ("Chocolate Layer Cake", "Dessert", "American", 120),
            ("Ramen from Scratch", "Soup", "Japanese", 180),
            ("BBQ Ribs", "Main Course", "American", 150)
        ]

        var successCount = 0
        let recipesToSeed = Array(testRecipes.prefix(count))

        for recipe in recipesToSeed {
            if seedTestRecipeSync(
                userId: userId,
                name: recipe.name,
                category: recipe.category,
                cuisine: recipe.cuisine,
                totalTimeMinutes: recipe.time
            ) != nil {
                successCount += 1
            }
        }

        print("✅ Seeded \(successCount)/\(recipesToSeed.count) test recipes")
        return successCount
    }

    /// Check how many test recipes exist for a user
    /// - Parameter userId: The user's UUID
    /// - Returns: Count of test recipes
    func countTestRecipesSync(userId: UUID) -> Int {
        guard let serviceKey = TestConfig.serviceRoleKey else { return 0 }

        let encodedPrefix = TestConfig.testRecipePrefix
            .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? TestConfig.testRecipePrefix

        let urlString = "\(TestConfig.supabaseURL)/rest/v1/recipes?user_id=eq.\(userId.uuidString)&name=like.\(encodedPrefix)*&select=id"
        guard let url = URL(string: urlString) else { return 0 }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        // New Supabase API keys: use secret key directly in apikey header (not Bearer)
        request.setValue(serviceKey, forHTTPHeaderField: "apikey")

        var count = 0
        let semaphore = DispatchSemaphore(value: 0)

        URLSession.shared.dataTask(with: request) { data, _, _ in
            if let data = data,
               let recipes = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
                count = recipes.count
            }
            semaphore.signal()
        }.resume()

        _ = semaphore.wait(timeout: .now() + 10)
        return count
    }
}
