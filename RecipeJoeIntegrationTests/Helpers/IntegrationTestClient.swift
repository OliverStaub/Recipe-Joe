//
//  IntegrationTestClient.swift
//  RecipeJoeIntegrationTests
//
//  Async Supabase client for integration tests
//  Uses async/await for cleaner test code
//

import Foundation

/// Errors that can occur during integration tests
enum IntegrationTestError: LocalizedError {
    case missingServiceRoleKey
    case missingAnonKey
    case networkError(Error)
    case invalidResponse(Int, String?)
    case decodingError(String)
    case userNotFound
    case authenticationFailed(String)

    var errorDescription: String? {
        switch self {
        case .missingServiceRoleKey:
            return "SUPABASE_SERVICE_ROLE_KEY not set in .env"
        case .missingAnonKey:
            return "SUPABASE_ANON_KEY not set in .env"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .invalidResponse(let status, let body):
            return "HTTP \(status): \(body ?? "no body")"
        case .decodingError(let message):
            return "Decoding error: \(message)"
        case .userNotFound:
            return "User not found"
        case .authenticationFailed(let message):
            return "Authentication failed: \(message)"
        }
    }
}

/// Auth response from Supabase
struct AuthResponse: Codable {
    let accessToken: String
    let refreshToken: String?
    let user: AuthUser?

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case user
    }
}

/// User from Supabase auth
struct AuthUser: Codable {
    let id: String
    let email: String?
}

/// Error response from Supabase
struct SupabaseErrorResponse: Codable {
    let error: String?
    let errorDescription: String?
    let message: String?
    let msg: String?
    let code: String?

    enum CodingKeys: String, CodingKey {
        case error
        case errorDescription = "error_description"
        case message
        case msg
        case code
    }

    var displayMessage: String {
        errorDescription ?? message ?? msg ?? error ?? "Unknown error"
    }
}

