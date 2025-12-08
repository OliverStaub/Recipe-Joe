//
//  IngredientRow.swift
//  RecipeJoe
//
//  Reusable ingredient row component
//

import SwiftUI

struct IngredientRow: View {
    let ingredient: SupabaseRecipeIngredient

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Quantity
            Text(ingredient.formattedQuantity)
                .font(.subheadline)
                .fontWeight(.medium)
                .frame(width: 60, alignment: .leading)

            // Ingredient name
            VStack(alignment: .leading, spacing: 2) {
                Text(ingredient.ingredient?.localizedName ?? "Unknown")
                    .font(.subheadline)

                if let notes = ingredient.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()
        }
    }
}
