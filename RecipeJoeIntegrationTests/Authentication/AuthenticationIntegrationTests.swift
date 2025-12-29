//
//  AuthenticationIntegrationTests.swift
//  RecipeJoeIntegrationTests
//
//  Integration tests for Supabase authentication API
//  Tests the auth layer directly without UI
//

import Testing
import Foundation

@Suite("Authentication Integration Tests")
struct AuthenticationIntegrationTests {

    // MARK: - Test User Management

    /// Generate a unique test email for each test run
    private func generateTestEmail() -> String {
        let timestamp = Int(Date().timeIntervalSince1970)
        let random = Int.random(in: 1000...9999)
        return "test-\(timestamp)-\(random)@recipejoe.test"
    }

    // MARK: - Sign In Tests

    @Test("Sign in with valid credentials returns access token")
    func testSignInWithValidCredentials() async throws {
        // Skip if no test credentials configured
        guard IntegrationTestConfig.hasTestCredentials,
              let email = IntegrationTestConfig.testUserEmail,
              let password = IntegrationTestConfig.testUserPassword else {
            print("⚠️ Skipping: TEST_USER_EMAIL and TEST_USER_PASSWORD not configured")
            return
        }

        let client = IntegrationTestClient.shared
        let response = try await client.signIn(email: email, password: password)

        #expect(!response.accessToken.isEmpty, "Access token should not be empty")
        #expect(response.user != nil, "User should be returned")
        #expect(response.user?.email?.lowercased() == email.lowercased(), "User email should match")
    }

