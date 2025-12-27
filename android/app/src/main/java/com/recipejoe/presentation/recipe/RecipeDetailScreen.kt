package com.recipejoe.presentation.recipe

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material.icons.filled.Favorite
import androidx.compose.material.icons.filled.FavoriteBorder
import androidx.compose.material.icons.filled.Restaurant
import androidx.compose.material.icons.filled.Timer
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import coil.compose.AsyncImage
import com.recipejoe.R
import com.recipejoe.domain.model.RecipeDetail
import com.recipejoe.presentation.theme.CornerRadius
import com.recipejoe.presentation.theme.Spacing
import java.util.Locale

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun RecipeDetailScreen(
    onNavigateBack: () -> Unit,
    viewModel: RecipeDetailViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()
    var showDeleteDialog by remember { mutableStateOf(false) }

    Scaffold(
        topBar = {
            TopAppBar(
                title = {
                    when (val state = uiState) {
                        is RecipeDetailUiState.Success -> Text(
                            state.detail.recipe.name,
                            maxLines = 1
                        )
                        else -> Text("")
                    }
                },
                navigationIcon = {
                    IconButton(onClick = onNavigateBack) {
                        Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "Back")
                    }
                },
                actions = {
                    if (uiState is RecipeDetailUiState.Success) {
                        val detail = (uiState as RecipeDetailUiState.Success).detail
                        IconButton(onClick = { viewModel.toggleFavorite() }) {
                            Icon(
                                if (detail.recipe.isFavorite) Icons.Default.Favorite
                                else Icons.Default.FavoriteBorder,
                                contentDescription = null,
                                tint = if (detail.recipe.isFavorite) MaterialTheme.colorScheme.primary
                                       else MaterialTheme.colorScheme.onSurface
                            )
                        }
                        IconButton(onClick = { showDeleteDialog = true }) {
                            Icon(
                                Icons.Default.Delete,
                                contentDescription = stringResource(R.string.delete),
                                tint = MaterialTheme.colorScheme.error
                            )
                        }
                    }
                }
            )
        }
    ) { paddingValues ->
        Box(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
        ) {
            when (val state = uiState) {
                is RecipeDetailUiState.Loading -> {
                    CircularProgressIndicator(
                        modifier = Modifier.align(Alignment.Center)
                    )
                }
                is RecipeDetailUiState.Error -> {
                    Column(
                        modifier = Modifier.align(Alignment.Center),
                        horizontalAlignment = Alignment.CenterHorizontally
                    ) {
                        Text(
                            text = state.message,
                            color = MaterialTheme.colorScheme.error
                        )
                        Spacer(modifier = Modifier.height(Spacing.md))
                        TextButton(onClick = { viewModel.loadRecipeDetail() }) {
                            Text("Retry")
                        }
                    }
                }
                is RecipeDetailUiState.Success -> {
                    RecipeDetailContent(detail = state.detail)
                }
            }
        }
    }

    // Delete confirmation dialog
    if (showDeleteDialog) {
        AlertDialog(
            onDismissRequest = { showDeleteDialog = false },
            title = { Text(stringResource(R.string.delete_recipe)) },
            text = { Text(stringResource(R.string.delete_recipe_confirm)) },
            confirmButton = {
                TextButton(
                    onClick = {
                        viewModel.deleteRecipe(onSuccess = onNavigateBack)
                        showDeleteDialog = false
                    }
                ) {
                    Text(
                        stringResource(R.string.delete),
                        color = MaterialTheme.colorScheme.error
                    )
                }
            },
            dismissButton = {
                TextButton(onClick = { showDeleteDialog = false }) {
                    Text(stringResource(R.string.cancel))
                }
            }
        )
    }
}

