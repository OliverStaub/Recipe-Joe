//
//  AuthenticationService.swift
//  RecipeJoe
//
//  Handles Apple Sign In authentication via Supabase
//

import AuthenticationServices
import Combine
import Foundation
import Supabase

/// Service to manage user authentication with Apple Sign In via Supabase
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

    var errorDescription: String? {
        switch self {
        case .invalidCredential:
            return "Invalid Apple ID credential"
        case .notAuthenticated:
            return "You must be signed in to perform this action"
        case .signInFailed(let message):
            return "Sign in failed: \(message)"
        }
    }
}
