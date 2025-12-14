//
//  TestConfig.swift
//  RecipeJoeUITests
//
//  Configuration constants for UI tests
//

import Foundation

/// Test configuration constants
enum TestConfig {
    // MARK: - Supabase Configuration

    /// Supabase project URL
    static let supabaseURL = "https://iqamjnyuvvmvakjdobsm.supabase.co"

    /// Supabase anon key (safe to include, only allows public access)
    static let supabaseAnonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImlxYW1qbnl1dnZtdmFramRvYnNtIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQ5NDA4NjEsImV4cCI6MjA4MDUxNjg2MX0.zHhBnHJUTGhSjdriwH8nKswCxHi2g3-LqaoQF51IBnU"

    /// Service role key from environment variable (for cleanup operations)
    /// Set this in Xcode Scheme > Test > Environment Variables
    static var serviceRoleKey: String? {
        ProcessInfo.processInfo.environment["SUPABASE_SERVICE_ROLE_KEY"]
    }

    // MARK: - Test User Configuration

    /// Test user email for automatic sign-in during tests
    /// Set in Xcode Scheme > Test > Environment Variables as TEST_USER_EMAIL
    static var testUserEmail: String? {
        ProcessInfo.processInfo.environment["TEST_USER_EMAIL"]
    }

    /// Test user password for automatic sign-in during tests
    /// Set in Xcode Scheme > Test > Environment Variables as TEST_USER_PASSWORD
    /// SECURITY: Never commit passwords to git - always use environment variables
    static var testUserPassword: String? {
        ProcessInfo.processInfo.environment["TEST_USER_PASSWORD"]
    }

    /// Check if test credentials are configured
    static var hasTestCredentials: Bool {
        testUserEmail != nil && testUserPassword != nil
    }

    /// The UUID of the test user in Supabase (set after creating test account)
    /// You can create a test user with email/password auth in Supabase Dashboard
    /// or use your personal account's UUID for testing
    ///
    /// To find your UUID: Supabase Dashboard > Authentication > Users
    static var testUserId: UUID? {
        if let uuidString = ProcessInfo.processInfo.environment["TEST_USER_ID"] {
            return UUID(uuidString: uuidString)
        }
        return nil
    }

    // MARK: - Test Data Prefixes

    /// Prefix for test recipe names (helps identify test data)
    static let testRecipePrefix = "[TEST] "

    // MARK: - Timeouts

    /// Standard timeout for UI element existence checks
    static let standardTimeout: TimeInterval = 5

    /// Extended timeout for authentication state checks
    static let authTimeout: TimeInterval = 10

    /// Long timeout for recipe import operations
    static let importTimeout: TimeInterval = 120
}
