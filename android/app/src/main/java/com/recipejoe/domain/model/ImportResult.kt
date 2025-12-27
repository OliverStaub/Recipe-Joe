package com.recipejoe.domain.model

import java.util.UUID

/**
 * Result of a recipe import operation
 */
data class ImportResult(
    val success: Boolean,
    val recipeId: UUID?,
    val recipeName: String?,
    val error: String?,
    val tokensDeducted: Int?,
    val tokensRemaining: Int?,
    val tokensRequired: Int?,
    val tokensAvailable: Int?,
    val stats: ImportStats?
)

/**
 * Import statistics
 */
data class ImportStats(
    val stepsCount: Int,
    val ingredientsCount: Int,
    val newIngredientsCount: Int,
    val tokensUsed: TokenUsage
)

/**
 * Token usage from AI processing
 */
data class TokenUsage(
    val inputTokens: Int,
    val outputTokens: Int
)

/**
 * Media type for OCR import
 */
enum class MediaImportType(val value: String) {
    IMAGE("image"),
    PDF("pdf")
}