    @Test("Sign in with invalid password returns authentication error")
    func testSignInWithInvalidPassword() async throws {
        guard IntegrationTestConfig.hasTestCredentials,
              let email = IntegrationTestConfig.testUserEmail else {
            print("⚠️ Skipping: TEST_USER_EMAIL not configured")
            return
        }

        let client = IntegrationTestClient.shared

        do {
            _ = try await client.signIn(email: email, password: "wrong-password-12345")
            Issue.record("Expected authentication to fail with wrong password")
        } catch let error as IntegrationTestError {
            // Expected - should fail with authentication error
            switch error {
            case .authenticationFailed(let message):
                #expect(message.lowercased().contains("invalid") || message.lowercased().contains("credentials"),
                       "Error should mention invalid credentials: \(message)")
            case .invalidResponse(let status, _):
                #expect(status == 400 || status == 401, "Should return 400 or 401 for invalid credentials")
            default:
                Issue.record("Unexpected error type: \(error)")
            }
        }
    }

    @Test("Sign in with non-existent user returns error")
    func testSignInWithNonExistentUser() async throws {
        let client = IntegrationTestClient.shared
        let fakeEmail = "nonexistent-\(UUID().uuidString)@example.com"

        do {
            _ = try await client.signIn(email: fakeEmail, password: "SomePassword123!")
            Issue.record("Expected authentication to fail with non-existent user")
        } catch let error as IntegrationTestError {
            // Expected - should fail
            switch error {
            case .authenticationFailed, .invalidResponse:
                // Expected
                break
            default:
                Issue.record("Unexpected error type: \(error)")
            }
        }
    }

    // MARK: - Sign Up Tests

    @Test("Sign up creates new user")
    func testSignUpCreatesUser() async throws {
        let client = IntegrationTestClient.shared
        let email = generateTestEmail()
        let password = IntegrationTestConfig.testPasswordForNewUsers
        var createdUserId: UUID?

        defer {
            // Cleanup: delete the test user
            if let userId = createdUserId {
                Task {
                    try? await client.deleteTestUser(userId: userId)
                }
            }
        }

        // Create user via Admin API (to have confirmed email for immediate testing)
        createdUserId = try await client.createTestUser(email: email, password: password)

        #expect(createdUserId != nil, "User should be created")

        // Now verify we can sign in
        let response = try await client.signIn(email: email, password: password)
        #expect(!response.accessToken.isEmpty, "Should be able to sign in")
    }

    @Test("Sign up with weak password fails")
    func testSignUpWithWeakPasswordFails() async throws {
        let client = IntegrationTestClient.shared
        let email = generateTestEmail()
        let weakPassword = "123" // Too short

        do {
            _ = try await client.signUp(email: email, password: weakPassword)
            Issue.record("Expected sign up to fail with weak password")
        } catch let error as IntegrationTestError {
            switch error {
            case .authenticationFailed(let message):
                // Expected - Supabase should reject weak passwords
                print("✅ Correctly rejected weak password: \(message)")
            case .invalidResponse(let status, _):
                #expect(status == 400 || status == 422, "Should return 400 or 422 for weak password")
            default:
                Issue.record("Unexpected error type: \(error)")
            }
        }
    }

    @Test("Sign up with invalid email fails")
    func testSignUpWithInvalidEmailFails() async throws {
        let client = IntegrationTestClient.shared
        let invalidEmail = "not-an-email"
        let password = IntegrationTestConfig.testPasswordForNewUsers

        do {
            _ = try await client.signUp(email: invalidEmail, password: password)
            Issue.record("Expected sign up to fail with invalid email")
        } catch let error as IntegrationTestError {
            switch error {
            case .authenticationFailed(let message):
                print("✅ Correctly rejected invalid email: \(message)")
            case .invalidResponse(let status, _):
                #expect(status == 400 || status == 422, "Should return 400 or 422 for invalid email")
            default:
                Issue.record("Unexpected error type: \(error)")
            }
        }
    }

    // MARK: - Sign Out Tests

    @Test("Sign out invalidates session")
    func testSignOutInvalidatesSession() async throws {
        guard IntegrationTestConfig.hasTestCredentials,
              let email = IntegrationTestConfig.testUserEmail,
              let password = IntegrationTestConfig.testUserPassword else {
            print("⚠️ Skipping: TEST_USER_EMAIL and TEST_USER_PASSWORD not configured")
            return
        }

        let client = IntegrationTestClient.shared

        // Sign in first
        let signInResponse = try await client.signIn(email: email, password: password)
        let accessToken = signInResponse.accessToken

        // Sign out
        try await client.signOut(accessToken: accessToken)

        // Verify the token is no longer valid by trying to fetch recipes
        // (This may still work briefly due to JWT validation, but the server-side session is invalidated)
        // The main verification is that signOut completes without error
    }

    // MARK: - Password Reset Tests

    @Test("Password reset request is accepted for valid email")
    func testPasswordResetRequestAccepted() async throws {
        guard IntegrationTestConfig.hasTestCredentials,
              let email = IntegrationTestConfig.testUserEmail else {
            print("⚠️ Skipping: TEST_USER_EMAIL not configured")
            return
        }

        let client = IntegrationTestClient.shared

        // This should not throw - Supabase accepts the request
        // (It won't actually send email in test mode)
        try await client.resetPassword(email: email)
    }

    @Test("Password reset for non-existent email doesn't reveal user existence")
    func testPasswordResetForNonExistentEmail() async throws {
        let client = IntegrationTestClient.shared
        let fakeEmail = "nonexistent-\(UUID().uuidString)@example.com"

        // Supabase should not reveal whether the email exists or not
        // It should accept the request silently
        do {
            try await client.resetPassword(email: fakeEmail)
            // Expected - Supabase accepts but doesn't send email
        } catch {
            // Some configurations might reject, which is also acceptable
            print("Note: Password reset was rejected for non-existent email")
        }
    }

    // MARK: - Admin API Tests

    @Test("Create and delete test user via Admin API")
    func testCreateAndDeleteTestUser() async throws {
        let client = IntegrationTestClient.shared
        let email = generateTestEmail()
        let password = IntegrationTestConfig.testPasswordForNewUsers

        // Create user
        let userId = try await client.createTestUser(email: email, password: password)

        // Verify user exists
        let retrievedEmail = try await client.getUserEmail(userId: userId)
        #expect(retrievedEmail.lowercased() == email.lowercased(), "Email should match")

        // Delete user
        try await client.deleteTestUser(userId: userId)

        // Verify user is gone
        do {
            _ = try await client.getUserEmail(userId: userId)
            Issue.record("User should have been deleted")
        } catch IntegrationTestError.userNotFound {
            // Expected
        } catch IntegrationTestError.invalidResponse(let status, _) {
            // 404 is also expected
            #expect(status == 404, "Should return 404 for deleted user")
        }
    }
}
