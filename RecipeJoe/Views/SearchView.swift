//
//  SearchView.swift
//  RecipeJoe
//
//  Created by Oliver Staub on 23.11.2025.
//

import Combine
import SwiftUI

struct SearchView: View {
    @StateObject private var viewModel = SearchViewModel()
    @State private var searchText = ""

    private var filteredRecipes: [SupabaseRecipe] {
        guard !searchText.isEmpty else { return [] }
        let lowercasedQuery = searchText.lowercased()
        return viewModel.recipes.filter { recipe in
            recipe.name.lowercased().contains(lowercasedQuery) ||
            (recipe.category?.lowercased().contains(lowercasedQuery) ?? false) ||
            (recipe.cuisine?.lowercased().contains(lowercasedQuery) ?? false) ||
            (recipe.keywords?.contains { $0.lowercased().contains(lowercasedQuery) } ?? false)
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    ProgressView("Loading recipes...")
                } else if searchText.isEmpty {
                    emptySearchView
                } else if filteredRecipes.isEmpty {
                    noResultsView
                } else {
                    searchResultsView
                }
            }
            .navigationTitle("Search")
            .searchable(text: $searchText, prompt: "Search recipes...")
        }
        .task {
            await viewModel.fetchRecipes()
        }
    }

    // MARK: - Empty Search View

    private var emptySearchView: some View {
        VStack(spacing: 20) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 60))
                .foregroundStyle(Color.terracotta)

            Text("Search Recipes")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("Search by name, category, cuisine, or ingredients")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - No Results View

    private var noResultsView: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 40))
                .foregroundStyle(.secondary)

            Text("No recipes found")
                .font(.headline)

            Text("Try a different search term")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Search Results View

    private var searchResultsView: some View {
        List(filteredRecipes) { recipe in
            NavigationLink(destination: RecipeDetailView(recipeId: recipe.id)) {
                HStack {
                    VStack(alignment: .leading) {
                        Text(recipe.name)
                            .font(.headline)
                        Text("\(recipe.category ?? "") - \(recipe.cuisine ?? "")")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    if recipe.isFavorite {
                        Image(systemName: "heart.fill")
                            .foregroundStyle(.red)
                    }
                }
            }
        }
    }
}

#Preview {
    SearchView()
}