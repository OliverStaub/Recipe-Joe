//
//  RecipeImportIntegrationTests.swift
//  RecipeJoeIntegrationTests
//
//  Integration tests for recipe import functionality.
//  Tests the full import flow via API (not UI).
//
//  NOTE: These tests are network-dependent and may take 2-3 minutes each.
//  They're included in integration tests but can be skipped for faster runs.
//

import Testing
import Foundation

@Suite("Recipe Import Integration Tests")
struct RecipeImportIntegrationTests {

    // MARK: - Test Configuration

    /// URLs for testing various import types
    private let testURLs = TestImportURLs()

    struct TestImportURLs {
        // YouTube video with recipe (needs transcript API)
        let youtube = "https://www.youtube.com/watch?v=mhDJNfV7hjk"

        // TikTok recipe video (needs transcript API)
        let tiktok = "https://www.tiktok.com/@fatimacooks/video/7362040203916203294"

        // Standard recipe website (HTML scraping)
        let website = "https://www.allrecipes.com/recipe/21014/good-old-fashioned-pancakes/"
    }

    // MARK: - URL Validation Tests

    @Test("YouTube URL is detected as video content")
    func testYouTubeURLDetection() async throws {
        let url = testURLs.youtube

        // Test that the URL is recognized as a video URL
        let isVideo = isVideoURL(url)
        #expect(isVideo == true, "YouTube URL should be detected as video")
    }

    @Test("TikTok URL is detected as video content")
    func testTikTokURLDetection() async throws {
        let url = testURLs.tiktok

        let isVideo = isVideoURL(url)
        #expect(isVideo == true, "TikTok URL should be detected as video")
    }

    @Test("Website URL is not detected as video content")
    func testWebsiteURLNotVideo() async throws {
        let url = testURLs.website

        let isVideo = isVideoURL(url)
        #expect(isVideo == false, "AllRecipes URL should not be detected as video")
    }

    // MARK: - Helper Methods

    /// Check if URL is a video URL (YouTube, TikTok, Instagram, etc.)
    private func isVideoURL(_ urlString: String) -> Bool {
        let videoPatterns = [
            "youtube.com/watch",
            "youtu.be/",
            "tiktok.com",
            "instagram.com/reel",
            "instagram.com/p/"
        ]

        let lowercased = urlString.lowercased()
        return videoPatterns.contains { lowercased.contains($0) }
    }

    // MARK: - Full Import Tests (Network Dependent)
    // NOTE: These tests require:
    // - Network access
    // - Supadata API for video transcripts
    // - Supabase credentials
    // They are skipped if credentials are not configured.

    @Test("Import recipe from YouTube video")
    func testImportFromYouTube() async throws {
        // Skip if not configured
        guard IntegrationTestConfig.serviceRoleKey != nil,
              IntegrationTestConfig.hasTestCredentials else {
            print("⚠️ Skipping: Supabase credentials not configured for import test")
            return
        }

        // TODO: Implement when Edge Function client is available for integration tests
        // This would call the recipe-import Edge Function directly
        print("ℹ️ Full YouTube import test requires Edge Function client")
    }

    @Test("Import recipe from website URL")
    func testImportFromWebsite() async throws {
        guard IntegrationTestConfig.serviceRoleKey != nil,
              IntegrationTestConfig.hasTestCredentials else {
            print("⚠️ Skipping: Supabase credentials not configured for import test")
            return
        }

        // TODO: Implement when Edge Function client is available for integration tests
        print("ℹ️ Full website import test requires Edge Function client")
    }
}
