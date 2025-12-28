//
//  RecipeImportViewModel.swift
//  RecipeJoe
//
//  ViewModel for recipe URL import functionality
//

import Combine
import Foundation
import SwiftUI

@MainActor
final class RecipeImportViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var importState: ImportState = .idle
    @Published var currentStep: ImportStep = .fetching
    @Published var lastImportedRecipeId: UUID?
    @Published var lastImportedRecipeName: String?
    @Published var lastImportStats: ImportStats?

    // Video timestamp properties
    @Published var startTimestamp: String = ""
    @Published var endTimestamp: String = ""

    // Token-related properties
    @Published var showInsufficientTokensAlert: Bool = false
    @Published var requiredTokens: Int = 0

    // MARK: - Video URL Detection Patterns

    private static let videoPatterns: [(platform: String, pattern: NSRegularExpression)] = {
        let patterns: [(String, String)] = [
            ("youtube", #"(?:youtube\.com\/(?:watch\?.*v=|shorts\/)|youtu\.be\/)[a-zA-Z0-9_-]+"#),
            ("instagram", #"instagram\.com\/(?:reel|p)\/[a-zA-Z0-9_-]+"#),
            ("tiktok", #"tiktok\.com\/@[\w.-]+\/video\/\d+"#),
            ("tiktok", #"vm\.tiktok\.com\/[a-zA-Z0-9]+"#),
        ]
        return patterns.compactMap { (platform, pattern) in
            guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else {
                return nil
            }
            return (platform, regex)
        }
    }()

    // MARK: - Types

    enum ImportState: Equatable {
        case idle
        case importing
        case success
        case error(String)

        var isLoading: Bool {
            if case .importing = self { return true }
            return false
        }

        /// Whether we're in an active import state (importing or success) that should be centered
        var isActiveImport: Bool {
            switch self {
            case .importing, .success:
                return true
            default:
                return false
            }
        }

        var errorMessage: String? {
            if case .error(let message) = self { return message }
            return nil
        }
    }

    enum ImportStep: Int, CaseIterable {
        case fetching = 0
        case fetchingTranscript = 1
        case uploading = 2
        case recognizing = 3
        case parsing = 4
        case extracting = 5
        case saving = 6

        var title: String {
            switch self {
            case .fetching: return String(localized: "Fetching recipe...")
            case .fetchingTranscript: return String(localized: "Fetching transcript...")
            case .uploading: return String(localized: "Uploading file...")
            case .recognizing: return String(localized: "Reading text...")
            case .parsing: return String(localized: "Analyzing with AI...")
            case .extracting: return String(localized: "Extracting ingredients...")
            case .saving: return String(localized: "Saving recipe...")
            }
        }

        var progress: Double {
            Double(rawValue + 1) / Double(ImportStep.allCases.count)
        }
    }

    // MARK: - Token Management

    /// Get the token cost for a URL import
    /// - Parameter urlString: The URL to check
    /// - Returns: The token cost based on URL type
    func getTokenCost(for urlString: String) -> ImportTokenCost {
        if isVideoURL(urlString) {
            return .video
        }
        return .website
    }

    /// Check if user can afford the import
    /// - Parameter urlString: The URL to import
    /// - Returns: true if user has enough tokens
    func canAffordImport(for urlString: String) -> Bool {
        let cost = getTokenCost(for: urlString)
        return TokenService.shared.canAffordImport(type: cost)
    }

    /// Check if user can afford media import (PDF/images)
    /// - Returns: true if user has enough tokens for media import
    func canAffordMediaImport() -> Bool {
        return TokenService.shared.canAffordImport(type: .media)
    }

    // MARK: - Import Recipe

    /// Import a recipe from a URL
    /// - Parameter urlString: The URL string to import from
    func importRecipe(from urlString: String) async {
        // Validate URL
        guard let url = URL(string: urlString),
              url.scheme == "http" || url.scheme == "https" else {
            importState = .error("Invalid URL format. Please enter a valid recipe URL.")
            return
        }

        let isVideo = isVideoURL(urlString)
        let tokenCost = isVideo ? ImportTokenCost.video : ImportTokenCost.website

        // Check token balance before importing
        guard TokenService.shared.canAffordImport(type: tokenCost) else {
            requiredTokens = tokenCost.rawValue
            showInsufficientTokensAlert = true
            return
        }

        importState = .importing
        currentStep = .fetching

        do {
            // Simulate step progression (actual work happens in Edge Function)
            // Step 1: Fetching
            try await Task.sleep(for: .milliseconds(500))

            // For video URLs, show transcript fetching step
            if isVideo {
                currentStep = .fetchingTranscript
                try await Task.sleep(for: .milliseconds(600))
            }

            currentStep = .parsing

            // Step 2: Parsing - Use language and translate settings
            let language = UserSettings.shared.recipeLanguage.rawValue
            let translate = UserSettings.shared.enableTranslation

            // Start the actual import (this takes most of the time)
            try await Task.sleep(for: .milliseconds(800))
            currentStep = .extracting

            // Prepare timestamps (empty string means use full video)
            let startTs = startTimestamp.isEmpty ? nil : startTimestamp
            let endTs = endTimestamp.isEmpty ? nil : endTimestamp

            let response = try await SupabaseService.shared.importRecipe(
                from: urlString,
                language: language,
                translate: translate,
                startTimestamp: startTs,
                endTimestamp: endTs
            )

            // Step 3 & 4: Extracting & Saving happen in the Edge Function
            currentStep = .saving
            try await Task.sleep(for: .milliseconds(300))

            if response.success {
                // Update token balance from server response
                if let newBalance = response.tokensRemaining {
                    TokenService.shared.updateBalance( newBalance)
                } else {
                    // Fallback: refresh balance from server
                    try? await TokenService.shared.refreshBalance()
                }

                if let recipeIdString = response.recipeId,
                   let recipeId = UUID(uuidString: recipeIdString) {
                    lastImportedRecipeId = recipeId
                }
                lastImportedRecipeName = response.recipeName
                lastImportStats = response.stats
                importState = .success
            } else {
                // Check if this was an insufficient tokens error from server
                if let required = response.tokensRequired,
                   let available = response.tokensAvailable {
                    requiredTokens = required
                    showInsufficientTokensAlert = true
                    // Update local balance to match server
                    TokenService.shared.updateBalance( available)
                }
                importState = .error(response.error ?? "Failed to import recipe")
            }

        } catch {
            importState = .error(error.localizedDescription)
        }
    }

    /// Reset the import state
    func reset() {
        importState = .idle
        lastImportedRecipeId = nil
        lastImportedRecipeName = nil
        lastImportStats = nil
        startTimestamp = ""
        endTimestamp = ""
    }

    // MARK: - Media Import (OCR)

    /// Maximum file sizes for upload
    private static let maxImageSizeMB = 10
    private static let maxPDFSizeMB = 20

    /// Import a recipe from image data (photo or camera capture)
    /// - Parameter imageData: JPEG image data
    func importRecipeFromImage(_ imageData: Data) async {
        await importRecipeFromImages([imageData])
    }

    /// Import a recipe from multiple images (combined into one recipe)
    /// - Parameter imagesData: Array of JPEG image data
    func importRecipeFromImages(_ imagesData: [Data]) async {
        // Check token balance before importing
        guard TokenService.shared.canAffordImport(type: .media) else {
            requiredTokens = ImportTokenCost.media.rawValue
            showInsufficientTokensAlert = true
            return
        }

        // Validate file sizes
        for (index, imageData) in imagesData.enumerated() {
            let sizeMB = imageData.count / (1024 * 1024)
            if sizeMB > Self.maxImageSizeMB {
                importState = .error("Image \(index + 1) too large. Maximum size is \(Self.maxImageSizeMB)MB.")
                return
            }
        }

        importState = .importing
        currentStep = .uploading

        do {
            // Step 1: Upload all images to temporary storage
            var storagePaths: [String] = []
            for imageData in imagesData {
                let storagePath = try await SupabaseService.shared.uploadTempImport(
                    data: imageData,
                    contentType: "image/jpeg",
                    fileExtension: "jpg"
                )
                storagePaths.append(storagePath)
            }

            currentStep = .recognizing
            try await Task.sleep(for: .milliseconds(300))

            // Step 2: Call OCR Edge Function with all paths
            let language = UserSettings.shared.recipeLanguage.rawValue
            let translate = UserSettings.shared.enableTranslation

            currentStep = .parsing
            try await Task.sleep(for: .milliseconds(300))

            currentStep = .extracting

            let response = try await SupabaseService.shared.importRecipeFromMedia(
                storagePaths: storagePaths,
                mediaType: .image,
                language: language,
                translate: translate
            )

            currentStep = .saving
            try await Task.sleep(for: .milliseconds(200))

            if response.success {
                // Update token balance from server response
                if let newBalance = response.tokensRemaining {
                    TokenService.shared.updateBalance( newBalance)
                } else {
                    try? await TokenService.shared.refreshBalance()
                }

                if let recipeIdString = response.recipeId,
                   let recipeId = UUID(uuidString: recipeIdString) {
                    lastImportedRecipeId = recipeId
                }
                lastImportedRecipeName = response.recipeName
                lastImportStats = response.stats
                importState = .success
            } else {
                if let required = response.tokensRequired,
                   let available = response.tokensAvailable {
                    requiredTokens = required
                    showInsufficientTokensAlert = true
                    TokenService.shared.updateBalance( available)
                }
                importState = .error(response.error ?? "Failed to import recipe from images")
            }

        } catch {
            importState = .error(error.localizedDescription)
        }
    }

    /// Import a recipe from PDF data
    /// - Parameter pdfData: PDF file data
    func importRecipeFromPDF(_ pdfData: Data) async {
        // Check token balance before importing
        guard TokenService.shared.canAffordImport(type: .media) else {
            requiredTokens = ImportTokenCost.media.rawValue
            showInsufficientTokensAlert = true
            return
        }

        // Validate file size
        let sizeMB = pdfData.count / (1024 * 1024)
        if sizeMB > Self.maxPDFSizeMB {
            importState = .error("PDF too large. Maximum size is \(Self.maxPDFSizeMB)MB.")
            return
        }

        importState = .importing
        currentStep = .uploading

        do {
            // Step 1: Upload to temporary storage
            let storagePath = try await SupabaseService.shared.uploadTempImport(
                data: pdfData,
                contentType: "application/pdf",
                fileExtension: "pdf"
            )

            currentStep = .recognizing
            try await Task.sleep(for: .milliseconds(300))

            // Step 2: Call OCR Edge Function
            let language = UserSettings.shared.recipeLanguage.rawValue
            let translate = UserSettings.shared.enableTranslation

            currentStep = .parsing
            try await Task.sleep(for: .milliseconds(300))

            currentStep = .extracting

            let response = try await SupabaseService.shared.importRecipeFromMedia(
                storagePaths: [storagePath],
                mediaType: .pdf,
                language: language,
                translate: translate
            )

            currentStep = .saving
            try await Task.sleep(for: .milliseconds(200))

            if response.success {
                // Update token balance from server response
                if let newBalance = response.tokensRemaining {
                    TokenService.shared.updateBalance( newBalance)
                } else {
                    try? await TokenService.shared.refreshBalance()
                }

                if let recipeIdString = response.recipeId,
                   let recipeId = UUID(uuidString: recipeIdString) {
                    lastImportedRecipeId = recipeId
                }
                lastImportedRecipeName = response.recipeName
                lastImportStats = response.stats
                importState = .success
            } else {
                if let required = response.tokensRequired,
                   let available = response.tokensAvailable {
                    requiredTokens = required
                    showInsufficientTokensAlert = true
                    TokenService.shared.updateBalance( available)
                }
                importState = .error(response.error ?? "Failed to import recipe from PDF")
            }

        } catch {
            importState = .error(error.localizedDescription)
        }
    }

    /// Check if a URL looks valid for import
    func isValidURL(_ urlString: String) -> Bool {
        guard let url = URL(string: urlString),
              url.scheme == "http" || url.scheme == "https",
              url.host != nil else {
            return false
        }
        return true
    }

    // MARK: - Video URL Detection

    /// Check if a URL is from a supported video platform
    /// - Parameter urlString: The URL to check
    /// - Returns: true if the URL is a YouTube, Instagram Reel, or TikTok video
    func isVideoURL(_ urlString: String) -> Bool {
        let range = NSRange(urlString.startIndex..., in: urlString)
        for (_, pattern) in Self.videoPatterns {
            if pattern.firstMatch(in: urlString, options: [], range: range) != nil {
                return true
            }
        }
        return false
    }

    /// Get the video platform name for display
    /// - Parameter urlString: The URL to check
    /// - Returns: The platform name (e.g., "YouTube", "Instagram", "TikTok") or nil if not a video
    func videoPlatformName(_ urlString: String) -> String? {
        let range = NSRange(urlString.startIndex..., in: urlString)
        for (platform, pattern) in Self.videoPatterns {
            if pattern.firstMatch(in: urlString, options: [], range: range) != nil {
                switch platform {
                case "youtube": return "YouTube"
                case "instagram": return "Instagram"
                case "tiktok": return "TikTok"
                default: return platform.capitalized
                }
            }
        }
        return nil
    }

    /// Validate timestamp format (MM:SS or HH:MM:SS)
    /// - Parameter timestamp: The timestamp string to validate
    /// - Returns: true if the timestamp is valid or empty
    func isValidTimestamp(_ timestamp: String) -> Bool {
        if timestamp.isEmpty { return true }

        let parts = timestamp.split(separator: ":")
        guard parts.count == 2 || parts.count == 3 else { return false }

        for part in parts {
            guard let _ = Int(part), part.count <= 2 else { return false }
        }

        return true
    }
}
