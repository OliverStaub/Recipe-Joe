package com.recipejoe.presentation.recipe

import androidx.lifecycle.SavedStateHandle
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.recipejoe.data.repository.RecipeRepository
import com.recipejoe.domain.model.RecipeDetail
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import timber.log.Timber
import java.util.UUID
import javax.inject.Inject

@HiltViewModel
class RecipeDetailViewModel @Inject constructor(
    private val recipeRepository: RecipeRepository,
    savedStateHandle: SavedStateHandle
) : ViewModel() {

    private val recipeId: UUID = UUID.fromString(savedStateHandle.get<String>("recipeId")!!)

    private val _uiState = MutableStateFlow<RecipeDetailUiState>(RecipeDetailUiState.Loading)
    val uiState: StateFlow<RecipeDetailUiState> = _uiState.asStateFlow()

    init {
        loadRecipeDetail()
    }

    fun loadRecipeDetail() {
        viewModelScope.launch {
            _uiState.value = RecipeDetailUiState.Loading
            try {
                val detail = recipeRepository.getRecipeDetail(recipeId)
                if (detail != null) {
                    _uiState.value = RecipeDetailUiState.Success(detail)
                } else {
                    _uiState.value = RecipeDetailUiState.Error("Recipe not found")
                }
            } catch (e: Exception) {
                Timber.e(e, "Failed to load recipe detail")
                _uiState.value = RecipeDetailUiState.Error(e.message ?: "Failed to load recipe")
            }
        }
    }

    fun toggleFavorite() {
        val currentState = _uiState.value
        if (currentState is RecipeDetailUiState.Success) {
            viewModelScope.launch {
                try {
                    val newFavorite = !currentState.detail.recipe.isFavorite
                    recipeRepository.updateFavorite(recipeId, newFavorite)
                    // Reload to get updated data
                    loadRecipeDetail()
                } catch (e: Exception) {
                    Timber.e(e, "Failed to update favorite")
                }
            }
        }
    }

    fun deleteRecipe(onSuccess: () -> Unit) {
        viewModelScope.launch {
            try {
                recipeRepository.deleteRecipe(recipeId)
                onSuccess()
            } catch (e: Exception) {
                Timber.e(e, "Failed to delete recipe")
                _uiState.value = RecipeDetailUiState.Error(e.message ?: "Failed to delete recipe")
            }
        }
    }
}

sealed class RecipeDetailUiState {
    data object Loading : RecipeDetailUiState()
    data class Success(val detail: RecipeDetail) : RecipeDetailUiState()
    data class Error(val message: String) : RecipeDetailUiState()
}
