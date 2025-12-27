package com.recipejoe.data.local.entity

import androidx.room.ColumnInfo
import androidx.room.Entity
import androidx.room.PrimaryKey
import com.recipejoe.domain.model.Recipe
import java.time.Instant
import java.util.UUID

/**
 * Room entity for recipes (local cache)
 */
@Entity(tableName = "recipes")
data class RecipeEntity(
    @PrimaryKey
    val id: String,

    @ColumnInfo(name = "user_id")
    val userId: String?,

    val name: String,
    val author: String?,
    val description: String?,

    @ColumnInfo(name = "prep_time_minutes")
    val prepTimeMinutes: Int?,

    @ColumnInfo(name = "cook_time_minutes")
    val cookTimeMinutes: Int?,

    @ColumnInfo(name = "total_time_minutes")
    val totalTimeMinutes: Int?,

    @ColumnInfo(name = "recipe_yield")
    val recipeYield: String?,

    val category: String?,
    val cuisine: String?,
    val rating: Int,

    @ColumnInfo(name = "is_favorite")
    val isFavorite: Boolean,

    @ColumnInfo(name = "image_url")
    val imageUrl: String?,

    @ColumnInfo(name = "source_url")
    val sourceUrl: String?,

    val keywords: String?, // Stored as comma-separated string
    val language: String?,

    @ColumnInfo(name = "created_at")
    val createdAt: Long,

    @ColumnInfo(name = "updated_at")
    val updatedAt: Long
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
        keywords = keywords?.split(",")?.map { it.trim() }?.filter { it.isNotEmpty() },
        language = language,
        createdAt = Instant.ofEpochMilli(createdAt),
        updatedAt = Instant.ofEpochMilli(updatedAt)
    )

    companion object {
        fun fromDomain(recipe: Recipe): RecipeEntity = RecipeEntity(
            id = recipe.id.toString(),
            userId = recipe.userId?.toString(),
            name = recipe.name,
            author = recipe.author,
            description = recipe.description,
            prepTimeMinutes = recipe.prepTimeMinutes,
            cookTimeMinutes = recipe.cookTimeMinutes,
            totalTimeMinutes = recipe.totalTimeMinutes,
            recipeYield = recipe.recipeYield,
            category = recipe.category,
            cuisine = recipe.cuisine,
            rating = recipe.rating,
            isFavorite = recipe.isFavorite,
            imageUrl = recipe.imageUrl,
            sourceUrl = recipe.sourceUrl,
            keywords = recipe.keywords?.joinToString(","),
            language = recipe.language,
            createdAt = recipe.createdAt.toEpochMilli(),
            updatedAt = recipe.updatedAt.toEpochMilli()
        )
    }
}
