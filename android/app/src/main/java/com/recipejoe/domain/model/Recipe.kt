package com.recipejoe.domain.model

import java.time.Instant
import java.util.UUID

/**
 * Domain model for a recipe
 */
data class Recipe(
    val id: UUID,
    val userId: UUID?,
    val name: String,
    val author: String?,
    val description: String?,
    val prepTimeMinutes: Int?,
    val cookTimeMinutes: Int?,
    val totalTimeMinutes: Int?,
    val recipeYield: String?,
    val category: String?,
    val cuisine: String?,
    val rating: Int,
    val isFavorite: Boolean,
    val imageUrl: String?,
    val sourceUrl: String?,
    val keywords: List<String>?,
    val language: String?,
    val createdAt: Instant,
    val updatedAt: Instant
)

/**
 * Domain model for a recipe step
 */
data class RecipeStep(
    val id: UUID,
    val recipeId: UUID,
    val stepNumber: Int,
    val instruction: String,
    val durationMinutes: Int?
)

/**
 * Domain model for an ingredient
 */
data class Ingredient(
    val id: UUID,
    val nameEn: String,
    val nameDe: String,
    val defaultMeasurementTypeId: UUID?
) {
    fun localizedName(languageCode: String): String {
        return if (languageCode == "de") nameDe else nameEn
    }
}

/**
 * Domain model for a measurement type
 */
data class MeasurementType(
    val id: UUID,
    val nameEn: String,
    val nameDe: String,
    val abbreviationEn: String,
    val abbreviationDe: String
) {
    fun localizedName(languageCode: String): String {
        return if (languageCode == "de") nameDe else nameEn
    }

    fun localizedAbbreviation(languageCode: String): String {
        return if (languageCode == "de") abbreviationDe else abbreviationEn
    }
}

/**
 * Domain model for a recipe ingredient (junction with quantity)
 */
data class RecipeIngredient(
    val id: UUID,
    val recipeId: UUID,
    val ingredientId: UUID,
    val measurementTypeId: UUID?,
    val quantity: Double?,
    val notes: String?,
    val displayOrder: Int,
    val ingredient: Ingredient?,
    val measurementType: MeasurementType?
) {
    fun formattedQuantity(languageCode: String): String {
        val parts = mutableListOf<String>()

        quantity?.let { qty ->
            parts.add(
                if (qty == qty.toLong().toDouble()) {
                    qty.toLong().toString()
                } else {
                    String.format("%.1f", qty)
                }
            )
        }

        measurementType?.let { measurement ->
            parts.add(measurement.localizedAbbreviation(languageCode))
        }

        return parts.joinToString(" ")
    }
}

/**
 * Complete recipe with all related data
 */
data class RecipeDetail(
    val recipe: Recipe,
    val steps: List<RecipeStep>,
    val ingredients: List<RecipeIngredient>
) {
    val sortedSteps: List<RecipeStep>
        get() = steps.sortedBy { it.stepNumber }

    val sortedIngredients: List<RecipeIngredient>
        get() = ingredients.sortedBy { it.displayOrder }
}