@Composable
private fun RecipeDetailContent(detail: RecipeDetail) {
    val languageCode = Locale.getDefault().language

    Column(
        modifier = Modifier
            .fillMaxSize()
            .verticalScroll(rememberScrollState())
    ) {
        // Hero image
        detail.recipe.imageUrl?.let { imageUrl ->
            AsyncImage(
                model = imageUrl,
                contentDescription = detail.recipe.name,
                modifier = Modifier
                    .fillMaxWidth()
                    .aspectRatio(16f / 9f)
                    .clip(RoundedCornerShape(bottomStart = CornerRadius.large, bottomEnd = CornerRadius.large)),
                contentScale = ContentScale.Crop
            )
        }

        Column(
            modifier = Modifier.padding(Spacing.lg)
        ) {
            // Recipe metadata
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceEvenly
            ) {
                detail.recipe.prepTimeMinutes?.let { time ->
                    MetadataItem(
                        icon = Icons.Default.Timer,
                        label = stringResource(R.string.prep_time),
                        value = stringResource(R.string.minutes, time)
                    )
                }
                detail.recipe.cookTimeMinutes?.let { time ->
                    MetadataItem(
                        icon = Icons.Default.Timer,
                        label = stringResource(R.string.cook_time),
                        value = stringResource(R.string.minutes, time)
                    )
                }
                detail.recipe.recipeYield?.let { yield ->
                    MetadataItem(
                        icon = Icons.Default.Restaurant,
                        label = stringResource(R.string.servings),
                        value = yield
                    )
                }
            }

            // Description
            detail.recipe.description?.let { description ->
                Spacer(modifier = Modifier.height(Spacing.xl))
                Text(
                    text = description,
                    style = MaterialTheme.typography.bodyLarge,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }

            // Ingredients section
            if (detail.sortedIngredients.isNotEmpty()) {
                Spacer(modifier = Modifier.height(Spacing.xl))
                Text(
                    text = stringResource(R.string.ingredients),
                    style = MaterialTheme.typography.headlineMedium
                )
                Spacer(modifier = Modifier.height(Spacing.md))
                Card(
                    modifier = Modifier.fillMaxWidth(),
                    colors = CardDefaults.cardColors(
                        containerColor = MaterialTheme.colorScheme.surfaceVariant
                    )
                ) {
                    Column(
                        modifier = Modifier.padding(Spacing.lg)
                    ) {
                        detail.sortedIngredients.forEach { ingredient ->
                            Row(
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .padding(vertical = Spacing.xs)
                            ) {
                                val quantity = ingredient.formattedQuantity(languageCode)
                                if (quantity.isNotBlank()) {
                                    Text(
                                        text = quantity,
                                        style = MaterialTheme.typography.bodyMedium,
                                        color = MaterialTheme.colorScheme.primary,
                                        modifier = Modifier.width(80.dp)
                                    )
                                }
                                Text(
                                    text = ingredient.ingredient?.localizedName(languageCode) ?: "",
                                    style = MaterialTheme.typography.bodyMedium
                                )
                                ingredient.notes?.let { notes ->
                                    Text(
                                        text = " ($notes)",
                                        style = MaterialTheme.typography.bodySmall,
                                        color = MaterialTheme.colorScheme.onSurfaceVariant
                                    )
                                }
                            }
                        }
                    }
                }
            }

            // Instructions section
            if (detail.sortedSteps.isNotEmpty()) {
                Spacer(modifier = Modifier.height(Spacing.xl))
                Text(
                    text = stringResource(R.string.instructions),
                    style = MaterialTheme.typography.headlineMedium
                )
                Spacer(modifier = Modifier.height(Spacing.md))

                detail.sortedSteps.forEachIndexed { index, step ->
                    Card(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(vertical = Spacing.xs),
                        colors = CardDefaults.cardColors(
                            containerColor = MaterialTheme.colorScheme.surface
                        )
                    ) {
                        Row(
                            modifier = Modifier.padding(Spacing.md)
                        ) {
                            // Step number badge
                            Card(
                                colors = CardDefaults.cardColors(
                                    containerColor = MaterialTheme.colorScheme.primary
                                ),
                                shape = RoundedCornerShape(50)
                            ) {
                                Text(
                                    text = "${index + 1}",
                                    style = MaterialTheme.typography.labelLarge,
                                    color = MaterialTheme.colorScheme.onPrimary,
                                    modifier = Modifier.padding(
                                        horizontal = Spacing.md,
                                        vertical = Spacing.xs
                                    )
                                )
                            }
                            Spacer(modifier = Modifier.width(Spacing.md))
                            Column {
                                Text(
                                    text = step.instruction,
                                    style = MaterialTheme.typography.bodyMedium
                                )
                                step.durationMinutes?.let { duration ->
                                    Spacer(modifier = Modifier.height(Spacing.xs))
                                    Row(
                                        verticalAlignment = Alignment.CenterVertically
                                    ) {
                                        Icon(
                                            Icons.Default.Timer,
                                            contentDescription = null,
                                            modifier = Modifier.size(14.dp),
                                            tint = MaterialTheme.colorScheme.onSurfaceVariant
                                        )
                                        Spacer(modifier = Modifier.width(Spacing.xs))
                                        Text(
                                            text = stringResource(R.string.minutes, duration),
                                            style = MaterialTheme.typography.labelSmall,
                                            color = MaterialTheme.colorScheme.onSurfaceVariant
                                        )
                                    }
                                }
                            }
                        }
                    }
                }
            }

            Spacer(modifier = Modifier.height(Spacing.xxl))
        }
    }
}

@Composable
private fun MetadataItem(
    icon: androidx.compose.ui.graphics.vector.ImageVector,
    label: String,
    value: String
) {
    Column(
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Icon(
            icon,
            contentDescription = null,
            tint = MaterialTheme.colorScheme.primary
        )
        Text(
            text = label,
            style = MaterialTheme.typography.labelSmall,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )
        Text(
            text = value,
            style = MaterialTheme.typography.bodyMedium
        )
    }
}
