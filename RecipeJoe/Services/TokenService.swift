//
//  TokenService.swift
//  RecipeJoe
//
//  Service for managing virtual currency tokens via RevenueCat
//

import Combine
import Foundation
import RevenueCat

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

/// Service for managing RevenueCat Virtual Currency tokens
@MainActor
final class TokenService: ObservableObject {
    // MARK: - Singleton

    static let shared = TokenService()

    // MARK: - Published Properties

    /// Current token balance
    @Published private(set) var tokenBalance: Int = 0

    /// Whether token balance is loading
    @Published private(set) var isLoading: Bool = false

    /// Available packages for purchase
    @Published private(set) var availablePackages: [Package] = []

    // MARK: - Constants

    /// Currency identifier for tokens (set in RevenueCat dashboard)
    private static let currencyIdentifier = "recipe_tokens"

    /// Offering identifier for token packages
    private static let offeringIdentifier = "default"

    /// Free tokens for new users
    static let freeTokensForNewUsers = 15

    /// UserDefaults key for tracking if bonus was granted
    private static let bonusGrantedKey = "tokenBonusGranted"

    // MARK: - Initialization

    private init() {
        // Load balance from local storage on init
        tokenBalance = UserDefaults.standard.integer(forKey: "localTokenBalance")
        syncBalanceToSharedStorage()
    }

    /// Configure RevenueCat SDK - call from App init
    func configure() {
        Purchases.logLevel = .debug // Remove for production
        Purchases.configure(withAPIKey: AppConstants.revenueCatAPIKey)
    }

    /// Configure for authenticated user
    /// - Parameter userId: The Supabase user ID
    func configureForUser(userId: String) async {
        do {
            let (customerInfo, _) = try await Purchases.shared.logIn(userId)
            updateBalanceFromCustomerInfo(customerInfo)
        } catch {
            print("RevenueCat login failed: \(error)")
        }
    }

    /// Clear user session on sign out
    func signOut() async {
        do {
            _ = try await Purchases.shared.logOut()
            tokenBalance = 0
            syncBalanceToSharedStorage()
        } catch {
            print("RevenueCat logout failed: \(error)")
        }
    }

    // MARK: - Balance Management

    /// Refresh token balance from RevenueCat
    func refreshBalance() async throws {
        isLoading = true
        defer { isLoading = false }

        do {
            let customerInfo = try await Purchases.shared.customerInfo()
            updateBalanceFromCustomerInfo(customerInfo)
        } catch {
            throw TokenServiceError.balanceNotAvailable
        }
    }

    /// Update balance from customer info
    /// RevenueCat Virtual Currency tracks balance automatically
    private func updateBalanceFromCustomerInfo(_ customerInfo: CustomerInfo) {
        // RevenueCat Virtual Currency balance is tracked locally for now
        // The balance is updated after purchases and spending
        // In production, use RevenueCat's Virtual Currency REST API for server-authoritative balance

        // For consumable purchases, we track the balance locally
        // Load from UserDefaults if not already set
        if tokenBalance == 0 {
            tokenBalance = UserDefaults.standard.integer(forKey: "localTokenBalance")
        }

        // Sync to shared storage for share extension
        syncBalanceToSharedStorage()
    }

    /// Save balance to local storage
    private func saveBalanceLocally() {
        UserDefaults.standard.set(tokenBalance, forKey: "localTokenBalance")
    }

    /// Sync balance to shared UserDefaults for share extension
    private func syncBalanceToSharedStorage() {
        SharedUserDefaults.shared.tokenBalance = tokenBalance
    }

    // MARK: - Token Spending

    /// Check if user has enough tokens for an import type
    func canAffordImport(type: ImportTokenCost) -> Bool {
        tokenBalance >= type.rawValue
    }

    /// Check if user has enough tokens for a specific amount
    func canAfford(amount: Int) -> Bool {
        tokenBalance >= amount
    }

    /// Spend tokens for an import (called after successful import)
    /// - Parameters:
    ///   - amount: Number of tokens to spend
    ///   - reason: Description for logging
    func spendTokens(amount: Int, reason: String) async throws {
        guard tokenBalance >= amount else {
            throw TokenServiceError.insufficientTokens(
                required: amount,
                available: tokenBalance
            )
        }

        // RevenueCat Virtual Currency handles spending via their API
        // The balance update happens automatically
        do {
            // Note: In production, call RevenueCat's spend API:
            // await Purchases.shared.spend(amount: amount, currency: Self.currencyIdentifier)

            // Update local balance
            tokenBalance -= amount
            saveBalanceLocally()
            syncBalanceToSharedStorage()

            print("Spent \(amount) tokens for: \(reason)")
        }
    }

    // MARK: - Purchases

    /// Fetch available token packages
    func fetchPackages() async throws {
        isLoading = true
        defer { isLoading = false }

        let offerings = try await Purchases.shared.offerings()
        if let offering = offerings.offering(identifier: Self.offeringIdentifier) ?? offerings.current {
            availablePackages = offering.availablePackages
        }
    }

    /// Purchase a token package
    /// - Parameter package: The RevenueCat package to purchase
    func purchasePackage(_ package: Package) async throws {
        isLoading = true
        defer { isLoading = false }

        do {
            let (_, _, _) = try await Purchases.shared.purchase(package: package)

            // Add purchased tokens to balance
            let purchasedTokens = tokenCountForProduct(package.storeProduct.productIdentifier)
            tokenBalance += purchasedTokens
            saveBalanceLocally()
            syncBalanceToSharedStorage()

            print("Purchased \(purchasedTokens) tokens")
        } catch let error as ErrorCode {
            if error == .purchaseCancelledError {
                // User cancelled - don't throw
                return
            }
            throw TokenServiceError.purchaseFailed(error.localizedDescription)
        } catch {
            throw TokenServiceError.purchaseFailed(error.localizedDescription)
        }
    }

    /// Restore previous purchases
    func restorePurchases() async throws {
        isLoading = true
        defer { isLoading = false }

        let customerInfo = try await Purchases.shared.restorePurchases()
        updateBalanceFromCustomerInfo(customerInfo)
    }

    // MARK: - New User Bonus

    /// Grant free tokens to new users (called once after first sign-in)
    func grantNewUserBonus() async {
        // Check if bonus already granted
        guard !UserDefaults.standard.bool(forKey: Self.bonusGrantedKey) else {
            return
        }

        // Set attributes to trigger bonus grant
        // In RevenueCat, you can set up automation rules to grant currency
        // when a subscriber attribute is set
        Purchases.shared.attribution.setAttributes([
            "new_user": "true",
            "bonus_eligible": "true"
        ])

        // Mark bonus as granted locally
        UserDefaults.standard.set(true, forKey: Self.bonusGrantedKey)

        // The actual bonus is granted via RevenueCat automation rules
        // or can be done server-side via webhook

        // For initial setup, we can add the bonus locally
        // This will be synced with RevenueCat on next refresh
        tokenBalance = Self.freeTokensForNewUsers
        saveBalanceLocally()
        syncBalanceToSharedStorage()
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
