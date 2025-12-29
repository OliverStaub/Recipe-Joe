//
//  TokenIntegrationTests.swift
//  RecipeJoeIntegrationTests
//
//  Integration tests for token balance functionality
//  Tests that new users receive the correct initial token balance
//

import Testing
import Foundation

@Suite("Token Integration Tests")
struct TokenIntegrationTests {

    // MARK: - Test User Management

    /// Generate a unique test email for each test run
    private func generateTestEmail() -> String {
        let timestamp = Int(Date().timeIntervalSince1970)
        let random = Int.random(in: 1000...9999)
        return "token-test-\(timestamp)-\(random)@recipejoe.test"
    }

    // MARK: - Initial Balance Tests

    @Test("New user receives 15 free tokens")
    func testNewUserReceives15Tokens() async throws {
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

        // Create a new user via Admin API (with confirmed email)
        createdUserId = try await client.createTestUser(email: email, password: password)
        #expect(createdUserId != nil, "User should be created")

        // Sign in to get access token
        let signInResponse = try await client.signIn(email: email, password: password)
        #expect(!signInResponse.accessToken.isEmpty, "Should receive access token")

        // Fetch token balance
        let balance = try await client.fetchTokenBalance(authToken: signInResponse.accessToken)

        // Verify new user gets 15 free tokens
        #expect(balance == 15, "New user should receive 15 free tokens, got \(balance)")
    }
}
