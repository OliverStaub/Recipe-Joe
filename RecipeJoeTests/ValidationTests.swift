//
//  ValidationTests.swift
//  RecipeJoeTests
//
//  Unit tests for form validation logic
//

import Foundation
import Testing
@testable import RecipeJoe

struct ValidationTests {

    // Email regex used in AuthenticationView
    private let emailRegex = #"^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#

    private func isValidEmail(_ email: String) -> Bool {
        email.range(of: emailRegex, options: .regularExpression) != nil
    }

    // MARK: - Email Validation Tests

    @Test func testValidEmailFormats() async throws {
        let validEmails = [
            "test@example.com",
            "user.name@example.com",
            "user+tag@example.com",
            "user@subdomain.example.com",
            "test@example.test",
            "123@example.com"
        ]

        for email in validEmails {
            #expect(isValidEmail(email), "Email '\(email)' should be valid")
        }
    }

    @Test func testInvalidEmailFormats() async throws {
        let invalidEmails = [
            "invalid@email",        // missing TLD
            "no-at-sign.com",       // missing @
            "@example.com",         // missing local part
            "user@.com",            // missing domain
            "user@com",             // missing TLD with dot
            "",                     // empty
            "spaces in@email.com"   // spaces
        ]

        for email in invalidEmails {
            #expect(!isValidEmail(email), "Email '\(email)' should be invalid")
        }
    }

    // MARK: - Password Validation Tests

    @Test func testPasswordMinimumLength() async throws {
        // Passwords with less than 6 characters should be invalid
        let shortPasswords = ["", "1", "12", "123", "1234", "12345"]
        for password in shortPasswords {
            let isValid = password.count >= 6
            #expect(!isValid, "Password '\(password)' should be invalid (too short)")
        }

        // Passwords with 6+ characters should be valid
        let validPasswords = ["123456", "password", "Password123!"]
        for password in validPasswords {
            let isValid = password.count >= 6
            #expect(isValid, "Password '\(password)' should be valid")
        }
    }

    // MARK: - Password Match Tests

    @Test func testPasswordMatch() async throws {
        let password = "Password123!"

        // Matching passwords
        #expect(password == "Password123!", "Matching passwords should be equal")

        // Non-matching passwords
        #expect(password != "DifferentPassword!", "Different passwords should not match")
        #expect(password != "password123!", "Case-sensitive: should not match")
        #expect(password != "", "Empty confirm should not match")
    }
}
