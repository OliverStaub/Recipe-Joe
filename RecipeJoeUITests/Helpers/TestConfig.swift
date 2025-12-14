//
//  TestConfig.swift
//  RecipeJoeUITests
//
//  Configuration constants for UI tests
//  Reads from .env file in project root (gitignored)
//

import Foundation

/// Test configuration constants
/// Reads from .env file, falls back to environment variables
enum TestConfig {

    // MARK: - .env File Reader

    /// Cached values from .env file
    private static let envValues: [String: String] = {
        loadEnvFile()
    }()

    /// Load .env file from project root
    private static func loadEnvFile() -> [String: String] {
        var values: [String: String] = [:]

        // Find the .env file - try multiple paths
        // Note: #file in Swift Package Manager points to DerivedData, not source
        // We need to find the actual project root
        let possiblePaths = [
            // Direct absolute path (most reliable for this project)
            "/Users/oliverstaub/gitroot/RecipeJoe/.env",
            // Try relative to the source file location (works in some Xcode configs)
            (#file as NSString).deletingLastPathComponent + "/../../.env",
            (#file as NSString).deletingLastPathComponent + "/../../../.env",
            // Standard locations
            FileManager.default.currentDirectoryPath + "/.env",
            NSHomeDirectory() + "/gitroot/RecipeJoe/.env",
        ]

        var envPath: String?
        for path in possiblePaths {
            let standardized = (path as NSString).standardizingPath
            if FileManager.default.fileExists(atPath: standardized) {
                envPath = standardized
                break
            }
        }

        guard let path = envPath else {
            print("⚠️ TestConfig: .env file not found. Tried paths:")
            for p in possiblePaths {
                print("   - \((p as NSString).standardizingPath)")
            }
            print("   Create .env from .env.template and fill in your values.")
            return values
        }

        guard let content = try? String(contentsOfFile: path, encoding: .utf8) else {
            print("⚠️ TestConfig: Could not read .env file at \(path)")
            return values
        }

        // Parse .env file
        let lines = content.components(separatedBy: .newlines)
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            // Skip empty lines and comments
            if trimmed.isEmpty || trimmed.hasPrefix("#") {
                continue
            }

            // Parse KEY=VALUE
            if let equalIndex = trimmed.firstIndex(of: "=") {
                let key = String(trimmed[..<equalIndex]).trimmingCharacters(in: .whitespaces)
                var value = String(trimmed[trimmed.index(after: equalIndex)...]).trimmingCharacters(in: .whitespaces)

                // Remove quotes if present
                if (value.hasPrefix("\"") && value.hasSuffix("\"")) ||
                   (value.hasPrefix("'") && value.hasSuffix("'")) {
                    value = String(value.dropFirst().dropLast())
                }

                values[key] = value
            }
        }

        print("✅ TestConfig: Loaded \(values.count) values from .env")
        return values
    }

    /// Get a value from .env file, falling back to environment variable
    private static func getValue(_ key: String) -> String? {
        // First check environment variable (allows override)
        if let envValue = ProcessInfo.processInfo.environment[key], !envValue.isEmpty {
            return envValue
        }
        // Then check .env file
        return envValues[key]
    }

    // MARK: - Supabase Configuration

    /// Supabase project URL
    static var supabaseURL: String {
        getValue("SUPABASE_URL") ?? "https://iqamjnyuvvmvakjdobsm.supabase.co"
    }

    /// Supabase publishable key (new API key format: sb_publishable_...)
    /// Used for public/anon access - replaces the old JWT anon key
    static var supabaseAnonKey: String? {
        getValue("SUPABASE_ANON_KEY")
    }

    /// Supabase secret key (new API key format: sb_secret_...)
    /// Used for admin operations - replaces the old JWT service_role key
    /// NOTE: New keys go directly in the apikey header, NOT as Bearer token
    static var serviceRoleKey: String? {
        getValue("SUPABASE_SERVICE_ROLE_KEY")
    }

    /// Password for creating new test users during tests
    static var testPasswordForNewUsers: String {
        getValue("TEST_PASSWORD_FOR_NEW_USERS") ?? "TestPassword123!"
    }

    // MARK: - Test User Configuration

    /// Test user email for automatic sign-in during tests
    static var testUserEmail: String? {
        getValue("TEST_USER_EMAIL")
    }

    /// Test user password for automatic sign-in during tests
    static var testUserPassword: String? {
        getValue("TEST_USER_PASSWORD")
    }

    /// Check if test credentials are configured
    static var hasTestCredentials: Bool {
        testUserEmail != nil && testUserPassword != nil
    }

    /// The UUID of the test user in Supabase (optional, set after creating test account)
    static var testUserId: UUID? {
        if let uuidString = getValue("TEST_USER_ID") {
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
