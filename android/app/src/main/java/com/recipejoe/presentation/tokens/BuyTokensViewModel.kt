package com.recipejoe.presentation.tokens

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.recipejoe.data.repository.TokenRepository
import com.recipejoe.domain.model.TokenPackage
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import timber.log.Timber
import javax.inject.Inject

@HiltViewModel
class BuyTokensViewModel @Inject constructor(
    private val tokenRepository: TokenRepository
) : ViewModel() {

    val tokenBalance: StateFlow<Int> = tokenRepository.tokenBalance

    private val _uiState = MutableStateFlow(BuyTokensUiState())
    val uiState: StateFlow<BuyTokensUiState> = _uiState.asStateFlow()

    init {
        viewModelScope.launch {
            try {
                tokenRepository.refreshBalance()
            } catch (e: Exception) {
                Timber.e(e, "Failed to refresh token balance")
            }
        }
    }

    fun purchaseTokens(tokenPackage: TokenPackage) {
        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(
                isLoading = true,
                selectedPackage = tokenPackage,
                error = null
            )

            try {
                // TODO: Implement Google Play Billing integration
                // For now, show a placeholder message
                _uiState.value = _uiState.value.copy(
                    isLoading = false,
                    selectedPackage = null,
                    error = "In-app purchases are not yet configured. Please set up Google Play Billing."
                )
            } catch (e: Exception) {
                Timber.e(e, "Failed to purchase tokens")
                _uiState.value = _uiState.value.copy(
                    isLoading = false,
                    selectedPackage = null,
                    error = e.message ?: "Purchase failed"
                )
            }
        }
    }

    fun clearError() {
        _uiState.value = _uiState.value.copy(error = null)
    }

    fun clearPurchaseSuccess() {
        _uiState.value = _uiState.value.copy(purchaseSuccess = false)
    }
}

data class BuyTokensUiState(
    val isLoading: Boolean = false,
    val selectedPackage: TokenPackage? = null,
    val error: String? = null,
    val purchaseSuccess: Boolean = false
)
