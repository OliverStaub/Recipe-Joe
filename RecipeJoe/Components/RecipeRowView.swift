//
//  RecipeRowView.swift
//  RecipeJoe
//
//  Recipe list row component
//

import Kingfisher
import SwiftUI

struct RecipeRowView: View {
    let recipe: SupabaseRecipe

    var body: some View {
        HStack(spacing: 12) {
            // Image thumbnail with Kingfisher caching
            Group {
                if let imageUrl = recipe.imageUrl,
                   let url = URL(string: imageUrl) {
                    KFImage(url)
                        .placeholder { RecipeImagePlaceholder() }
                        .loadDiskFileSynchronously()
                        .cacheMemoryOnly(false)
                        .fade(duration: 0.25)
                        .resizable()
                        .scaledToFill()
                } else {
                    RecipeImagePlaceholder()
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
}
