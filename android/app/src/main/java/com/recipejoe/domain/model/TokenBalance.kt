package com.recipejoe.domain.model

/**
 * Token balance for the current user
 */
data class TokenBalance(
    val balance: Int
)

/**
 * Token package for purchase
 */
enum class TokenPackage(val productId: String, val tokenCount: Int) {
    TOKENS_10("tokens_10", 10),
    TOKENS_25("tokens_25", 25),
    TOKENS_50("tokens_50", 50),
    TOKENS_120("tokens_120", 120);

    companion object {
        fun fromProductId(productId: String): TokenPackage? {
            return entries.find { it.productId == productId }
        }
    }
}
