//
//  MainTabView.swift
//  RecipeJoe
//
//  Created by Oliver Staub on 23.11.2025.
//

import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            Tab("Home", systemImage: "house.fill") {
                HomeView()
            }

            Tab("Add Recipe", systemImage: "plus.circle.fill") {
                AddRecipeView()
            }

            Tab("Search", systemImage: "magnifyingglass", role: .search) {
                SearchView()
            }
        }
        .tint(Color.terracotta) // Terracotta accent color
    }
}

#Preview {
    MainTabView()
}
