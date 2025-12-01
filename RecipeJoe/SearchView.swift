//
//  SearchView.swift
//  RecipeJoe
//
//  Created by Oliver Staub on 23.11.2025.
//

import SwiftUI
import SwiftData

struct SearchView: View {
    @Query private var allRecipes: [Recipe]
    @State private var searchText = ""

    private var filteredRecipes: [Recipe] {
        guard !searchText.isEmpty else { return [] }
        let lowercasedQuery = searchText.lowercased()
        return allRecipes.filter { recipe in
            recipe.name.lowercased().contains(lowercasedQuery) ||
            recipe.recipeCategory.lowercased().contains(lowercasedQuery) ||
            recipe.recipeCuisine.lowercased().contains(lowercasedQuery) ||
            recipe.keywords.contains { $0.lowercased().contains(lowercasedQuery) } ||
            recipe.ingredientsList.contains { $0.lowercased().contains(lowercasedQuery) }
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if searchText.isEmpty {
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
            HStack {
                VStack(alignment: .leading) {
                    Text(recipe.name)
                        .font(.headline)
                    Text("\(recipe.recipeCategory) - \(recipe.recipeCuisine)")
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

#Preview {
    SearchView()
        .modelContainer(DataController.previewContainer)
}
