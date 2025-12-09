//
//  IngredientRow.swift
//  RecipeJoe
//
//  Reusable ingredient row component
//

import SwiftUI

struct IngredientRow: View {
    let ingredient: SupabaseRecipeIngredient
    @Environment(\.locale) private var locale

    /// Check if current locale is German-based
    private var isGerman: Bool {
        let langCode = locale.language.languageCode?.identifier ?? "en"
        return langCode == "de" || langCode == "gsw"
    }

    /// Returns localized ingredient name based on app's locale setting
    private var ingredientName: String {
        guard let ing = ingredient.ingredient else {
            return "Unknown".localized(for: locale)
        }
        return isGerman ? ing.nameDe : ing.nameEn
    }

    /// Returns formatted quantity with localized measurement unit
    private var formattedQuantity: String {
        var parts: [String] = []

        if let qty = ingredient.quantity {
            if qty == qty.rounded() {
                parts.append(String(format: "%.0f", qty))
            } else {
                parts.append(String(format: "%.1f", qty))
            }
        }

        if let measurement = ingredient.measurementType {
            parts.append(isGerman ? measurement.abbreviationDe : measurement.abbreviationEn)
        }

        return parts.isEmpty ? "to taste".localized(for: locale) : parts.joined(separator: " ")
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Quantity
            Text(formattedQuantity)
                .font(.subheadline)
                .fontWeight(.medium)
                .frame(width: 60, alignment: .leading)

            // Ingredient name
            VStack(alignment: .leading, spacing: 2) {
                Text(ingredientName)
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
