//
//  SharedUserDefaults.swift
//  RecipeJoe
//
//  Wrapper for reading/writing to App Group UserDefaults.
//  Used by both main app and share extension.
//

import Foundation

final class SharedUserDefaults {
    static let shared = SharedUserDefaults()

    private let defaults: UserDefaults?

    private init() {
        defaults = UserDefaults(suiteName: AppConstants.appGroupIdentifier)
    }

    // MARK: - Authentication Tokens

    var accessToken: String? {
        get { defaults?.string(forKey: AppConstants.Keys.accessToken) }
        set { defaults?.set(newValue, forKey: AppConstants.Keys.accessToken) }
    }

    var refreshToken: String? {
        get { defaults?.string(forKey: AppConstants.Keys.refreshToken) }
        set { defaults?.set(newValue, forKey: AppConstants.Keys.refreshToken) }
    }

    /// Check if user is authenticated (has valid tokens)
    var isAuthenticated: Bool {
        accessToken != nil && refreshToken != nil
    }

    /// Clear all authentication tokens
    func clearTokens() {
        accessToken = nil
        refreshToken = nil
    }

    // MARK: - Token Balance

    /// Token balance synced from main app for share extension access
    var tokenBalance: Int {
        get { defaults?.integer(forKey: AppConstants.Keys.tokenBalance) ?? 0 }
        set { defaults?.set(newValue, forKey: AppConstants.Keys.tokenBalance) }
    }

    // MARK: - Import Settings

    var recipeLanguage: String {
        get { defaults?.string(forKey: AppConstants.Keys.recipeLanguage) ?? "en" }
        set { defaults?.set(newValue, forKey: AppConstants.Keys.recipeLanguage) }
    }

    var enableTranslation: Bool {
        get { defaults?.bool(forKey: AppConstants.Keys.enableTranslation) ?? true }
        set { defaults?.set(newValue, forKey: AppConstants.Keys.enableTranslation) }
    }

    // MARK: - Pending Import

    /// Type of pending import: "pdf" or "image"
    var pendingImportType: String? {
        get { defaults?.string(forKey: AppConstants.Keys.pendingImportType) }
        set { defaults?.set(newValue, forKey: AppConstants.Keys.pendingImportType) }
    }

    /// Check if there's a pending import
    var hasPendingImport: Bool {
        pendingImportType != nil
    }

    /// Clear pending import flag
    func clearPendingImport() {
        pendingImportType = nil
    }

    // MARK: - Shared Container File Operations

    /// Get the shared container URL
    var sharedContainerURL: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: AppConstants.appGroupIdentifier)
    }

    /// Get the pending import directory URL
    var pendingImportDirectoryURL: URL? {
        sharedContainerURL?.appendingPathComponent(AppConstants.pendingImportDirectory, isDirectory: true)
    }

    /// Save files for pending import
    /// - Parameters:
    ///   - files: Array of (data, filename) tuples
    ///   - mediaType: "pdf" or "image"
    /// - Returns: true if successful
    func savePendingImportFiles(_ files: [(data: Data, filename: String)], mediaType: String) -> Bool {
        guard let directoryURL = pendingImportDirectoryURL else { return false }

        // Clear any existing pending files
        clearPendingImportFiles()

        // Create directory
        do {
            try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        } catch {
            return false
        }

        // Save each file
        for (data, filename) in files {
            let fileURL = directoryURL.appendingPathComponent(filename)
            do {
                try data.write(to: fileURL)
            } catch {
                return false
            }
        }

        // Set the pending import type
        pendingImportType = mediaType
        return true
    }

    /// Get pending import files
    /// - Returns: Array of file data, or empty if no pending import
    func getPendingImportFiles() -> [Data] {
        guard let directoryURL = pendingImportDirectoryURL else { return [] }

        do {
            let fileURLs = try FileManager.default.contentsOfDirectory(
                at: directoryURL,
                includingPropertiesForKeys: nil
            )
            return fileURLs.compactMap { try? Data(contentsOf: $0) }
        } catch {
            return []
        }
    }

    /// Clear pending import files from shared container
    func clearPendingImportFiles() {
        guard let directoryURL = pendingImportDirectoryURL else { return }

        try? FileManager.default.removeItem(at: directoryURL)
        clearPendingImport()
    }
}
