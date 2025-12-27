//
//  HomeView.swift
//  RecipeJoe
//
//  Created by Oliver Staub on 23.11.2025.
//

import SwiftUI

struct HomeView: View {
    @Binding var navigationPath: NavigationPath
    @StateObject private var viewModel = HomeViewModel()
    @State private var showingSettings = false
    @Environment(\.locale) private var locale

    init(navigationPath: Binding<NavigationPath> = .constant(NavigationPath())) {
        self._navigationPath = navigationPath
    }

    private var filterHeader: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterChip(title: "All", isSelected: viewModel.filters.timeFilter == .all) {
                    viewModel.filters.timeFilter = .all
                }
                FilterChip(title: "Quick", icon: "clock", isSelected: viewModel.filters.timeFilter == .quick) {
                    viewModel.filters.timeFilter = .quick
                }
                FilterChip(title: "Medium", icon: "clock", isSelected: viewModel.filters.timeFilter == .medium) {
                    viewModel.filters.timeFilter = .medium
                }
                FilterChip(title: "Long", icon: "clock", isSelected: viewModel.filters.timeFilter == .long) {
                    viewModel.filters.timeFilter = .long
                }
                FilterChip(title: "Favorites", icon: "heart.fill", isSelected: viewModel.filters.showFavoritesOnly) {
                    viewModel.filters.showFavoritesOnly.toggle()
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .listRowInsets(EdgeInsets())
        .background(Color(.systemBackground))
    }

    @ViewBuilder
    private var contentView: some View {
        if viewModel.isLoading && viewModel.recipes.isEmpty {
            loadingView
        } else if viewModel.recipes.isEmpty && !viewModel.filters.hasActiveFilters {
            emptyStateView
        } else if viewModel.filteredRecipes.isEmpty {
            noFilterResultsView
        } else {
            List {
                Section(header: filterHeader) {
                    ForEach(viewModel.filteredRecipes) { recipe in
                        NavigationLink(value: recipe.id) {
                            RecipeRowView(recipe: recipe)
                        }
                    }
                    .onDelete { indexSet in
                        let recipesToDelete = indexSet.map { viewModel.filteredRecipes[$0] }
                        Task {
                            for recipe in recipesToDelete {
                                _ = await viewModel.deleteRecipe(id: recipe.id)
                            }
                        }
                    }
                }
            }
            .listStyle(.plain)
            .accessibilityIdentifier("recipeList")
        }
    }

    var body: some View {
        NavigationStack(path: $navigationPath) {
            contentView
                .navigationTitle("RecipeJoe")
                .navigationDestination(for: UUID.self) { recipeId in
                    RecipeDetailView(recipeId: recipeId)
                }
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
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityIdentifier("emptyHomeView")
    }

    // MARK: - No Filter Results

    private var noFilterResultsView: some View {
        VStack(spacing: 20) {
            Image(systemName: "line.3.horizontal.decrease.circle")
                .font(.system(size: 60))
                .foregroundStyle(Color.terracotta)

            Text("No Matching Recipes".localized(for: locale))
                .font(.title2)
                .fontWeight(.bold)

            Text("Try adjusting your filters".localized(for: locale))
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button("Clear Filters".localized(for: locale)) {
                viewModel.filters.reset()
            }
            .buttonStyle(.borderedProminent)
            .tint(Color.terracotta)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    HomeView()
}
