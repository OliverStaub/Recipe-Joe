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
    @Published var filters = RecipeFilters()
    @Published private(set) var hasLoadedOnce: Bool = false

    // MARK: - Computed Properties

    var filteredRecipes: [SupabaseRecipe] {
        recipes.filter { recipe in
            // Time filter
            guard filters.timeFilter.matches(totalMinutes: recipe.totalTimeMinutes) else {
                return false
            }

            // Category filter
            if let selectedCategory = filters.selectedCategory {
                guard recipe.category?.lowercased() == selectedCategory.lowercased() else {
                    return false
                }
            }

            // Cuisine filter
            if let selectedCuisine = filters.selectedCuisine {
                guard recipe.cuisine?.lowercased() == selectedCuisine.lowercased() else {
                    return false
                }
            }

            // Favorites filter
            if filters.showFavoritesOnly {
                guard recipe.isFavorite else {
                    return false
                }
            }

            return true
        }
    }

    var availableCategories: [String] {
        let categories = recipes.compactMap { $0.category }.filter { !$0.isEmpty }
        return Array(Set(categories)).sorted()
    }

    var availableCuisines: [String] {
        let cuisines = recipes.compactMap { $0.cuisine }.filter { !$0.isEmpty }
        return Array(Set(cuisines)).sorted()
    }

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
        hasLoadedOnce = true
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
