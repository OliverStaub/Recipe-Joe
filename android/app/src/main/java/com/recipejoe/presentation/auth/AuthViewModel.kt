package com.recipejoe.presentation.auth

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.recipejoe.data.repository.AuthException
import com.recipejoe.data.repository.AuthRepository
import com.recipejoe.domain.model.AuthState
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class AuthViewModel @Inject constructor(
    private val authRepository: AuthRepository
) : ViewModel() {

    val authState: StateFlow<AuthState> = authRepository.authState
        .stateIn(
            scope = viewModelScope,
            started = SharingStarted.WhileSubscribed(5000),
            initialValue = AuthState.Loading
        )

    private val _uiState = MutableStateFlow(AuthUiState())
    val uiState: StateFlow<AuthUiState> = _uiState.asStateFlow()

    fun signInWithGoogle(idToken: String) {
        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(isLoading = true, error = null)
            try {
                authRepository.signInWithGoogle(idToken)
            } catch (e: Exception) {
                _uiState.value = _uiState.value.copy(
                    isLoading = false,
                    error = e.message ?: "Sign in failed"
                )
            }
        }
    }

    fun signInWithEmail(email: String, password: String) {
        if (!isValidEmail(email)) {
            _uiState.value = _uiState.value.copy(error = "Please enter a valid email address")
            return
        }

        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(isLoading = true, error = null)
            try {
                authRepository.signInWithEmail(email, password)
            } catch (e: AuthException) {
                _uiState.value = _uiState.value.copy(
                    isLoading = false,
                    error = e.message
                )
            } catch (e: Exception) {
                _uiState.value = _uiState.value.copy(
                    isLoading = false,
                    error = e.message ?: "Sign in failed"
                )
            }
        }
    }

    fun signUpWithEmail(email: String, password: String) {
        if (!isValidEmail(email)) {
            _uiState.value = _uiState.value.copy(error = "Please enter a valid email address")
            return
        }
        if (password.length < 6) {
            _uiState.value = _uiState.value.copy(error = "Password must be at least 6 characters")
            return
        }

        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(isLoading = true, error = null)
            try {
                authRepository.signUpWithEmail(email, password)
            } catch (e: AuthException.EmailConfirmationRequired) {
                _uiState.value = _uiState.value.copy(
                    isLoading = false,
                    showEmailConfirmation = true
                )
            } catch (e: AuthException) {
                _uiState.value = _uiState.value.copy(
                    isLoading = false,
                    error = e.message
                )
            } catch (e: Exception) {
                _uiState.value = _uiState.value.copy(
                    isLoading = false,
                    error = e.message ?: "Sign up failed"
                )
            }
        }
    }

    fun resetPassword(email: String) {
        if (!isValidEmail(email)) {
            _uiState.value = _uiState.value.copy(error = "Please enter a valid email address")
            return
        }

        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(isLoading = true, error = null)
            try {
                authRepository.resetPassword(email)
                _uiState.value = _uiState.value.copy(
                    isLoading = false,
                    showResetEmailSent = true
                )
            } catch (e: Exception) {
                _uiState.value = _uiState.value.copy(
                    isLoading = false,
                    error = e.message ?: "Failed to send reset email"
                )
            }
        }
    }

    fun clearError() {
        _uiState.value = _uiState.value.copy(error = null)
    }

    fun dismissEmailConfirmation() {
        _uiState.value = _uiState.value.copy(showEmailConfirmation = false)
    }

    fun dismissResetEmailSent() {
        _uiState.value = _uiState.value.copy(showResetEmailSent = false)
    }

    private fun isValidEmail(email: String): Boolean {
        return android.util.Patterns.EMAIL_ADDRESS.matcher(email).matches()
    }
}

data class AuthUiState(
    val isLoading: Boolean = false,
    val error: String? = null,
    val showEmailConfirmation: Boolean = false,
    val showResetEmailSent: Boolean = false
)
