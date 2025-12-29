//
//  Constants.swift
//  RecipeJoe
//
//  Shared constants accessible by both main app and share extension.
//

import Foundation

enum AppConstants {
    /// App Group identifier for sharing data between main app and extensions
    static let appGroupIdentifier = "group.com.oliverstaub.recipejoe"

    /// URL scheme for deep linking
    static let urlScheme = "recipejoe"

    /// Supabase project URL
    static let supabaseURL = "https://iqamjnyuvvmvakjdobsm.supabase.co"

    /// Supabase publishable key (safe to include in client apps)
    static let supabaseAnonKey = "sb_publishable_bjC-0a3jReGsoS5pprLevA_dDXqwrxn"

    /// RevenueCat publishable API key (safe to include in client apps)
    static let revenueCatAPIKey = "appl_WCgwdlbyESXHZoEWBLZxlPxrbhj"

    /// Keys for shared UserDefaults
    enum Keys {
        static let accessToken = "supabase_access_token"
        static let refreshToken = "supabase_refresh_token"
        static let recipeLanguage = "recipeLanguage"
        static let enableTranslation = "enableTranslation"
        static let tokenBalance = "tokenBalance"
    }

    /// File size limits
    enum Limits {
        static let maxPDFSizeMB = 20
        static let maxImageSizeMB = 10
        static let maxImageCount = 10
    }
}
