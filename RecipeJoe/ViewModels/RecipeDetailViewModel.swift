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
}
