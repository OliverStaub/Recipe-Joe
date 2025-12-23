//
//  RecipeDetailViewModel.swift
//  RecipeJoe
//
//  ViewModel for the recipe detail view
//

import Combine
import Foundation

@MainActor
final class RecipeDetailViewModel: ObservableObject {
    @Published var recipeDetail: SupabaseRecipeDetail?
    @Published var isLoading: Bool = false
    @Published var error: String?
    @Published var isSaving: Bool = false
    @Published var saveError: String?

    private var hasLoadedOnce = false

    func fetchRecipeDetail(id: UUID) async {
        error = nil

        // 1. Load cached data immediately for fast display
        if !hasLoadedOnce {
            if let cached = await RecipeCacheService.shared.loadCachedRecipeDetail(id: id) {
                recipeDetail = cached
                isLoading = false
            } else {
                isLoading = true
            }
        }

        // 2. Fetch fresh data from network
        do {
            let fresh = try await SupabaseService.shared.fetchRecipeDetail(id: id)
            recipeDetail = fresh
            // 3. Cache the fresh data for next time
            try? await RecipeCacheService.shared.cacheRecipeDetail(fresh)
        } catch {
            // Only show error if we have no cached data
            if recipeDetail == nil {
                self.error = error.localizedDescription
            }
            // Otherwise silently use cached data
        }

        isLoading = false
        hasLoadedOnce = true
    }

    // MARK: - Save Methods

    /// Save recipe name
    func saveName(_ name: String) async {
        guard let recipeId = recipeDetail?.recipe.id else { return }
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        await performSave {
            try await SupabaseService.shared.updateRecipeName(id: recipeId, name: name)
        }
    }

    /// Save recipe description
    func saveDescription(_ description: String) async {
        guard let recipeId = recipeDetail?.recipe.id else { return }
        let value = description.isEmpty ? nil : description

        await performSave {
            try await SupabaseService.shared.updateRecipeDescription(id: recipeId, description: value)
        }
    }

    /// Save recipe prep time
    func savePrepTime(_ minutes: Int) async {
        guard let recipeId = recipeDetail?.recipe.id else { return }
        let value = minutes > 0 ? minutes : nil

        await performSave {
            try await SupabaseService.shared.updateRecipePrepTime(id: recipeId, prepTimeMinutes: value)
        }
    }

    /// Save recipe cook time
    func saveCookTime(_ minutes: Int) async {
        guard let recipeId = recipeDetail?.recipe.id else { return }
        let value = minutes > 0 ? minutes : nil

        await performSave {
            try await SupabaseService.shared.updateRecipeCookTime(id: recipeId, cookTimeMinutes: value)
        }
    }

    /// Save recipe total time
    func saveTotalTime(_ minutes: Int) async {
        guard let recipeId = recipeDetail?.recipe.id else { return }
        let value = minutes > 0 ? minutes : nil

        await performSave {
            try await SupabaseService.shared.updateRecipeTotalTime(id: recipeId, totalTimeMinutes: value)
        }
    }

    /// Save recipe yield/servings
    func saveYield(_ recipeYield: String) async {
        guard let recipeId = recipeDetail?.recipe.id else { return }
        let value = recipeYield.isEmpty ? nil : recipeYield

        await performSave {
            try await SupabaseService.shared.updateRecipeYield(id: recipeId, recipeYield: value)
        }
    }

    /// Save recipe category
    func saveCategory(_ category: String) async {
        guard let recipeId = recipeDetail?.recipe.id else { return }
        let value = category.isEmpty ? nil : category

        await performSave {
            try await SupabaseService.shared.updateRecipeCategory(id: recipeId, category: value)
        }
    }

    /// Save recipe cuisine
    func saveCuisine(_ cuisine: String) async {
        guard let recipeId = recipeDetail?.recipe.id else { return }
        let value = cuisine.isEmpty ? nil : cuisine

        await performSave {
            try await SupabaseService.shared.updateRecipeCuisine(id: recipeId, cuisine: value)
        }
    }

    /// Save step instruction
    func saveStepInstruction(stepId: UUID, instruction: String) async {
        guard recipeDetail?.recipe.id != nil else { return }
        guard !instruction.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        await performSave {
            try await SupabaseService.shared.updateRecipeStep(id: stepId, instruction: instruction)
        }
    }

    /// Save ingredient quantity and notes
    func saveIngredient(ingredientId: UUID, quantity: Double?, notes: String?) async {
        guard recipeDetail?.recipe.id != nil else { return }

        await performSave {
            try await SupabaseService.shared.updateRecipeIngredient(
                id: ingredientId,
                quantity: quantity,
                notes: notes
            )
        }
    }

    // MARK: - Private Helpers

    private func performSave(_ operation: () async throws -> Void) async {
        guard let recipeId = recipeDetail?.recipe.id else { return }

        isSaving = true
        saveError = nil

        do {
            try await operation()
            // Refresh to get updated data
            await fetchRecipeDetail(id: recipeId)
        } catch {
            saveError = error.localizedDescription
        }

        isSaving = false
    }
}
