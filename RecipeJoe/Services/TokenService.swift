//
//  TokenService.swift
//  RecipeJoe
//
//  Service for managing virtual currency tokens via Supabase
//

import Combine
import Foundation

/// Token costs for different import types
enum ImportTokenCost: Int, Sendable {
    case website = 1   // HTML recipe website
    case video = 2     // YouTube, TikTok, Instagram
    case media = 3     // PDF or image (OCR)
}

/// Available token packages for purchase
enum TokenPackage: String, CaseIterable, Sendable {
    case starter = "tokens_10"      // 10 tokens - $1.99
    case popular = "tokens_25"      // 25 tokens - $3.99
    case bestValue = "tokens_50"    // 50 tokens - $6.99
    case bulk = "tokens_120"        // 120 tokens - $11.99

    var tokenCount: Int {
        switch self {
        case .starter: return 10
        case .popular: return 25
        case .bestValue: return 50
        case .bulk: return 120
        }
    }

    var displayName: String {
        switch self {
        case .starter: return "Starter Pack"
        case .popular: return "Popular Pack"
        case .bestValue: return "Best Value"
        case .bulk: return "Bulk Pack"
        }
    }
}

/// Token service errors
enum TokenServiceError: LocalizedError {
    case notConfigured
    case insufficientTokens(required: Int, available: Int)
    case purchaseFailed(String)
    case balanceNotAvailable
    case userNotAuthenticated

    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "Token service not configured"
        case .insufficientTokens(let required, let available):
            return "Not enough tokens. Need \(required), have \(available)"
        case .purchaseFailed(let message):
            return "Purchase failed: \(message)"
        case .balanceNotAvailable:
            return "Could not retrieve token balance"
        case .userNotAuthenticated:
            return "Please sign in to use tokens"
        }
    }
}

/// Service for managing token balance via Supabase
/// Balance is managed server-side in Supabase, not locally
@MainActor
final class TokenService: ObservableObject {
    // MARK: - Singleton

    static let shared = TokenService()

    // MARK: - Published Properties

    /// Current token balance (from Supabase)
    @Published private(set) var tokenBalance: Int = 0

    /// Whether token balance is loading
    @Published private(set) var isLoading: Bool = false

    // MARK: - Constants

    /// Free tokens for new users
    static let freeTokensForNewUsers = 15

    // MARK: - Initialization

    private init() {
        // Balance will be loaded from Supabase when user logs in
    }

    // MARK: - Balance Management (from Supabase)

    /// Refresh token balance from Supabase
    func refreshBalance() async throws {
        isLoading = true
        defer { isLoading = false }

        do {
            tokenBalance = try await SupabaseService.shared.fetchTokenBalance()
            syncBalanceToSharedStorage()
            print("Token balance from Supabase: \(tokenBalance)")
        } catch {
            print("Failed to fetch token balance: \(error)")
            throw TokenServiceError.balanceNotAvailable
        }
    }

    /// Update balance after an import (called with response from Edge Function)
    /// - Parameter newBalance: The new balance from the server response
    func updateBalance(_ newBalance: Int) {
        tokenBalance = newBalance
        syncBalanceToSharedStorage()
        print("Balance updated after import: \(tokenBalance)")
    }

    /// Sync balance to shared UserDefaults for share extension
    private func syncBalanceToSharedStorage() {
        SharedUserDefaults.shared.tokenBalance = tokenBalance
    }

    // MARK: - Token Checks (for UI)

    /// Check if user has enough tokens for an import type
    func canAffordImport(type: ImportTokenCost) -> Bool {
        tokenBalance >= type.rawValue
    }

    /// Check if user has enough tokens for a specific amount
    func canAfford(amount: Int) -> Bool {
        tokenBalance >= amount
    }

    // MARK: - Helper Methods

    /// Get token count for a product identifier
    func tokenCountForProduct(_ productId: String) -> Int {
        if productId.contains("120") { return 120 }
        if productId.contains("50") { return 50 }
        if productId.contains("25") { return 25 }
        if productId.contains("10") { return 10 }
        return 0
    }
}
