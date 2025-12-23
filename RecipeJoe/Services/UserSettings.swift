//
//  UserSettings.swift
//  RecipeJoe
//
//  User settings stored in UserDefaults
//

import Combine
import Foundation
import SwiftUI

/// Supported languages for recipe import
enum RecipeLanguage: String, CaseIterable, Identifiable {
    case english = "en"
    case german = "de"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .english: return "English"
        case .german: return "Deutsch"
        }
    }

    var flag: String {
        switch self {
        case .english: return "🇬🇧"
        case .german: return "🇩🇪"
        }
    }
}

/// Supported languages for app UI
enum AppLanguage: String, CaseIterable, Identifiable {
    case system = "system"
    case english = "en"
    case german = "de"
    case swissGerman = "gsw"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .system: return String(localized: "System Default")
        case .english: return "English"
        case .german: return "Deutsch"
        case .swissGerman: return "Schwiizerdütsch"
        }
    }

    var flag: String {
        switch self {
        case .system: return "📱"
        case .english: return "🇬🇧"
        case .german: return "🇩🇪"
        case .swissGerman: return "🇨🇭"
        }
    }

    /// Returns the locale identifier, resolving system to the actual device locale
    var localeIdentifier: String {
        switch self {
        case .system:
            return Locale.current.language.languageCode?.identifier ?? "en"
        case .english:
            return "en"
        case .german:
            return "de"
        case .swissGerman:
            return "gsw"
        }
    }
}

/// Observable user settings
@MainActor
final class UserSettings: ObservableObject {
    // MARK: - Singleton

    static let shared = UserSettings()

    // MARK: - Keys

    private enum Keys {
        static let recipeLanguage = "recipeLanguage"
        static let keepOriginalWording = "keepOriginalWording"
        static let appLanguage = "appLanguage"
    }

    // MARK: - Published Properties

    /// Language for app UI
    @Published var appLanguage: AppLanguage {
        didSet {
            UserDefaults.standard.set(appLanguage.rawValue, forKey: Keys.appLanguage)
        }
    }

    /// Language for recipe import (translation target)
    @Published var recipeLanguage: RecipeLanguage {
        didSet {
            UserDefaults.standard.set(recipeLanguage.rawValue, forKey: Keys.recipeLanguage)
            // Sync to shared storage for share extension
            SharedUserDefaults.shared.recipeLanguage = recipeLanguage.rawValue
        }
    }

    /// If true, keep original step text without rewording/translating
    @Published var keepOriginalWording: Bool {
        didSet {
            UserDefaults.standard.set(keepOriginalWording, forKey: Keys.keepOriginalWording)
            // Sync to shared storage for share extension
            SharedUserDefaults.shared.keepOriginalWording = keepOriginalWording
        }
    }

    // MARK: - Initialization

    private init() {
        // Load saved app language or default to system
        if let savedAppLanguage = UserDefaults.standard.string(forKey: Keys.appLanguage),
           let language = AppLanguage(rawValue: savedAppLanguage) {
            self.appLanguage = language
        } else {
            self.appLanguage = .system
        }

        // Load saved recipe language or default to device locale
        if let savedLanguage = UserDefaults.standard.string(forKey: Keys.recipeLanguage),
           let language = RecipeLanguage(rawValue: savedLanguage) {
            self.recipeLanguage = language
        } else {
            // Default based on device locale
            let deviceLanguage = Locale.current.language.languageCode?.identifier ?? "en"
            self.recipeLanguage = deviceLanguage == "de" ? .german : .english
        }

        // Load keepOriginalWording (default: false = reword enabled)
        self.keepOriginalWording = UserDefaults.standard.bool(forKey: Keys.keepOriginalWording)

        // Sync to shared storage for share extension
        SharedUserDefaults.shared.recipeLanguage = self.recipeLanguage.rawValue
        SharedUserDefaults.shared.keepOriginalWording = self.keepOriginalWording
    }

    // MARK: - Computed Properties

    /// The locale to use for app UI based on user's language selection
    var appLocale: Locale {
        Locale(identifier: appLanguage.localeIdentifier)
    }
}
