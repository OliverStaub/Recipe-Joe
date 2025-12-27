package com.recipejoe.data.repository

import com.recipejoe.data.remote.SupabaseClientProvider
import com.recipejoe.data.remote.dto.TokenBalanceDto
import com.recipejoe.data.remote.dto.ValidatePurchaseRequest
import com.recipejoe.data.remote.dto.ValidatePurchaseResponse
import io.github.jan.supabase.functions.functions
import io.github.jan.supabase.postgrest.postgrest
import io.ktor.client.call.body
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import timber.log.Timber
import javax.inject.Inject
import javax.inject.Singleton

interface TokenRepository {
    val tokenBalance: StateFlow<Int>

    suspend fun refreshBalance(): Int
    suspend fun validatePurchase(
        transactionId: String,
        productId: String,
        purchaseToken: String
    ): Int
}

@Singleton
class TokenRepositoryImpl @Inject constructor(
    private val supabaseProvider: SupabaseClientProvider
) : TokenRepository {

    private val client get() = supabaseProvider.client

    private val _tokenBalance = MutableStateFlow(0)
    override val tokenBalance: StateFlow<Int> = _tokenBalance.asStateFlow()

    override suspend fun refreshBalance(): Int {
        return try {
            val response = client.postgrest
                .from("user_tokens")
                .select {
                    limit(1)
                }
                .decodeSingle<TokenBalanceDto>()

            _tokenBalance.value = response.balance
            response.balance
        } catch (e: Exception) {
            Timber.e(e, "Failed to fetch token balance")
            throw e
        }
    }

    override suspend fun validatePurchase(
        transactionId: String,
        productId: String,
        purchaseToken: String
    ): Int {
        val request = ValidatePurchaseRequest(
            transactionId = transactionId,
            productId = productId,
            originalTransactionId = null,
            purchaseToken = purchaseToken
        )

        val response = client.functions.invoke(
            function = "validate-purchase",
            body = request
        )

        val result = response.body<ValidatePurchaseResponse>()

        if (!result.success) {
            throw Exception(result.error ?: "Purchase validation failed")
        }

        result.balance?.let { newBalance ->
            _tokenBalance.value = newBalance
        }

        return result.balance ?: _tokenBalance.value
    }
}
