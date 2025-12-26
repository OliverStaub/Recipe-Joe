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

    /// Token balance synced from main app
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
}
