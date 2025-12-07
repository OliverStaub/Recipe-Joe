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

        do {
            // Determine language based on device locale
            let language = Locale.current.language.languageCode?.identifier == "de" ? "de" : "en"

            let response = try await SupabaseService.shared.importRecipe(
                from: urlString,
                language: language
            )

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
