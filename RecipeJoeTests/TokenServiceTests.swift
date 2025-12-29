//
//  TokenServiceTests.swift
//  RecipeJoeTests
//
//  Unit tests for TokenService and related types
//

import Foundation
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
        #expect(TokenPackage.bulk.tokenCount == 100)
    }

    @Test func testTokenPackageIdentifiers() async throws {
        #expect(TokenPackage.starter.rawValue == "tokens_10")
        #expect(TokenPackage.popular.rawValue == "tokens_25")
        #expect(TokenPackage.bestValue.rawValue == "tokens_50")
        #expect(TokenPackage.bulk.rawValue == "tokens_100x")
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
        #expect(await service.tokenCountForProduct("tokens_100x") == 100)
        #expect(await service.tokenCountForProduct("unknown_product") == 0)
    }

    @Test func testTokenCountForProductWithPrefix() async throws {
        let service = await TokenService.shared

        // Product IDs might have platform prefixes
        #expect(await service.tokenCountForProduct("com.recipejoe.tokens_10") == 10)
        #expect(await service.tokenCountForProduct("ios_tokens_100x") == 100)
    }

    // MARK: - Balance Check Tests

    @Test func testCanAffordImport_withZeroBalance() async throws {
        let service = await TokenService.shared
        let currentBalance = await service.tokenBalance

        // If balance is 0, should not afford any import
        if currentBalance == 0 {
            #expect(await service.canAffordImport(type: .website) == false)
            #expect(await service.canAffordImport(type: .video) == false)
            #expect(await service.canAffordImport(type: .media) == false)
        }
    }

    @Test func testCanAfford_checksBalance() async throws {
        let service = await TokenService.shared
        let currentBalance = await service.tokenBalance

        // Should be able to afford amounts <= balance
        #expect(await service.canAfford(amount: 0) == true)
        if currentBalance > 0 {
            #expect(await service.canAfford(amount: currentBalance) == true)
        }
        // Should not afford more than balance
        #expect(await service.canAfford(amount: currentBalance + 1) == false)
        #expect(await service.canAfford(amount: currentBalance + 100) == false)
    }

    // Note: Token spending is now done server-side in Edge Functions.
    // The TokenService no longer has a spendTokens method.
    // Token balance is deducted by the Edge Function and returned in the response.
}
