package com.recipejoe.presentation.settings

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.recipejoe.data.repository.AppLanguage
import com.recipejoe.data.repository.AuthRepository
import com.recipejoe.data.repository.RecipeLanguage
import com.recipejoe.data.repository.RecipeRepository
import com.recipejoe.data.repository.TokenRepository
import com.recipejoe.data.repository.UserSettings
import com.recipejoe.data.repository.UserSettingsRepository
import com.recipejoe.domain.model.AuthState
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch
import timber.log.Timber
import javax.inject.Inject

@HiltViewModel
class SettingsViewModel @Inject constructor(
    private val authRepository: AuthRepository,
    private val recipeRepository: RecipeRepository,
    private val tokenRepository: TokenRepository,
    private val userSettingsRepository: UserSettingsRepository
) : ViewModel() {

    val authState: StateFlow<AuthState> = authRepository.authState
        .stateIn(
            scope = viewModelScope,
            started = SharingStarted.WhileSubscribed(5000),
            initialValue = AuthState.Loading
        )

    val tokenBalance: StateFlow<Int> = tokenRepository.tokenBalance

    val userSettings: StateFlow<UserSettings> = userSettingsRepository.settings
        .stateIn(
            scope = viewModelScope,
            started = SharingStarted.WhileSubscribed(5000),
            initialValue = UserSettings()
        )

    private val _uiState = MutableStateFlow(SettingsUiState())
    val uiState: StateFlow<SettingsUiState> = _uiState.asStateFlow()

    val userEmail: String?
        get() = authRepository.currentUserEmail

    fun setAppLanguage(language: AppLanguage) {
        viewModelScope.launch {
            try {
                userSettingsRepository.setAppLanguage(language)
            } catch (e: Exception) {
                Timber.e(e, "Failed to set app language")
                _uiState.value = _uiState.value.copy(error = "Failed to update language")
            }
        }
    }

    fun setRecipeLanguage(language: RecipeLanguage) {
        viewModelScope.launch {
            try {
                userSettingsRepository.setRecipeLanguage(language)
            } catch (e: Exception) {
                Timber.e(e, "Failed to set recipe language")
                _uiState.value = _uiState.value.copy(error = "Failed to update language")
            }
        }
    }

    fun setEnableTranslation(enabled: Boolean) {
        viewModelScope.launch {
            try {
                userSettingsRepository.setEnableTranslation(enabled)
            } catch (e: Exception) {
                Timber.e(e, "Failed to set translation setting")
                _uiState.value = _uiState.value.copy(error = "Failed to update setting")
            }
        }
    }

    fun signOut() {
        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(isLoading = true)
            try {
                recipeRepository.clearCache()
                authRepository.signOut()
            } catch (e: Exception) {
                Timber.e(e, "Sign out failed")
                _uiState.value = _uiState.value.copy(
                    isLoading = false,
                    error = e.message ?: "Sign out failed"
                )
            }
        }
    }

    fun deleteAccount() {
        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(isLoading = true)
            try {
                recipeRepository.clearCache()
                authRepository.deleteAccount()
            } catch (e: Exception) {
                Timber.e(e, "Delete account failed")
                _uiState.value = _uiState.value.copy(
                    isLoading = false,
                    error = e.message ?: "Delete account failed"
                )
            }
        }
    }

    fun clearError() {
        _uiState.value = _uiState.value.copy(error = null)
    }
}

data class SettingsUiState(
    val isLoading: Boolean = false,
    val error: String? = null
)
