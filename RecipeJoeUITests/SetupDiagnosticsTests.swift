//
//  SetupDiagnosticsTests.swift
//  RecipeJoeUITests
//
//  Diagnostic tests that run FIRST to verify test environment is configured correctly.
//  These tests help identify setup issues before running the full test suite.
//

import XCTest

/// Diagnostic tests to verify test environment setup
/// These tests are prefixed with "test0" to run first alphabetically
final class SetupDiagnosticsTests: XCTestCase {

    // MARK: - Environment Variable Checks

    func test0_A_ServiceRoleKeyIsSet() throws {
        let serviceKey = ProcessInfo.processInfo.environment["SUPABASE_SERVICE_ROLE_KEY"]

        if serviceKey == nil {
            XCTFail("""
                ❌ SUPABASE_SERVICE_ROLE_KEY is NOT set!

                To fix:
                1. Open Xcode
                2. Edit Scheme → Test → Arguments → Environment Variables
                3. Add: SUPABASE_SERVICE_ROLE_KEY = (your key from Supabase Dashboard → Settings → API)
                """)
        } else {
            print("✅ SUPABASE_SERVICE_ROLE_KEY is set (length: \(serviceKey!.count) chars)")
            XCTAssertTrue(serviceKey!.count > 50, "Service role key seems too short - verify it's correct")
        }
    }

    func test0_B_TestUserEmailIsSet() throws {
        let email = ProcessInfo.processInfo.environment["TEST_USER_EMAIL"]

        if email == nil {
            XCTFail("""
                ❌ TEST_USER_EMAIL is NOT set!

                To fix:
                1. Open Xcode
                2. Edit Scheme → Test → Arguments → Environment Variables
                3. Add: TEST_USER_EMAIL = uitest@recipejoe.test (or your preferred test email)
                """)
        } else {
            print("✅ TEST_USER_EMAIL is set: \(email!)")
            XCTAssertTrue(email!.contains("@"), "Email should contain @")
        }
    }

    func test0_C_TestUserPasswordIsSet() throws {
        let password = ProcessInfo.processInfo.environment["TEST_USER_PASSWORD"]

        if password == nil {
            XCTFail("""
                ❌ TEST_USER_PASSWORD is NOT set!

                To fix:
                1. Open Xcode
                2. Edit Scheme → Test → Arguments → Environment Variables
                3. Add: TEST_USER_PASSWORD = YourSecurePassword123!
                """)
        } else {
            print("✅ TEST_USER_PASSWORD is set (length: \(password!.count) chars)")
            XCTAssertTrue(password!.count >= 6, "Password should be at least 6 characters")
        }
    }

    // MARK: - API Connectivity Checks

    func test0_D_CanConnectToSupabase() throws {
        guard ProcessInfo.processInfo.environment["SUPABASE_SERVICE_ROLE_KEY"] != nil else {
            throw XCTSkip("SUPABASE_SERVICE_ROLE_KEY not set - skipping API test")
        }

        // Try to hit the Supabase health endpoint
        let url = URL(string: "\(TestConfig.supabaseURL)/rest/v1/")!
        var request = URLRequest(url: url)
        request.setValue(TestConfig.supabaseAnonKey, forHTTPHeaderField: "apikey")

        let expectation = XCTestExpectation(description: "Supabase connection")
        var connectionSuccess = false
        var statusCode = 0

        URLSession.shared.dataTask(with: request) { _, response, error in
            if let httpResponse = response as? HTTPURLResponse {
                statusCode = httpResponse.statusCode
                connectionSuccess = (200...299).contains(httpResponse.statusCode)
            }
            expectation.fulfill()
        }.resume()

        wait(for: [expectation], timeout: 10)

        XCTAssertTrue(connectionSuccess, "❌ Cannot connect to Supabase (status: \(statusCode)). Check your internet connection and Supabase URL.")
        print("✅ Successfully connected to Supabase")
    }

    // MARK: - Test User Checks

