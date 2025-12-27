package com.recipejoe.presentation.home

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.recipejoe.data.repository.RecipeRepository
import com.recipejoe.data.repository.TokenRepository
import com.recipejoe.domain.model.Recipe
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
class HomeViewModel @Inject constructor(
    private val recipeRepository: RecipeRepository,
    private val tokenRepository: TokenRepository
) : ViewModel() {

    val recipes: StateFlow<List<Recipe>> = recipeRepository.getRecipes()
        .stateIn(
            scope = viewModelScope,
            started = SharingStarted.WhileSubscribed(5000),
            initialValue = emptyList()
        )

    val tokenBalance: StateFlow<Int> = tokenRepository.tokenBalance

    private val _uiState = MutableStateFlow(HomeUiState())
    val uiState: StateFlow<HomeUiState> = _uiState.asStateFlow()

    init {
        refreshData()
    }

    fun refreshData() {
        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(isRefreshing = true)
            try {
                recipeRepository.refreshRecipes()
                tokenRepository.refreshBalance()
            } catch (e: Exception) {
                Timber.e(e, "Failed to refresh data")
                _uiState.value = _uiState.value.copy(
                    error = e.message ?: "Failed to refresh data"
                )
            } finally {
                _uiState.value = _uiState.value.copy(isRefreshing = false)
            }
        }
    }

    fun toggleFavorite(recipe: Recipe) {
        viewModelScope.launch {
            try {
                recipeRepository.updateFavorite(recipe.id, !recipe.isFavorite)
            } catch (e: Exception) {
                Timber.e(e, "Failed to update favorite")
            }
        }
    }

    fun deleteRecipe(recipe: Recipe) {
        viewModelScope.launch {
            try {
                recipeRepository.deleteRecipe(recipe.id)
            } catch (e: Exception) {
                Timber.e(e, "Failed to delete recipe")
                _uiState.value = _uiState.value.copy(
                    error = e.message ?: "Failed to delete recipe"
                )
            }
        }
    }

    fun clearError() {
        _uiState.value = _uiState.value.copy(error = null)
    }
}

data class HomeUiState(
    val isRefreshing: Boolean = false,
    val error: String? = null
)
