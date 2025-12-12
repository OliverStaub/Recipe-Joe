//
//  LocalizationService.swift
//  RecipeJoe
//
//  Service to handle in-app language switching with String Catalogs
//
//  Note: String(localized:locale:) does NOT select translations - the locale parameter
//  only affects formatting of interpolated values. This service provides true
//  in-app language switching by loading the correct .lproj bundle.
//

import Foundation
import SwiftUI

// MARK: - String Extension for Locale-Based Localization

extension String {
    /// Returns a localized version of this string based on the provided locale.
    ///
    /// Use this instead of `String(localized:locale:)` which only affects formatting,
    /// not translation selection.
    ///
    /// - Parameter locale: The locale to use for translation lookup
    /// - Returns: The localized string, or the original key if no translation found
    func localized(for locale: Locale) -> String {
        let languageCode = locale.language.languageCode?.identifier ?? "en"

        // Determine which bundles to try (with fallbacks)
        let bundleCodes: [String]
        switch languageCode {
        case "gsw":
            // Swiss German -> German -> English fallback
            bundleCodes = ["gsw", "de", "en"]
        case "de":
            bundleCodes = ["de", "en"]
        default:
            bundleCodes = [languageCode, "en"]
        }

        // Try each bundle in order
        for code in bundleCodes {
            if let path = Bundle.main.path(forResource: code, ofType: "lproj"),
               let bundle = Bundle(path: path) {
                let result = bundle.localizedString(forKey: self, value: "🔑NOT_FOUND🔑", table: nil)
                // Only return if we actually found a translation
                if result != "🔑NOT_FOUND🔑" && result != self {
                    return result
                }
            }
        }

        // Final fallback: try main bundle with NSLocalizedString
        let fallback = NSLocalizedString(self, comment: "")
        return fallback
    }
}

// MARK: - Localized Text Helper

/// A helper to create Text views with proper locale-based localization
struct LocalizedText: View {
    let key: String
    @Environment(\.locale) private var locale

    init(_ key: String) {
        self.key = key
    }

    var body: some View {
        Text(key.localized(for: locale))
    }
}
