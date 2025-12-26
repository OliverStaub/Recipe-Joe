//
//  IntegrationTestConfig.swift
//  RecipeJoeIntegrationTests
//
//  Configuration for integration tests
//  Reads from .env file in project root (gitignored)
//

import Foundation

/// Test configuration for integration tests
/// Reads from .env file, falls back to environment variables
enum IntegrationTestConfig {

    // MARK: - .env File Reader

    /// Cached values from .env file
    private static let envValues: [String: String] = {
        loadEnvFile()
    }()

    /// Load .env file from project root
    private static func loadEnvFile() -> [String: String] {
        var values: [String: String] = [:]

        let possiblePaths = [
            "/Users/oliverstaub/gitroot/RecipeJoe/.env",
            (#file as NSString).deletingLastPathComponent + "/../../.env",
            (#file as NSString).deletingLastPathComponent + "/../../../.env",
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
            print("⚠️ IntegrationTestConfig: .env file not found")
            return values
        }

        guard let content = try? String(contentsOfFile: path, encoding: .utf8) else {
            return values
        }

        let lines = content.components(separatedBy: .newlines)
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty || trimmed.hasPrefix("#") { continue }

            if let equalIndex = trimmed.firstIndex(of: "=") {
                let key = String(trimmed[..<equalIndex]).trimmingCharacters(in: .whitespaces)
                var value = String(trimmed[trimmed.index(after: equalIndex)...]).trimmingCharacters(in: .whitespaces)

                if (value.hasPrefix("\"") && value.hasSuffix("\"")) ||
                   (value.hasPrefix("'") && value.hasSuffix("'")) {
                    value = String(value.dropFirst().dropLast())
                }
                values[key] = value
            }
        }

        return values
    }

    private static func getValue(_ key: String) -> String? {
        if let envValue = ProcessInfo.processInfo.environment[key], !envValue.isEmpty {
            return envValue
        }
        return envValues[key]
    }

    // MARK: - Supabase Configuration

    static var supabaseURL: String {
        getValue("SUPABASE_URL") ?? "https://iqamjnyuvvmvakjdobsm.supabase.co"
    }

    static var supabaseAnonKey: String? {
        getValue("SUPABASE_ANON_KEY")
    }

    static var serviceRoleKey: String? {
        getValue("SUPABASE_SERVICE_ROLE_KEY")
    }

    static var testPasswordForNewUsers: String {
        getValue("TEST_PASSWORD_FOR_NEW_USERS") ?? "TestPassword123!"
    }

    // MARK: - Test User Configuration

    static var testUserEmail: String? {
        getValue("TEST_USER_EMAIL")
    }

    static var testUserPassword: String? {
        getValue("TEST_USER_PASSWORD")
    }

    static var hasTestCredentials: Bool {
        testUserEmail != nil && testUserPassword != nil
    }

    // MARK: - Test Data Prefixes

    static let testRecipePrefix = "[TEST] "
    static let testEmailDomain = "@recipejoe.test"

    // MARK: - Timeouts

    static let standardTimeout: TimeInterval = 10
    static let networkTimeout: TimeInterval = 30
}
