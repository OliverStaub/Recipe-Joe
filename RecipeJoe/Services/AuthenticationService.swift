//
//  AuthenticationService.swift
//  RecipeJoe
//
//  Handles authentication via Supabase (Apple Sign In and Email/Password)
//

import AuthenticationServices
import Combine
import Foundation
import Supabase

/// Service to manage user authentication via Supabase (Apple Sign In and Email/Password)
@MainActor
final class AuthenticationService: ObservableObject {
    // MARK: - Singleton

    static let shared = AuthenticationService()

    // MARK: - Published Properties

    /// The currently authenticated user
    @Published private(set) var currentUser: User?

    /// Whether the user is authenticated
    @Published private(set) var isAuthenticated: Bool = false

    /// Whether authentication state is being loaded
    @Published private(set) var isLoading: Bool = true

    /// Error message to display
    @Published var errorMessage: String?

    // MARK: - Private Properties

    private var authStateTask: Task<Void, Never>?

    // MARK: - Initialization

    private init() {
        Task {
            await setupAuthStateListener()
        }
    }

    deinit {
        authStateTask?.cancel()
    }

    // MARK: - Auth State Management

    /// Sets up a listener for authentication state changes
    private func setupAuthStateListener() async {
        // Check initial session
        do {
            let session = try await SupabaseService.shared.client.auth.session
            self.currentUser = session.user
            self.isAuthenticated = true
        } catch {
            self.currentUser = nil
            self.isAuthenticated = false
        }
        self.isLoading = false

        // Listen for auth state changes
        authStateTask = Task {
            for await (event, session) in SupabaseService.shared.client.auth.authStateChanges {
                guard !Task.isCancelled else { return }

                switch event {
                case .signedIn:
                    self.currentUser = session?.user
                    self.isAuthenticated = true
                case .signedOut:
                    self.currentUser = nil
                    self.isAuthenticated = false
                    // Clear cached data on sign out
                    await clearUserData()
                case .tokenRefreshed:
                    self.currentUser = session?.user
                case .userUpdated:
                    self.currentUser = session?.user
                default:
                    break
                }
            }
        }
    }

    // MARK: - Sign In with Apple

    /// Sign in with Apple using the provided credential
    /// - Parameter credential: The ASAuthorizationAppleIDCredential from Apple Sign In
    func signInWithApple(credential: ASAuthorizationAppleIDCredential) async throws {
        guard let identityToken = credential.identityToken,
              let tokenString = String(data: identityToken, encoding: .utf8) else {
            throw AuthenticationError.invalidCredential
        }

        isLoading = true
        errorMessage = nil

        do {
            let session = try await SupabaseService.shared.client.auth.signInWithIdToken(
                credentials: .init(
                    provider: .apple,
                    idToken: tokenString
                )
            )

            self.currentUser = session.user
            self.isAuthenticated = true
        } catch {
            self.errorMessage = error.localizedDescription
            throw error
        }

        isLoading = false
    }

    // MARK: - Email/Password Authentication

    /// Sign up with email and password
    /// - Parameters:
    ///   - email: User's email address
    ///   - password: User's password (min 6 characters)
    func signUp(email: String, password: String) async throws {
        guard isValidEmail(email) else {
            throw AuthenticationError.invalidEmail
        }

        guard password.count >= 6 else {
            throw AuthenticationError.weakPassword
        }

        isLoading = true
        errorMessage = nil

        do {
            let response = try await SupabaseService.shared.client.auth.signUp(
                email: email,
                password: password
            )

            // Check if email confirmation is required
            if response.session != nil {
                self.currentUser = response.user
                self.isAuthenticated = true
            } else {
                // Email confirmation required
                throw AuthenticationError.emailConfirmationRequired
            }
        } catch let error as AuthenticationError {
            self.errorMessage = error.localizedDescription
            isLoading = false
            throw error
        } catch {
            self.errorMessage = error.localizedDescription
            isLoading = false
            throw AuthenticationError.signUpFailed(error.localizedDescription)
        }

        isLoading = false
    }

    /// Sign in with email and password
    /// - Parameters:
    ///   - email: User's email address
    ///   - password: User's password
    func signIn(email: String, password: String) async throws {
        guard isValidEmail(email) else {
            throw AuthenticationError.invalidEmail
        }

        isLoading = true
        errorMessage = nil

        do {
            let session = try await SupabaseService.shared.client.auth.signIn(
                email: email,
                password: password
            )

            self.currentUser = session.user
            self.isAuthenticated = true
        } catch {
            self.errorMessage = "Invalid email or password"
            isLoading = false
            throw AuthenticationError.invalidCredentials
        }

        isLoading = false
    }

    /// Send password reset email
    /// - Parameter email: User's email address
    func resetPassword(email: String) async throws {
        guard isValidEmail(email) else {
            throw AuthenticationError.invalidEmail
        }

        isLoading = true
        errorMessage = nil

        do {
            try await SupabaseService.shared.client.auth.resetPasswordForEmail(email)
        } catch {
            self.errorMessage = error.localizedDescription
            isLoading = false
            throw error
        }

        isLoading = false
    }

    /// Validate email format
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = #"^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        return email.range(of: emailRegex, options: .regularExpression) != nil
    }

    // MARK: - Sign Out

    /// Sign out the current user
    func signOut() async throws {
        isLoading = true
        errorMessage = nil

        do {
            try await SupabaseService.shared.client.auth.signOut()
            self.currentUser = nil
            self.isAuthenticated = false
            await clearUserData()
        } catch {
            self.errorMessage = error.localizedDescription
            throw error
        }

        isLoading = false
    }

    // MARK: - Delete Account

    /// Delete the user's account and all associated data
    func deleteAccount() async throws {
        guard currentUser != nil else {
            throw AuthenticationError.notAuthenticated
        }

        isLoading = true
        errorMessage = nil

        do {
            // First clear local data
            await clearUserData()

            // Note: Actual account deletion requires a server-side function
            // For now, just sign out. Full deletion can be added via Edge Function
            try await SupabaseService.shared.client.auth.signOut()

            self.currentUser = nil
            self.isAuthenticated = false
        } catch {
            self.errorMessage = error.localizedDescription
            throw error
        }

        isLoading = false
    }

    // MARK: - Helper Methods

    /// Clear all cached user data
    private func clearUserData() async {
        do {
            try await RecipeCacheService.shared.clearCache()
        } catch {
            print("Failed to clear cache: \(error)")
        }
    }

    /// Get the current user's ID
    var currentUserId: UUID? {
        currentUser?.id
    }

    /// Get the current user's email
    var currentUserEmail: String? {
        currentUser?.email
    }
}

// MARK: - Errors

enum AuthenticationError: LocalizedError {
    case invalidCredential
    case notAuthenticated
    case signInFailed(String)
    case invalidEmail
    case weakPassword
    case invalidCredentials
    case emailConfirmationRequired
    case signUpFailed(String)
    case userAlreadyExists

    var errorDescription: String? {
        switch self {
        case .invalidCredential:
            return "Invalid Apple ID credential"
        case .notAuthenticated:
            return "You must be signed in to perform this action"
        case .signInFailed(let message):
            return "Sign in failed: \(message)"
        case .invalidEmail:
            return "Please enter a valid email address"
        case .weakPassword:
            return "Password must be at least 6 characters"
        case .invalidCredentials:
            return "Invalid email or password"
        case .emailConfirmationRequired:
            return "Please check your email to confirm your account"
        case .signUpFailed(let message):
            return "Sign up failed: \(message)"
        case .userAlreadyExists:
            return "An account with this email already exists"
        }
    }
}
