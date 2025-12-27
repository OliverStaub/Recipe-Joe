package com.recipejoe.presentation.recipe

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.recipejoe.data.repository.RecipeRepository
import com.recipejoe.data.repository.TokenRepository
import com.recipejoe.domain.model.ImportResult
import com.recipejoe.domain.model.MediaImportType
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import timber.log.Timber
import java.util.Locale
import java.util.UUID
import javax.inject.Inject

@HiltViewModel
class AddRecipeViewModel @Inject constructor(
    private val recipeRepository: RecipeRepository,
    private val tokenRepository: TokenRepository
) : ViewModel() {

    val tokenBalance: StateFlow<Int> = tokenRepository.tokenBalance

    private val _uiState = MutableStateFlow(AddRecipeUiState())
    val uiState: StateFlow<AddRecipeUiState> = _uiState.asStateFlow()

    init {
        viewModelScope.launch {
            try {
                tokenRepository.refreshBalance()
            } catch (e: Exception) {
                Timber.e(e, "Failed to refresh token balance")
            }
        }
    }

    fun importFromUrl(url: String, translate: Boolean = true) {
        if (url.isBlank()) {
            _uiState.value = _uiState.value.copy(error = "Please enter a URL")
            return
        }

        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(isLoading = true, error = null)
            try {
                val language = Locale.getDefault().language.take(2)
                val result = recipeRepository.importRecipe(
                    url = url,
                    language = language,
                    translate = translate
                )

                if (result.success && result.recipeId != null) {
                    _uiState.value = _uiState.value.copy(
                        isLoading = false,
                        importedRecipeId = result.recipeId,
                        importedRecipeName = result.recipeName
                    )
                    // Refresh token balance
                    try {
                        tokenRepository.refreshBalance()
                    } catch (e: Exception) {
                        Timber.e(e, "Failed to refresh token balance after import")
                    }
                } else {
                    _uiState.value = _uiState.value.copy(
                        isLoading = false,
                        error = result.error ?: "Import failed"
                    )
                }
            } catch (e: Exception) {
                Timber.e(e, "Failed to import recipe")
                _uiState.value = _uiState.value.copy(
                    isLoading = false,
                    error = e.message ?: "Import failed"
                )
            }
        }
    }

    fun importFromImage(imageData: ByteArray, translate: Boolean = true) {
        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(isLoading = true, error = null)
            try {
                // Upload image to temp storage
                val storagePath = recipeRepository.uploadTempFile(
                    data = imageData,
                    contentType = "image/jpeg",
                    fileExtension = "jpg"
                )

                // Import via OCR
                val language = Locale.getDefault().language.take(2)
                val result = recipeRepository.importFromMedia(
                    storagePaths = listOf(storagePath),
                    mediaType = MediaImportType.IMAGE,
                    language = language,
                    translate = translate
                )

                handleImportResult(result)
            } catch (e: Exception) {
                Timber.e(e, "Failed to import from image")
                _uiState.value = _uiState.value.copy(
                    isLoading = false,
                    error = e.message ?: "Import failed"
                )
            }
        }
    }

    fun importFromPdf(pdfData: ByteArray, translate: Boolean = true) {
        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(isLoading = true, error = null)
            try {
                // Upload PDF to temp storage
                val storagePath = recipeRepository.uploadTempFile(
                    data = pdfData,
                    contentType = "application/pdf",
                    fileExtension = "pdf"
                )

                // Import via OCR
                val language = Locale.getDefault().language.take(2)
                val result = recipeRepository.importFromMedia(
                    storagePaths = listOf(storagePath),
                    mediaType = MediaImportType.PDF,
                    language = language,
                    translate = translate
                )

                handleImportResult(result)
            } catch (e: Exception) {
                Timber.e(e, "Failed to import from PDF")
                _uiState.value = _uiState.value.copy(
                    isLoading = false,
                    error = e.message ?: "Import failed"
                )
            }
        }
    }

    private suspend fun handleImportResult(result: ImportResult) {
        if (result.success && result.recipeId != null) {
            _uiState.value = _uiState.value.copy(
                isLoading = false,
                importedRecipeId = result.recipeId,
                importedRecipeName = result.recipeName
            )
            // Refresh token balance
            try {
                tokenRepository.refreshBalance()
            } catch (e: Exception) {
                Timber.e(e, "Failed to refresh token balance after import")
            }
        } else {
            _uiState.value = _uiState.value.copy(
                isLoading = false,
                error = result.error ?: "Import failed"
            )
        }
    }

    fun clearError() {
        _uiState.value = _uiState.value.copy(error = null)
    }

    fun clearImportedRecipe() {
        _uiState.value = _uiState.value.copy(
            importedRecipeId = null,
            importedRecipeName = null
        )
    }
}

data class AddRecipeUiState(
    val isLoading: Boolean = false,
    val error: String? = null,
    val importedRecipeId: UUID? = null,
    val importedRecipeName: String? = null
)