    func test0_E_TestUserExistsOrCanBeCreated() throws {
        guard let serviceKey = ProcessInfo.processInfo.environment["SUPABASE_SERVICE_ROLE_KEY"],
              let email = ProcessInfo.processInfo.environment["TEST_USER_EMAIL"],
              let password = ProcessInfo.processInfo.environment["TEST_USER_PASSWORD"] else {
            throw XCTSkip("Environment variables not set - skipping user check")
        }

        // First, try to call the Admin API to check connectivity
        let (userCheckResult, userCheckError) = checkUserViaAdminAPI(email: email, serviceKey: serviceKey)

        if let error = userCheckError {
            XCTFail("Admin API error checking user: \(error)")
            return
        }

        if let userId = userCheckResult {
            // User exists - verify sign in works
            let (token, signInError) = signInAndGetToken(email: email, password: password)
            if token != nil {
                // Success!
                return
            } else {
                // Password doesn't match - delete user and recreate with correct password
                let deleteError = deleteUserViaAdminAPI(userId: userId, serviceKey: serviceKey)
                if let error = deleteError {
                    XCTFail("User exists with wrong password. Failed to delete: \(error)")
                    return
                }

                // Recreate with correct password
                let (newUserId, createError) = createUserViaAdminAPI(email: email, password: password, serviceKey: serviceKey)
                if newUserId != nil {
                    // Verify sign in now works
                    let (newToken, _) = signInAndGetToken(email: email, password: password)
                    XCTAssertNotNil(newToken, "Recreated user but still can't sign in")
                } else {
                    XCTFail("Deleted old user but failed to recreate: \(createError ?? "unknown")")
                }
                return
            }
        } else {
            // User doesn't exist - try to create
            let (newUserId, createError) = createUserViaAdminAPI(email: email, password: password, serviceKey: serviceKey)

            if let userId = newUserId {
                // Verify sign in
                let (token, _) = signInAndGetToken(email: email, password: password)
                XCTAssertNotNil(token, "Created user \(userId) but sign-in failed")
            } else {
                XCTFail("""
                    Failed to create test user '\(email)'!

                    API Error: \(createError ?? "unknown")

                    Possible causes:
                    1. Service role key is invalid
                    2. Email provider not enabled in Supabase
                    3. User already exists (check Dashboard)
                    """)
            }
        }
    }

    // MARK: - Direct API Helpers (with error details)

    private func checkUserViaAdminAPI(email: String, serviceKey: String) -> (UUID?, String?) {
        let encodedEmail = email.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? email
        guard let url = URL(string: "\(TestConfig.supabaseURL)/auth/v1/admin/users?email=\(encodedEmail)") else {
            return (nil, "Invalid URL")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(TestConfig.supabaseAnonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(serviceKey)", forHTTPHeaderField: "Authorization")

        var userId: UUID?
        var errorMessage: String?
        let semaphore = DispatchSemaphore(value: 0)

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                errorMessage = "Network error: \(error.localizedDescription)"
            } else if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 200 {
                    if let data = data,
                       let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let users = json["users"] as? [[String: Any]],
                       let firstUser = users.first,
                       let idString = firstUser["id"] as? String {
                        userId = UUID(uuidString: idString)
                    }
                } else {
                    let body = data.flatMap { String(data: $0, encoding: .utf8) } ?? "no body"
                    errorMessage = "HTTP \(httpResponse.statusCode): \(body)"
                }
            }
            semaphore.signal()
        }.resume()

