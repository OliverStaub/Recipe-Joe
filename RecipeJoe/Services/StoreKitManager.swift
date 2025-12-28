//
//  StoreKitManager.swift
//  RecipeJoe
//
//  Manages StoreKit 2 in-app purchases for token packages
//

import Combine
import StoreKit

/// Manages StoreKit 2 in-app purchases for token packages
@MainActor
final class StoreKitManager: ObservableObject {
    // MARK: - Singleton

    static let shared = StoreKitManager()

    // MARK: - Published Properties

    /// Available products for purchase
    @Published private(set) var products: [Product] = []

    /// Whether a purchase is in progress
    @Published private(set) var purchaseInProgress = false

    /// Last error that occurred
    @Published private(set) var lastError: String?

    // MARK: - Private Properties

    private let productIds = ["tokens_10", "tokens_25", "tokens_50", "tokens_120"]
    private var transactionListener: Task<Void, Error>?

    // MARK: - Initialization

    private init() {
        transactionListener = listenForTransactions()
        Task {
            await loadProducts()
        }
    }

    deinit {
        transactionListener?.cancel()
    }

    // MARK: - Load Products

    /// Load available products from the App Store
    func loadProducts() async {
        do {
            products = try await Product.products(for: productIds)
                .sorted { tokenCount(for: $0.id) < tokenCount(for: $1.id) }
            Log.debug("Loaded \(products.count) products", category: Log.storeKit)
        } catch {
            Log.error("Failed to load products: \(error)", category: Log.storeKit)
            lastError = error.localizedDescription
        }
    }

    // MARK: - Purchase

    /// Purchase a product
    /// - Parameter product: The product to purchase
    /// - Returns: true if purchase was successful, false if cancelled or failed
    func purchase(_ product: Product) async throws -> Bool {
        purchaseInProgress = true
        lastError = nil
        defer { purchaseInProgress = false }

        let result = try await product.purchase()

        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)

            // Validate with server and credit tokens
            do {
                try await validateAndCreditPurchase(transaction: transaction, product: product)
            } catch {
                // If server validation fails, we still finish the transaction
                // but report the error
                Log.error("Server validation failed: \(error)", category: Log.storeKit)
                lastError = error.localizedDescription
                await transaction.finish()
                throw error
            }

            await transaction.finish()
            return true

        case .pending:
            // Transaction is pending (e.g., parental approval needed)
            return false

        case .userCancelled:
            return false

        @unknown default:
            return false
        }
    }

    // MARK: - Validate with Server

    /// Validate the purchase with the server and credit tokens
    private func validateAndCreditPurchase(transaction: Transaction, product: Product) async throws {
        try await SupabaseService.shared.validatePurchase(
            transactionId: String(transaction.id),
            productId: product.id,
            originalTransactionId: String(transaction.originalID)
        )
    }

    // MARK: - Transaction Listener

    /// Listen for transaction updates (e.g., interrupted purchases)
    private func listenForTransactions() -> Task<Void, Error> {
        Task.detached {
            for await result in Transaction.updates {
                do {
                    let transaction = try await self.checkVerified(result)

                    // Handle transaction (e.g., from interrupted purchase)
                    // Note: We don't validate with server here because we might not
                    // be in a state to update the UI properly
                    await transaction.finish()

                    // Refresh token balance to pick up any changes
                    try? await TokenService.shared.refreshBalance()
                } catch {
                    Log.error("Transaction verification failed: \(error)", category: Log.storeKit)
                }
            }
        }
    }

    /// Verify a transaction result
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .verified(let value):
            return value
        case .unverified(_, let error):
            throw error
        }
    }

    // MARK: - Helpers

    /// Get the token count for a product ID
    func tokenCount(for productId: String) -> Int {
        if productId.contains("120") { return 120 }
        if productId.contains("50") { return 50 }
        if productId.contains("25") { return 25 }
        if productId.contains("10") { return 10 }
        return 0
    }

    /// Get product for a token package
    func product(for package: TokenPackage) -> Product? {
        products.first { $0.id == package.rawValue }
    }
}
