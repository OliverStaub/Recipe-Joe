//
//  MainTabView.swift
//  RecipeJoe
//
//  Created by Oliver Staub on 23.11.2025.
//

import SwiftUI

struct MainTabView: View {
    @Binding var deepLinkRecipeId: UUID?
    @State private var selectedTab = 0
    @State private var homeNavigationPath = NavigationPath()

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Home", systemImage: "house.fill", value: 0) {
                HomeView(navigationPath: $homeNavigationPath)
            }

            Tab("Add Recipe", systemImage: "plus.circle.fill", value: 1) {
                AddRecipeView()
            }

            Tab("Search", systemImage: "magnifyingglass", value: 2, role: .search) {
                SearchView()
            }
        }
        .tint(Color.terracotta)
        .onChange(of: deepLinkRecipeId) { _, newValue in
            if let recipeId = newValue {
                // Switch to home tab and navigate to the recipe
                selectedTab = 0
                homeNavigationPath.append(recipeId)
                deepLinkRecipeId = nil
            }
        }
    }
}

#Preview {
    MainTabView(deepLinkRecipeId: .constant(nil))
}
