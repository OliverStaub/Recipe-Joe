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

    func fetchRecipeDetail(id: UUID) async {
        isLoading = true
        error = nil

        do {
            recipeDetail = try await SupabaseService.shared.fetchRecipeDetail(id: id)
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }
}
