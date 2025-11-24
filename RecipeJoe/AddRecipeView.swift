//
//  AddRecipeView.swift
//  RecipeJoe
//
//  Created by Oliver Staub on 23.11.2025.
//

import SwiftUI

struct AddRecipeView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(Color.terracotta)

                Text("Add Recipe")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("Recipe creation form coming soon")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
            .navigationTitle("New Recipe")
        }
    }
}

#Preview {
    AddRecipeView()
}
