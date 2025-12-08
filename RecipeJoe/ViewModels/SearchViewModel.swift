//
//  SearchViewModel.swift
//  RecipeJoe
//
//  ViewModel for the search view
//

import Combine
import Foundation

@MainActor
final class SearchViewModel: ObservableObject {
    @Published var recipes: [SupabaseRecipe] = []
    @Published var isLoading: Bool = false

    func fetchRecipes() async {
        isLoading = true
        do {
            recipes = try await SupabaseService.shared.fetchRecipes()
        } catch {
            // Silent fail - just show empty results
        }
        isLoading = false
    }
}
