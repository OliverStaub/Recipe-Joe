//
//  HomeViewModel.swift
//  RecipeJoe
//
//  ViewModel for fetching and managing recipes from Supabase
//

import Combine
import Foundation
import SwiftUI

@MainActor
final class HomeViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var recipes: [SupabaseRecipe] = []
    @Published var isLoading: Bool = false
    @Published var error: String?

    // MARK: - Fetch Recipes

    func fetchRecipes() async {
        isLoading = true
        error = nil

        do {
            recipes = try await SupabaseService.shared.fetchRecipes()
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }

    // MARK: - Refresh

    func refresh() async {
        await fetchRecipes()
    }

    // MARK: - Delete Recipes

    func deleteRecipes(at indexSet: IndexSet) async {
        for index in indexSet {
            let recipe = recipes[index]
            do {
                try await SupabaseService.shared.deleteRecipe(id: recipe.id)
                recipes.remove(at: index)
            } catch {
                self.error = "Failed to delete recipe: \(error.localizedDescription)"
            }
        }
    }

    func deleteRecipe(id: UUID) async -> Bool {
        do {
            try await SupabaseService.shared.deleteRecipe(id: id)
            recipes.removeAll { $0.id == id }
            return true
        } catch {
            self.error = "Failed to delete recipe: \(error.localizedDescription)"
            return false
        }
    }
}
