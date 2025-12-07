//
//  HomeView.swift
//  RecipeJoe
//
//  Created by Oliver Staub on 23.11.2025.
//

import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @State private var showingSettings = false

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.recipes.isEmpty {
                    loadingView
                } else if viewModel.recipes.isEmpty {
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
            .task {
                await viewModel.fetchRecipes()
            }
            .refreshable {
                await viewModel.refresh()
            }
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
            Text("Loading recipes...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "fork.knife.circle")
                .font(.system(size: 60))
                .foregroundStyle(Color.terracotta)

            Text("No Recipes Yet")
                .font(.title2)
                .fontWeight(.bold)

            Text("Import your first recipe from the Add Recipe tab")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            if let error = viewModel.error {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .padding(.top, 8)

                Button("Retry") {
                    Task {
                        await viewModel.fetchRecipes()
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(Color.terracotta)
            }
        }
        .accessibilityIdentifier("emptyHomeView")
    }

    // MARK: - Recipe List

    private var recipeListView: some View {
        List {
            ForEach(viewModel.recipes) { recipe in
                NavigationLink(destination: RecipeDetailView(recipeId: recipe.id)) {
                    RecipeRowView(recipe: recipe)
                }
            }
            .onDelete { indexSet in
                Task {
                    await viewModel.deleteRecipes(at: indexSet)
                }
            }
        }
        .listStyle(.plain)
        .accessibilityIdentifier("recipeList")
    }
}

// MARK: - Recipe Row View

struct RecipeRowView: View {
    let recipe: SupabaseRecipe

    var body: some View {
        HStack(spacing: 12) {
            // Image thumbnail
            Group {
                if let imageUrl = recipe.imageUrl,
                   let url = URL(string: imageUrl) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                        case .failure, .empty:
                            placeholderContent
                        @unknown default:
                            placeholderContent
                        }
                    }
                } else {
                    placeholderContent
                }
            }
            .frame(width: 70, height: 70)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            // Recipe info
            VStack(alignment: .leading, spacing: 4) {
                Text(recipe.name)
                    .font(.headline)
                    .lineLimit(2)

                if let category = recipe.category, !category.isEmpty {
                    Text(category)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                HStack(spacing: 12) {
                    if let totalTime = recipe.totalTimeMinutes, totalTime > 0 {
                        Label(formatTime(totalTime), systemImage: "clock")
                    }
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

    private var placeholderContent: some View {
        Rectangle()
            .fill(Color.terracotta.opacity(0.15))
            .overlay {
                Image(systemName: "fork.knife")
                    .font(.title2)
                    .foregroundStyle(Color.terracotta)
            }
    }

    private func formatTime(_ minutes: Int) -> String {
        if minutes >= 60 {
            let hours = minutes / 60
            let mins = minutes % 60
            if mins == 0 {
                return "\(hours)h"
            }
            return "\(hours)h \(mins)m"
        }
        return "\(minutes) min"
    }
}

#Preview {
    HomeView()
}
