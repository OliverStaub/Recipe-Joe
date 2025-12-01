//
//  HomeView.swift
//  RecipeJoe
//
//  Created by Oliver Staub on 23.11.2025.
//

import SwiftUI
import SwiftData

struct HomeView: View {
    @Query(sort: \Recipe.dateModified, order: .reverse) private var recipes: [Recipe]
    @State private var showingSettings = false

    var body: some View {
        NavigationStack {
            Group {
                if recipes.isEmpty {
                    emptyStateView
                } else {
                    recipeListView
                }
            }
            .navigationTitle("RecipeJoe")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                    .accessibilityIdentifier("settingsButton")
                }
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "house.fill")
                .font(.system(size: 60))
                .foregroundStyle(Color.terracotta)

            Text("Home")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("No recipes yet. Add your first recipe!")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .accessibilityIdentifier("emptyHomeView")
    }

    // MARK: - Recipe List

    private var recipeListView: some View {
        List(recipes) { recipe in
            RecipeRow(recipe: recipe)
        }
        .accessibilityIdentifier("recipeList")
    }
}

// MARK: - Recipe Row

private struct RecipeRow: View {
    let recipe: Recipe

    var body: some View {
        HStack(spacing: 12) {
            // Placeholder for recipe image
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.terracotta.opacity(0.2))
                .frame(width: 60, height: 60)
                .overlay {
                    if let imageData = recipe.imageData,
                       let uiImage = UIImage(data: imageData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    } else {
                        Image(systemName: "fork.knife")
                            .foregroundStyle(Color.terracotta)
                    }
                }

            VStack(alignment: .leading, spacing: 4) {
                Text(recipe.name)
                    .font(.headline)

                Text(recipe.recipeCategory)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                HStack(spacing: 8) {
                    Label(recipe.formattedTotalTime, systemImage: "clock")
                    if recipe.isFavorite {
                        Image(systemName: "heart.fill")
                            .foregroundStyle(.red)
                    }
                }
                .font(.caption2)
                .foregroundStyle(.tertiary)
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    HomeView()
        .modelContainer(DataController.previewContainer)
}
