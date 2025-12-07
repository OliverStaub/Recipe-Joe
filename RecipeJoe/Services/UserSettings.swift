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

/// Observable user settings
@MainActor
final class UserSettings: ObservableObject {
    // MARK: - Singleton

    static let shared = UserSettings()

    // MARK: - Keys

    private enum Keys {
        static let recipeLanguage = "recipeLanguage"
    }

    // MARK: - Published Properties

    @Published var recipeLanguage: RecipeLanguage {
        didSet {
            UserDefaults.standard.set(recipeLanguage.rawValue, forKey: Keys.recipeLanguage)
        }
    }

    // MARK: - Initialization

    private init() {
        // Load saved language or default to device locale
        if let savedLanguage = UserDefaults.standard.string(forKey: Keys.recipeLanguage),
           let language = RecipeLanguage(rawValue: savedLanguage) {
            self.recipeLanguage = language
        } else {
            // Default based on device locale
            let deviceLanguage = Locale.current.language.languageCode?.identifier ?? "en"
            self.recipeLanguage = deviceLanguage == "de" ? .german : .english
        }
    }
}