        _ = semaphore.wait(timeout: .now() + 15)
        return (userId, errorMessage)
    }

    private func createUserViaAdminAPI(email: String, password: String, serviceKey: String) -> (UUID?, String?) {
        guard let url = URL(string: "\(TestConfig.supabaseURL)/auth/v1/admin/users") else {
            return (nil, "Invalid URL")
        }

        let userData: [String: Any] = [
            "email": email,
            "password": password,
            "email_confirm": true
        ]

        guard let body = try? JSONSerialization.data(withJSONObject: userData) else {
            return (nil, "Failed to serialize request")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(TestConfig.supabaseAnonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(serviceKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = body

        var userId: UUID?
        var errorMessage: String?
        let semaphore = DispatchSemaphore(value: 0)

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                errorMessage = "Network error: \(error.localizedDescription)"
            } else if let httpResponse = response as? HTTPURLResponse {
                let body = data.flatMap { String(data: $0, encoding: .utf8) } ?? "no body"
                if (200...299).contains(httpResponse.statusCode) {
                    if let data = data,
                       let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let idString = json["id"] as? String {
                        userId = UUID(uuidString: idString)
                    }
                } else {
                    errorMessage = "HTTP \(httpResponse.statusCode): \(body)"
                }
            }
            semaphore.signal()
        }.resume()

        _ = semaphore.wait(timeout: .now() + 15)
        return (userId, errorMessage)
    }

    private func deleteUserViaAdminAPI(userId: UUID, serviceKey: String) -> String? {
        guard let url = URL(string: "\(TestConfig.supabaseURL)/auth/v1/admin/users/\(userId.uuidString)") else {
            return "Invalid URL"
        }

        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue(TestConfig.supabaseAnonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(serviceKey)", forHTTPHeaderField: "Authorization")

        var errorMessage: String?
        let semaphore = DispatchSemaphore(value: 0)

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                errorMessage = "Network error: \(error.localizedDescription)"
            } else if let httpResponse = response as? HTTPURLResponse {
                if !(200...299).contains(httpResponse.statusCode) {
                    let body = data.flatMap { String(data: $0, encoding: .utf8) } ?? "no body"
                    errorMessage = "HTTP \(httpResponse.statusCode): \(body)"
                }
            }
            semaphore.signal()
        }.resume()

        _ = semaphore.wait(timeout: .now() + 15)
        return errorMessage
    }

    private func signInAndGetToken(email: String, password: String) -> (String?, String?) {
        guard let url = URL(string: "\(TestConfig.supabaseURL)/auth/v1/token?grant_type=password") else {
            return (nil, "Invalid URL")
        }

        let credentials: [String: String] = ["email": email, "password": password]
        guard let body = try? JSONSerialization.data(withJSONObject: credentials) else {
            return (nil, "Failed to serialize")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(TestConfig.supabaseAnonKey, forHTTPHeaderField: "apikey")
        request.httpBody = body

        var token: String?
        var errorMessage: String?
        let semaphore = DispatchSemaphore(value: 0)

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                errorMessage = "Network: \(error.localizedDescription)"
            } else if let httpResponse = response as? HTTPURLResponse {
                let body = data.flatMap { String(data: $0, encoding: .utf8) } ?? ""
                if httpResponse.statusCode == 200 {
                    if let data = data,
                       let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        token = json["access_token"] as? String
                    }
                } else {
                    errorMessage = "HTTP \(httpResponse.statusCode): \(body)"
                }
            }
            semaphore.signal()
        }.resume()

        _ = semaphore.wait(timeout: .now() + 15)
        return (token, errorMessage)
    }

    func test0_F_CanSeedTestRecipes() throws {
        guard let serviceKey = ProcessInfo.processInfo.environment["SUPABASE_SERVICE_ROLE_KEY"],
              let email = ProcessInfo.processInfo.environment["TEST_USER_EMAIL"] else {
            throw XCTSkip("Environment variables not set - skipping recipe seed test")
        }

        // Get user ID using our diagnostic helper (more reliable)
        let (userId, userError) = checkUserViaAdminAPI(email: email, serviceKey: serviceKey)

        guard let userId = userId else {
            XCTFail("Could not find test user '\(email)': \(userError ?? "unknown")")
            return
        }

        // Check existing recipes
        let existingCount = TestSupabaseClient.shared.countTestRecipesSync(userId: userId)

        if existingCount >= 10 {
            // Already have enough recipes
            return
        }

        // Try to seed one recipe with detailed error reporting
        let (recipeId, seedError) = seedRecipeWithErrorDetails(userId: userId, serviceKey: serviceKey)

        if recipeId != nil {
            // Clean up
            TestSupabaseClient.shared.deleteTestRecipesSync(userId: userId)
        } else {
            XCTFail("Failed to seed test recipe: \(seedError ?? "unknown error")")
        }
    }

    private func seedRecipeWithErrorDetails(userId: UUID, serviceKey: String) -> (UUID?, String?) {
        let recipeId = UUID()

        let recipe: [String: Any] = [
            "id": recipeId.uuidString,
            "user_id": userId.uuidString,
            "name": "[TEST] Diagnostic Recipe",
            "description": "Test recipe for diagnostics",
            "category": "Main Course",
            "cuisine": "Italian",
            "prep_time_minutes": 10,
            "cook_time_minutes": 20,
            "total_time_minutes": 30,
            "recipe_yield": "4 servings",
            "rating": 0,
            "is_favorite": false
        ]

        guard let url = URL(string: "\(TestConfig.supabaseURL)/rest/v1/recipes"),
              let body = try? JSONSerialization.data(withJSONObject: recipe) else {
            return (nil, "Failed to create request")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("return=representation", forHTTPHeaderField: "Prefer")
        request.setValue(TestConfig.supabaseAnonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(serviceKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = body

        var resultId: UUID?
        var errorMessage: String?
        let semaphore = DispatchSemaphore(value: 0)

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                errorMessage = "Network: \(error.localizedDescription)"
            } else if let httpResponse = response as? HTTPURLResponse {
                let responseBody = data.flatMap { String(data: $0, encoding: .utf8) } ?? "no body"
                if (200...299).contains(httpResponse.statusCode) {
                    resultId = recipeId
                } else {
                    errorMessage = "HTTP \(httpResponse.statusCode): \(responseBody)"
                }
            }
            semaphore.signal()
        }.resume()

        _ = semaphore.wait(timeout: .now() + 15)
        return (resultId, errorMessage)
    }

    // MARK: - Summary

    func test0_Z_PrintSetupSummary() throws {
        print("""

        ═══════════════════════════════════════════════════════════
        📋 TEST ENVIRONMENT SETUP SUMMARY
        ═══════════════════════════════════════════════════════════

        Environment Variables:
        • SUPABASE_SERVICE_ROLE_KEY: \(ProcessInfo.processInfo.environment["SUPABASE_SERVICE_ROLE_KEY"] != nil ? "✅ Set" : "❌ Missing")
        • TEST_USER_EMAIL: \(ProcessInfo.processInfo.environment["TEST_USER_EMAIL"] ?? "❌ Missing")
        • TEST_USER_PASSWORD: \(ProcessInfo.processInfo.environment["TEST_USER_PASSWORD"] != nil ? "✅ Set" : "❌ Missing")

        If all checks passed, your test environment is ready!
        If any failed, fix the issues above before running other tests.

        ═══════════════════════════════════════════════════════════
        """)
    }
}
