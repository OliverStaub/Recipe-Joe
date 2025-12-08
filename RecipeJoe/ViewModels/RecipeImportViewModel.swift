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

        var errorMessage: String? {
            if case .error(let message) = self { return message }
            return nil
        }
    }

    enum ImportStep: Int, CaseIterable {
        case fetching = 0
        case parsing = 1
        case extracting = 2
        case saving = 3

        var title: String {
            switch self {
            case .fetching: return String(localized: "Fetching recipe...")
            case .parsing: return String(localized: "Analyzing with AI...")
            case .extracting: return String(localized: "Extracting ingredients...")
            case .saving: return String(localized: "Saving recipe...")
            }
        }

        var progress: Double {
            Double(rawValue + 1) / Double(ImportStep.allCases.count)
        }
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

        importState = .importing
        currentStep = .fetching

        do {
            // Simulate step progression (actual work happens in Edge Function)
            // Step 1: Fetching
            try await Task.sleep(for: .milliseconds(500))
            currentStep = .parsing

            // Step 2: Parsing - Use language and reword settings
            let language = UserSettings.shared.recipeLanguage.rawValue
            let reword = !UserSettings.shared.keepOriginalWording

            // Start the actual import (this takes most of the time)
            try await Task.sleep(for: .milliseconds(800))
            currentStep = .extracting

            let response = try await SupabaseService.shared.importRecipe(
                from: urlString,
                language: language,
                reword: reword
            )

            // Step 3 & 4: Extracting & Saving happen in the Edge Function
            currentStep = .saving
            try await Task.sleep(for: .milliseconds(300))

            if response.success {
                if let recipeIdString = response.recipeId,
                   let recipeId = UUID(uuidString: recipeIdString) {
                    lastImportedRecipeId = recipeId
                }
                lastImportedRecipeName = response.recipeName
                lastImportStats = response.stats
                importState = .success
            } else {
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
}
