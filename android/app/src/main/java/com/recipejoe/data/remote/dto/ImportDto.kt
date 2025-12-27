package com.recipejoe.data.remote.dto

import com.recipejoe.domain.model.ImportResult
import com.recipejoe.domain.model.ImportStats
import com.recipejoe.domain.model.TokenUsage
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import java.util.UUID

/**
 * Request to import a recipe from URL
 */
@Serializable
data class RecipeImportRequest(
    val url: String,
    val language: String,
    val translate: Boolean,
    @SerialName("startTimestamp") val startTimestamp: String? = null,
    @SerialName("endTimestamp") val endTimestamp: String? = null
)

/**
 * Response from recipe import Edge Function
 */
@Serializable
data class RecipeImportResponse(
    val success: Boolean,
    @SerialName("recipe_id") val recipeId: String? = null,
    @SerialName("recipe_name") val recipeName: String? = null,
    val error: String? = null,
    @SerialName("tokens_deducted") val tokensDeducted: Int? = null,
    @SerialName("tokens_remaining") val tokensRemaining: Int? = null,
    @SerialName("tokens_required") val tokensRequired: Int? = null,
    @SerialName("tokens_available") val tokensAvailable: Int? = null,
    val stats: ImportStatsDto? = null
) {
    fun toDomain(): ImportResult = ImportResult(
        success = success,
        recipeId = recipeId?.let { UUID.fromString(it) },
        recipeName = recipeName,
        error = error,
        tokensDeducted = tokensDeducted,
        tokensRemaining = tokensRemaining,
        tokensRequired = tokensRequired,
        tokensAvailable = tokensAvailable,
        stats = stats?.toDomain()
    )
}

/**
 * Import statistics from Edge Function
 */
@Serializable
data class ImportStatsDto(
    @SerialName("steps_count") val stepsCount: Int,
    @SerialName("ingredients_count") val ingredientsCount: Int,
    @SerialName("new_ingredients_count") val newIngredientsCount: Int,
    @SerialName("tokens_used") val tokensUsed: TokenUsageDto
) {
    fun toDomain(): ImportStats = ImportStats(
        stepsCount = stepsCount,
        ingredientsCount = ingredientsCount,
        newIngredientsCount = newIngredientsCount,
        tokensUsed = tokensUsed.toDomain()
    )
}

/**
 * Token usage from AI processing
 */
@Serializable
data class TokenUsageDto(
    @SerialName("input_tokens") val inputTokens: Int,
    @SerialName("output_tokens") val outputTokens: Int
) {
    fun toDomain(): TokenUsage = TokenUsage(
        inputTokens = inputTokens,
        outputTokens = outputTokens
    )
}

/**
 * Request to import a recipe from image/PDF via OCR
 */
@Serializable
data class MediaImportRequest(
    @SerialName("storage_paths") val storagePaths: List<String>,
    @SerialName("media_type") val mediaType: String,
    val language: String,
    val translate: Boolean
)

/**
 * Token balance response
 */
@Serializable
data class TokenBalanceDto(
    val balance: Int
)

/**
 * Purchase validation request
 */
@Serializable
data class ValidatePurchaseRequest(
    val transactionId: String,
    val productId: String,
    val originalTransactionId: String?,
    val purchaseToken: String? = null // Android-specific
)

/**
 * Purchase validation response
 */
@Serializable
data class ValidatePurchaseResponse(
    val success: Boolean,
    val balance: Int? = null,
    val tokensAdded: Int? = null,
    val alreadyProcessed: Boolean? = null,
    val error: String? = null
)
