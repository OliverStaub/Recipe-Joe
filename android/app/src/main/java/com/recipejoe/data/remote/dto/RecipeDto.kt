package com.recipejoe.data.remote.dto

import com.recipejoe.domain.model.Ingredient
import com.recipejoe.domain.model.MeasurementType
import com.recipejoe.domain.model.Recipe
import com.recipejoe.domain.model.RecipeIngredient
import com.recipejoe.domain.model.RecipeStep
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import java.time.Instant
import java.util.UUID

/**
 * DTO for recipe from Supabase
 */
@Serializable
data class RecipeDto(
    val id: String,
    @SerialName("user_id") val userId: String? = null,
    val name: String,
    val author: String? = null,
    val description: String? = null,
    @SerialName("prep_time_minutes") val prepTimeMinutes: Int? = null,
    @SerialName("cook_time_minutes") val cookTimeMinutes: Int? = null,
    @SerialName("total_time_minutes") val totalTimeMinutes: Int? = null,
    @SerialName("recipe_yield") val recipeYield: String? = null,
    val category: String? = null,
    val cuisine: String? = null,
    val rating: Int = 0,
    @SerialName("is_favorite") val isFavorite: Boolean = false,
    @SerialName("image_url") val imageUrl: String? = null,
    @SerialName("source_url") val sourceUrl: String? = null,
    val keywords: List<String>? = null,
    val language: String? = null,
    @SerialName("created_at") val createdAt: String,
    @SerialName("updated_at") val updatedAt: String
) {
    fun toDomain(): Recipe = Recipe(
        id = UUID.fromString(id),
        userId = userId?.let { UUID.fromString(it) },
        name = name,
        author = author,
        description = description,
        prepTimeMinutes = prepTimeMinutes,
        cookTimeMinutes = cookTimeMinutes,
        totalTimeMinutes = totalTimeMinutes,
        recipeYield = recipeYield,
        category = category,
        cuisine = cuisine,
        rating = rating,
        isFavorite = isFavorite,
        imageUrl = imageUrl,
        sourceUrl = sourceUrl,
        keywords = keywords,
        language = language,
        createdAt = Instant.parse(createdAt),
        updatedAt = Instant.parse(updatedAt)
    )
}

/**
 * DTO for recipe step from Supabase
 */
@Serializable
data class RecipeStepDto(
    val id: String,
    @SerialName("recipe_id") val recipeId: String,
    @SerialName("step_number") val stepNumber: Int,
    val instruction: String,
    @SerialName("duration_minutes") val durationMinutes: Int? = null
) {
    fun toDomain(): RecipeStep = RecipeStep(
        id = UUID.fromString(id),
        recipeId = UUID.fromString(recipeId),
        stepNumber = stepNumber,
        instruction = instruction,
        durationMinutes = durationMinutes
    )
}

/**
 * DTO for ingredient from Supabase
 */
@Serializable
data class IngredientDto(
    val id: String,
    @SerialName("name_en") val nameEn: String,
    @SerialName("name_de") val nameDe: String,
    @SerialName("default_measurement_type_id") val defaultMeasurementTypeId: String? = null
) {
    fun toDomain(): Ingredient = Ingredient(
        id = UUID.fromString(id),
        nameEn = nameEn,
        nameDe = nameDe,
        defaultMeasurementTypeId = defaultMeasurementTypeId?.let { UUID.fromString(it) }
    )
}

/**
 * DTO for measurement type from Supabase
 */
@Serializable
data class MeasurementTypeDto(
    val id: String,
    @SerialName("name_en") val nameEn: String,
    @SerialName("name_de") val nameDe: String,
    @SerialName("abbreviation_en") val abbreviationEn: String,
    @SerialName("abbreviation_de") val abbreviationDe: String
) {
    fun toDomain(): MeasurementType = MeasurementType(
        id = UUID.fromString(id),
        nameEn = nameEn,
        nameDe = nameDe,
        abbreviationEn = abbreviationEn,
        abbreviationDe = abbreviationDe
    )
}

/**
 * DTO for recipe ingredient from Supabase
 */
@Serializable
data class RecipeIngredientDto(
    val id: String,
    @SerialName("recipe_id") val recipeId: String,
    @SerialName("ingredient_id") val ingredientId: String,
    @SerialName("measurement_type_id") val measurementTypeId: String? = null,
    val quantity: Double? = null,
    val notes: String? = null,
    @SerialName("display_order") val displayOrder: Int,
    val ingredient: IngredientDto? = null,
    @SerialName("measurement_type") val measurementType: MeasurementTypeDto? = null
) {
    fun toDomain(): RecipeIngredient = RecipeIngredient(
        id = UUID.fromString(id),
        recipeId = UUID.fromString(recipeId),
        ingredientId = UUID.fromString(ingredientId),
        measurementTypeId = measurementTypeId?.let { UUID.fromString(it) },
        quantity = quantity,
        notes = notes,
        displayOrder = displayOrder,
        ingredient = ingredient?.toDomain(),
        measurementType = measurementType?.toDomain()
    )
}
