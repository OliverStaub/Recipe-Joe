//
//  TokenServiceTests.swift
//  RecipeJoeTests
//
//  Unit tests for TokenService and related types
//

import Foundation
import RevenueCat
import Testing
@testable import RecipeJoe

struct TokenServiceTests {

    // MARK: - ImportTokenCost Tests

    @Test func testImportTokenCostValues() async throws {
        #expect(ImportTokenCost.website.rawValue == 1)
        #expect(ImportTokenCost.video.rawValue == 2)
        #expect(ImportTokenCost.media.rawValue == 3)
    }

    @Test func testImportTokenCostComparison() async throws {
        // Media should be most expensive
        #expect(ImportTokenCost.media.rawValue > ImportTokenCost.video.rawValue)
        #expect(ImportTokenCost.video.rawValue > ImportTokenCost.website.rawValue)
    }

    // MARK: - TokenPackage Tests

    @Test func testTokenPackageValues() async throws {
        #expect(TokenPackage.starter.tokenCount == 10)
        #expect(TokenPackage.popular.tokenCount == 25)
        #expect(TokenPackage.bestValue.tokenCount == 50)
        #expect(TokenPackage.bulk.tokenCount == 120)
    }

    @Test func testTokenPackageIdentifiers() async throws {
        #expect(TokenPackage.starter.rawValue == "tokens_10")
        #expect(TokenPackage.popular.rawValue == "tokens_25")
        #expect(TokenPackage.bestValue.rawValue == "tokens_50")
        #expect(TokenPackage.bulk.rawValue == "tokens_120")
    }

    @Test func testTokenPackageDisplayNames() async throws {
        #expect(TokenPackage.starter.displayName == "Starter Pack")
        #expect(TokenPackage.popular.displayName == "Popular Pack")
        #expect(TokenPackage.bestValue.displayName == "Best Value")
        #expect(TokenPackage.bulk.displayName == "Bulk Pack")
    }

    @Test func testTokenPackageAllCases() async throws {
        // Ensure all packages are enumerated
        #expect(TokenPackage.allCases.count == 4)
        #expect(TokenPackage.allCases.contains(.starter))
        #expect(TokenPackage.allCases.contains(.popular))
        #expect(TokenPackage.allCases.contains(.bestValue))
        #expect(TokenPackage.allCases.contains(.bulk))
    }

    // MARK: - TokenServiceError Tests

    @Test func testTokenServiceErrorNotConfigured() async throws {
        let error = TokenServiceError.notConfigured
        #expect(error.errorDescription?.contains("not configured") == true)
    }

    @Test func testTokenServiceErrorInsufficientTokens() async throws {
        let error = TokenServiceError.insufficientTokens(required: 5, available: 2)
        let description = error.errorDescription ?? ""

        #expect(description.contains("5"))
        #expect(description.contains("2"))
        #expect(description.contains("Not enough") || description.contains("tokens"))
    }

    @Test func testTokenServiceErrorPurchaseFailed() async throws {
        let error = TokenServiceError.purchaseFailed("Payment declined")
        let description = error.errorDescription ?? ""

        #expect(description.contains("Payment declined"))
        #expect(description.contains("failed") || description.contains("Purchase"))
    }

    @Test func testTokenServiceErrorBalanceNotAvailable() async throws {
        let error = TokenServiceError.balanceNotAvailable
        #expect(error.errorDescription?.contains("balance") == true)
    }

    @Test func testTokenServiceErrorUserNotAuthenticated() async throws {
        let error = TokenServiceError.userNotAuthenticated
        #expect(error.errorDescription?.contains("sign in") == true)
    }

    // MARK: - Token Cost Calculation Tests

    @Test func testTokenCostForWebsite() async throws {
        let viewModel = await RecipeImportViewModel()
        let cost = await viewModel.getTokenCost(for: "https://www.allrecipes.com/recipe/12345")
        #expect(cost == .website)
        #expect(cost.rawValue == 1)
    }

    @Test func testTokenCostForYouTube() async throws {
        let viewModel = await RecipeImportViewModel()
        let cost = await viewModel.getTokenCost(for: "https://www.youtube.com/watch?v=dQw4w9WgXcQ")
        #expect(cost == .video)
        #expect(cost.rawValue == 2)
    }

    @Test func testTokenCostForTikTok() async throws {
        let viewModel = await RecipeImportViewModel()
        let cost = await viewModel.getTokenCost(for: "https://www.tiktok.com/@chef/video/1234567890")
        #expect(cost == .video)
        #expect(cost.rawValue == 2)
    }

    @Test func testTokenCostForInstagram() async throws {
        let viewModel = await RecipeImportViewModel()
        let cost = await viewModel.getTokenCost(for: "https://www.instagram.com/reel/ABC123/")
        #expect(cost == .video)
        #expect(cost.rawValue == 2)
    }

    // MARK: - Free Tokens Constant Tests

    @Test func testFreeTokensForNewUsers() async throws {
        #expect(TokenService.freeTokensForNewUsers == 15)
    }

    // MARK: - Token Service Helper Tests

    @Test func testTokenCountForProductIdentifiers() async throws {
        let service = await TokenService.shared

        #expect(await service.tokenCountForProduct("tokens_10") == 10)
        #expect(await service.tokenCountForProduct("tokens_25") == 25)
        #expect(await service.tokenCountForProduct("tokens_50") == 50)
        #expect(await service.tokenCountForProduct("tokens_120") == 120)
        #expect(await service.tokenCountForProduct("unknown_product") == 0)
    }

    @Test func testTokenCountForProductWithPrefix() async throws {
        let service = await TokenService.shared

        // Product IDs might have platform prefixes
        #expect(await service.tokenCountForProduct("com.recipejoe.tokens_10") == 10)
        #expect(await service.tokenCountForProduct("ios_tokens_120") == 120)
    }

    // MARK: - RevenueCat Integration Tests

    /// Integration test for RevenueCat offerings - disabled by default as it requires network
    /// Run manually with: -only-testing:RecipeJoeTests/TokenServiceTests/testRevenueCatOfferingsAvailable
    @Test(.disabled("Integration test - run manually to verify RevenueCat setup"))
    func testRevenueCatOfferingsAvailable() async throws {
        // Configure RevenueCat if not already configured
        Purchases.logLevel = .debug
        if Purchases.isConfigured == false {
            Purchases.configure(withAPIKey: AppConstants.revenueCatAPIKey)
        }

        // Fetch offerings
        let offerings = try await Purchases.shared.offerings()

        // Log what we found
        print("=== RevenueCat Offerings Debug ===")
        print("Current offering: \(offerings.current?.identifier ?? "NONE")")
        print("All offerings: \(offerings.all.keys.joined(separator: ", "))")

        // Check for "default" offering specifically
        let defaultOffering = offerings.offering(identifier: "default")
        print("Default offering found: \(defaultOffering != nil)")

        if let offering = defaultOffering ?? offerings.current {
            print("Packages in offering:")
            for package in offering.availablePackages {
                print("  - \(package.identifier): \(package.storeProduct.productIdentifier) @ \(package.storeProduct.localizedPriceString)")
            }
        }

        // Test that we have the "default" offering or a current offering
        let activeOffering = defaultOffering ?? offerings.current
        #expect(activeOffering != nil, "No 'default' or current offering found - check RevenueCat dashboard")

        // Test that we have the expected packages
        if let offering = activeOffering {
            #expect(offering.availablePackages.count >= 1, "No packages in offering")
            print("✅ Found \(offering.availablePackages.count) packages")
        }

        print("=================================")
    }
}