/// Async Supabase client for integration tests
actor IntegrationTestClient {

    static let shared = IntegrationTestClient()

    private init() {}

    // MARK: - Authentication API Tests

    /// Sign in with email/password and return auth response
    func signIn(email: String, password: String) async throws -> AuthResponse {
        guard let anonKey = IntegrationTestConfig.supabaseAnonKey else {
            throw IntegrationTestError.missingAnonKey
        }

        guard let url = URL(string: "\(IntegrationTestConfig.supabaseURL)/auth/v1/token?grant_type=password") else {
            throw IntegrationTestError.decodingError("Invalid URL")
        }

        let credentials = ["email": email, "password": password]
        let body = try JSONEncoder().encode(credentials)

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(anonKey, forHTTPHeaderField: "apikey")
        request.httpBody = body

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw IntegrationTestError.decodingError("Invalid response type")
        }

        if httpResponse.statusCode == 200 {
            let decoder = JSONDecoder()
            return try decoder.decode(AuthResponse.self, from: data)
        } else {
            let errorBody = String(data: data, encoding: .utf8)
            if let errorData = try? JSONDecoder().decode(SupabaseErrorResponse.self, from: data) {
                throw IntegrationTestError.authenticationFailed(errorData.displayMessage)
            }
            throw IntegrationTestError.invalidResponse(httpResponse.statusCode, errorBody)
        }
    }

    /// Sign up with email/password (creates unconfirmed user unless email_confirm is set)
    func signUp(email: String, password: String) async throws -> AuthResponse {
        guard let anonKey = IntegrationTestConfig.supabaseAnonKey else {
            throw IntegrationTestError.missingAnonKey
        }

        guard let url = URL(string: "\(IntegrationTestConfig.supabaseURL)/auth/v1/signup") else {
            throw IntegrationTestError.decodingError("Invalid URL")
        }

        let credentials = ["email": email, "password": password]
        let body = try JSONEncoder().encode(credentials)

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(anonKey, forHTTPHeaderField: "apikey")
        request.httpBody = body

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw IntegrationTestError.decodingError("Invalid response type")
        }

        if (200...299).contains(httpResponse.statusCode) {
            let decoder = JSONDecoder()
            return try decoder.decode(AuthResponse.self, from: data)
        } else {
            if let errorData = try? JSONDecoder().decode(SupabaseErrorResponse.self, from: data) {
                throw IntegrationTestError.authenticationFailed(errorData.displayMessage)
            }
            let errorBody = String(data: data, encoding: .utf8)
            throw IntegrationTestError.invalidResponse(httpResponse.statusCode, errorBody)
        }
    }

    /// Request password reset email
    func resetPassword(email: String) async throws {
        guard let anonKey = IntegrationTestConfig.supabaseAnonKey else {
            throw IntegrationTestError.missingAnonKey
        }

        guard let url = URL(string: "\(IntegrationTestConfig.supabaseURL)/auth/v1/recover") else {
            throw IntegrationTestError.decodingError("Invalid URL")
        }

        let payload = ["email": email]
        let body = try JSONEncoder().encode(payload)

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(anonKey, forHTTPHeaderField: "apikey")
        request.httpBody = body

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw IntegrationTestError.decodingError("Invalid response type")
        }

        if !(200...299).contains(httpResponse.statusCode) {
            if let errorData = try? JSONDecoder().decode(SupabaseErrorResponse.self, from: data) {
                throw IntegrationTestError.authenticationFailed(errorData.displayMessage)
            }
            let errorBody = String(data: data, encoding: .utf8)
            throw IntegrationTestError.invalidResponse(httpResponse.statusCode, errorBody)
        }
    }

    /// Sign out (invalidate token)
    func signOut(accessToken: String) async throws {
        guard let anonKey = IntegrationTestConfig.supabaseAnonKey else {
            throw IntegrationTestError.missingAnonKey
        }

        guard let url = URL(string: "\(IntegrationTestConfig.supabaseURL)/auth/v1/logout") else {
            throw IntegrationTestError.decodingError("Invalid URL")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(anonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw IntegrationTestError.decodingError("Invalid response type")
        }

        // 204 No Content is success, also accept 200
        if !(200...299).contains(httpResponse.statusCode) {
            let errorBody = String(data: data, encoding: .utf8)
            throw IntegrationTestError.invalidResponse(httpResponse.statusCode, errorBody)
        }
    }

    // MARK: - Admin API (for test user management)

    /// Create a test user with auto-confirmed email (Admin API)
    func createTestUser(email: String, password: String) async throws -> UUID {
        guard let serviceKey = IntegrationTestConfig.serviceRoleKey else {
            throw IntegrationTestError.missingServiceRoleKey
        }

        guard let url = URL(string: "\(IntegrationTestConfig.supabaseURL)/auth/v1/admin/users") else {
            throw IntegrationTestError.decodingError("Invalid URL")
        }

        let userData: [String: Any] = [
            "email": email,
            "password": password,
            "email_confirm": true
        ]

        let body = try JSONSerialization.data(withJSONObject: userData)

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(serviceKey, forHTTPHeaderField: "apikey")
        request.httpBody = body

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw IntegrationTestError.decodingError("Invalid response type")
        }

        if (200...299).contains(httpResponse.statusCode) {
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let idString = json["id"] as? String,
               let uuid = UUID(uuidString: idString) {
                return uuid
            }
            throw IntegrationTestError.decodingError("Could not parse user ID")
        } else {
            let errorBody = String(data: data, encoding: .utf8)
            throw IntegrationTestError.invalidResponse(httpResponse.statusCode, errorBody)
        }
    }

    /// Delete a test user (Admin API)
    /// Safety: Only deletes users with @recipejoe.test email domain
    func deleteTestUser(userId: UUID) async throws {
        guard let serviceKey = IntegrationTestConfig.serviceRoleKey else {
            throw IntegrationTestError.missingServiceRoleKey
        }

        // First verify it's a test user
        let email = try await getUserEmail(userId: userId)
        guard email.hasSuffix(IntegrationTestConfig.testEmailDomain) else {
            throw IntegrationTestError.authenticationFailed("Safety: Cannot delete non-test user \(email)")
        }

        guard let url = URL(string: "\(IntegrationTestConfig.supabaseURL)/auth/v1/admin/users/\(userId.uuidString)") else {
            throw IntegrationTestError.decodingError("Invalid URL")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue(serviceKey, forHTTPHeaderField: "apikey")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw IntegrationTestError.decodingError("Invalid response type")
        }

        if !(200...299).contains(httpResponse.statusCode) {
            let errorBody = String(data: data, encoding: .utf8)
            throw IntegrationTestError.invalidResponse(httpResponse.statusCode, errorBody)
        }
    }

    /// Get user email by ID (Admin API)
    func getUserEmail(userId: UUID) async throws -> String {
        guard let serviceKey = IntegrationTestConfig.serviceRoleKey else {
            throw IntegrationTestError.missingServiceRoleKey
        }

        guard let url = URL(string: "\(IntegrationTestConfig.supabaseURL)/auth/v1/admin/users/\(userId.uuidString)") else {
            throw IntegrationTestError.decodingError("Invalid URL")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(serviceKey, forHTTPHeaderField: "apikey")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw IntegrationTestError.decodingError("Invalid response type")
        }

        if httpResponse.statusCode == 200 {
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let email = json["email"] as? String {
                return email
            }
            throw IntegrationTestError.decodingError("Could not parse user email")
        } else {
            throw IntegrationTestError.userNotFound
        }
    }

    // MARK: - Recipe API (for RLS tests)

    /// Fetch recipes with auth token (tests RLS)
    func fetchRecipes(authToken: String) async throws -> [UUID] {
        guard let anonKey = IntegrationTestConfig.supabaseAnonKey else {
            throw IntegrationTestError.missingAnonKey
        }

        guard let url = URL(string: "\(IntegrationTestConfig.supabaseURL)/rest/v1/recipes?select=id") else {
            throw IntegrationTestError.decodingError("Invalid URL")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(anonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw IntegrationTestError.decodingError("Invalid response type")
        }

        if httpResponse.statusCode == 200 {
            if let recipes = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
                return recipes.compactMap { recipe in
                    guard let idString = recipe["id"] as? String else { return nil }
                    return UUID(uuidString: idString)
                }
            }
            return []
        } else {
            let errorBody = String(data: data, encoding: .utf8)
            throw IntegrationTestError.invalidResponse(httpResponse.statusCode, errorBody)
        }
    }

    /// Fetch recipes without auth (tests RLS for unauthenticated users)
    func fetchRecipesUnauthenticated() async throws -> [UUID] {
        guard let anonKey = IntegrationTestConfig.supabaseAnonKey else {
            throw IntegrationTestError.missingAnonKey
        }

        guard let url = URL(string: "\(IntegrationTestConfig.supabaseURL)/rest/v1/recipes?select=id") else {
            throw IntegrationTestError.decodingError("Invalid URL")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(anonKey, forHTTPHeaderField: "apikey")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw IntegrationTestError.decodingError("Invalid response type")
        }

        // RLS might return empty array or 401/403
        if httpResponse.statusCode == 200 {
            if let recipes = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
                return recipes.compactMap { recipe in
                    guard let idString = recipe["id"] as? String else { return nil }
                    return UUID(uuidString: idString)
                }
            }
            return []
        } else if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 {
            // Expected - RLS is working
            return []
        } else {
            let errorBody = String(data: data, encoding: .utf8)
            throw IntegrationTestError.invalidResponse(httpResponse.statusCode, errorBody)
        }
    }

    /// Seed a test recipe (Admin API)
    func seedTestRecipe(userId: UUID, name: String = "Test Recipe") async throws -> UUID {
        guard let serviceKey = IntegrationTestConfig.serviceRoleKey else {
            throw IntegrationTestError.missingServiceRoleKey
        }

        let recipeId = UUID()
        let testName = "\(IntegrationTestConfig.testRecipePrefix)\(name)"

        let recipe: [String: Any] = [
            "id": recipeId.uuidString,
            "user_id": userId.uuidString,
            "name": testName,
            "description": "Test recipe for integration tests",
            "category": "Main Course",
            "cuisine": "Italian",
            "prep_time_minutes": 15,
            "cook_time_minutes": 30,
            "total_time_minutes": 45,
            "recipe_yield": "4 servings",
            "rating": 0,
            "is_favorite": false
        ]

        guard let url = URL(string: "\(IntegrationTestConfig.supabaseURL)/rest/v1/recipes") else {
            throw IntegrationTestError.decodingError("Invalid URL")
        }

        let body = try JSONSerialization.data(withJSONObject: recipe)

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("return=representation", forHTTPHeaderField: "Prefer")
        request.setValue(serviceKey, forHTTPHeaderField: "apikey")
        request.httpBody = body

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw IntegrationTestError.decodingError("Invalid response type")
        }

        if (200...299).contains(httpResponse.statusCode) {
            return recipeId
        } else {
            let errorBody = String(data: data, encoding: .utf8)
            throw IntegrationTestError.invalidResponse(httpResponse.statusCode, errorBody)
        }
    }

    /// Delete test recipes for a user (Admin API)
    func deleteTestRecipes(userId: UUID) async throws {
        guard let serviceKey = IntegrationTestConfig.serviceRoleKey else {
            throw IntegrationTestError.missingServiceRoleKey
        }

        let encodedPrefix = IntegrationTestConfig.testRecipePrefix
            .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? IntegrationTestConfig.testRecipePrefix

        let urlString = "\(IntegrationTestConfig.supabaseURL)/rest/v1/recipes?user_id=eq.\(userId.uuidString)&name=like.\(encodedPrefix)*"
        guard let url = URL(string: urlString) else {
            throw IntegrationTestError.decodingError("Invalid URL")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue(serviceKey, forHTTPHeaderField: "apikey")

        let (_, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw IntegrationTestError.decodingError("Invalid response type")
        }

        if !(200...299).contains(httpResponse.statusCode) {
            throw IntegrationTestError.invalidResponse(httpResponse.statusCode, nil)
        }
    }
}
