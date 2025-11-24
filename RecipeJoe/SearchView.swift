//
//  SearchView.swift
//  RecipeJoe
//
//  Created by Oliver Staub on 23.11.2025.
//

import SwiftUI

struct SearchView: View {
    @State private var searchText = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 60))
                    .foregroundStyle(Color.terracotta)

                Text("Search Recipes")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("Recipe search coming soon")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
            .navigationTitle("Search")
            .searchable(text: $searchText, prompt: "Search recipes...")
        }
    }
}

#Preview {
    SearchView()
}
