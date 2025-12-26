//
//  AuthenticationErrorTests.swift
//  RecipeJoeTests
//
//  Unit tests for AuthenticationError enum and error descriptions
//

import Foundation
import Testing
@testable import RecipeJoe

struct AuthenticationErrorTests {

    // MARK: - Error Description Tests

    @Test("Invalid credential error has descriptive message")
    func testInvalidCredentialError() async throws {
        let error = AuthenticationError.invalidCredential
        #expect(error.errorDescription?.contains("Apple") == true ||
               error.errorDescription?.contains("credential") == true,
               "Should mention credential issue")
    }

    @Test("Not authenticated error explains action requirement")
    func testNotAuthenticatedError() async throws {
        let error = AuthenticationError.notAuthenticated
        #expect(error.errorDescription?.contains("signed in") == true,
               "Should mention sign in requirement")
    }

    @Test("Invalid email error provides guidance")
    func testInvalidEmailError() async throws {
        let error = AuthenticationError.invalidEmail
        #expect(error.errorDescription?.contains("email") == true,
               "Should mention email")
    }

    @Test("Weak password error mentions minimum length")
    func testWeakPasswordError() async throws {
        let error = AuthenticationError.weakPassword
        #expect(error.errorDescription?.contains("6") == true,
               "Should mention 6 character minimum")
    }

    @Test("Invalid credentials error is user-friendly")
    func testInvalidCredentialsError() async throws {
        let error = AuthenticationError.invalidCredentials
        #expect(error.errorDescription?.contains("Invalid") == true,
               "Should indicate invalid credentials")
    }

    @Test("Email confirmation required error gives instructions")
    func testEmailConfirmationRequiredError() async throws {
        let error = AuthenticationError.emailConfirmationRequired
        #expect(error.errorDescription?.contains("email") == true &&
               error.errorDescription?.contains("confirm") == true,
               "Should mention email confirmation")
    }

    @Test("Sign in failed error includes reason")
    func testSignInFailedError() async throws {
        let reason = "Network timeout"
        let error = AuthenticationError.signInFailed(reason)
        #expect(error.errorDescription?.contains(reason) == true,
               "Should include the failure reason")
    }

    @Test("Sign up failed error includes reason")
    func testSignUpFailedError() async throws {
        let reason = "Server unavailable"
        let error = AuthenticationError.signUpFailed(reason)
        #expect(error.errorDescription?.contains(reason) == true,
               "Should include the failure reason")
    }

    @Test("User already exists error is clear")
    func testUserAlreadyExistsError() async throws {
        let error = AuthenticationError.userAlreadyExists
        #expect(error.errorDescription?.contains("already exists") == true ||
               error.errorDescription?.contains("already") == true,
               "Should indicate account exists")
    }

    // MARK: - LocalizedError Conformance

    @Test("All errors have non-nil descriptions")
    func testAllErrorsHaveDescriptions() async throws {
        let errors: [AuthenticationError] = [
            .invalidCredential,
            .notAuthenticated,
            .signInFailed("test"),
            .invalidEmail,
            .weakPassword,
            .invalidCredentials,
            .emailConfirmationRequired,
            .signUpFailed("test"),
            .userAlreadyExists
        ]

        for error in errors {
            #expect(error.errorDescription != nil, "Error \(error) should have a description")
            #expect(!error.errorDescription!.isEmpty, "Error \(error) description should not be empty")
        }
    }

    @Test("Error descriptions are user-friendly (no technical jargon)")
    func testErrorDescriptionsAreUserFriendly() async throws {
        let errors: [AuthenticationError] = [
            .invalidCredential,
            .notAuthenticated,
            .invalidEmail,
            .weakPassword,
            .invalidCredentials,
            .emailConfirmationRequired,
            .userAlreadyExists
        ]

        let technicalTerms = ["nil", "null", "exception", "fatal", "crash", "stack"]

        for error in errors {
            let description = error.errorDescription?.lowercased() ?? ""
            for term in technicalTerms {
                #expect(!description.contains(term),
                       "Error description should not contain technical term '\(term)'")
            }
        }
    }
}
