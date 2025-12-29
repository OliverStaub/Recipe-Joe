package com.recipejoe.presentation.home

import androidx.compose.animation.animateColorAsState
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.KeyboardArrowRight
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material.icons.filled.Favorite
import androidx.compose.material.icons.filled.FavoriteBorder
import androidx.compose.material.icons.filled.Restaurant
import androidx.compose.material.icons.filled.Settings
import androidx.compose.material.icons.filled.Timer
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.FilterChip
import androidx.compose.material3.FilterChipDefaults
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.SnackbarHost
import androidx.compose.material3.SnackbarHostState
import androidx.compose.material3.SwipeToDismissBox
import androidx.compose.material3.SwipeToDismissBoxValue
import androidx.compose.material3.Text
import androidx.compose.material3.pulltorefresh.PullToRefreshBox
import androidx.compose.material3.rememberSwipeToDismissBoxState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.derivedStateOf
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import coil.compose.AsyncImage
import com.recipejoe.R
import com.recipejoe.domain.model.Recipe
import com.recipejoe.presentation.theme.CornerRadius
import com.recipejoe.presentation.theme.Spacing
import java.util.UUID

enum class TimeFilter {
    ALL, QUICK, MEDIUM, LONG
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun HomeScreen(
    onNavigateToRecipe: (UUID) -> Unit,
    onNavigateToSettings: () -> Unit,
    modifier: Modifier = Modifier,
    viewModel: HomeViewModel = hiltViewModel()
) {
    val recipes by viewModel.recipes.collectAsState()
    val tokenBalance by viewModel.tokenBalance.collectAsState()
    val uiState by viewModel.uiState.collectAsState()
    val snackbarHostState = remember { SnackbarHostState() }

    // Filter state
    var timeFilter by rememberSaveable { mutableStateOf(TimeFilter.ALL) }
    var showFavoritesOnly by rememberSaveable { mutableStateOf(false) }

    // Filtered recipes
    val filteredRecipes by remember(recipes, timeFilter, showFavoritesOnly) {
        derivedStateOf {
            recipes.filter { recipe ->
                val passesTimeFilter = when (timeFilter) {
                    TimeFilter.ALL -> true
                    TimeFilter.QUICK -> (recipe.totalTimeMinutes ?: 0) <= 30
                    TimeFilter.MEDIUM -> (recipe.totalTimeMinutes ?: 0) in 31..60
                    TimeFilter.LONG -> (recipe.totalTimeMinutes ?: 0) > 60
                }
                val passesFavoriteFilter = !showFavoritesOnly || recipe.isFavorite
                passesTimeFilter && passesFavoriteFilter
            }
        }
    }

    LaunchedEffect(uiState.error) {
        uiState.error?.let { error ->
            snackbarHostState.showSnackbar(error)
            viewModel.clearError()
        }
    }

    Scaffold(
        modifier = modifier,
        snackbarHost = { SnackbarHost(snackbarHostState) }
    ) { paddingValues ->
        PullToRefreshBox(
            isRefreshing = uiState.isRefreshing,
            onRefresh = { viewModel.refreshData() },
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
        ) {
            Column(
                modifier = Modifier.fillMaxSize()
            ) {
                // Header
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = Spacing.lg, vertical = Spacing.md),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text(
                        text = "RecipeJoe",
                        style = MaterialTheme.typography.headlineLarge,
                        fontWeight = FontWeight.Bold
                    )

                    Row(
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(Spacing.sm)
                    ) {
                        // Token balance badge
                        Card(
                            colors = CardDefaults.cardColors(
                                containerColor = MaterialTheme.colorScheme.primaryContainer
                            )
                        ) {
                            Text(
                                text = "$tokenBalance tokens",
                                style = MaterialTheme.typography.labelMedium,
                                modifier = Modifier.padding(
                                    horizontal = Spacing.md,
                                    vertical = Spacing.sm
                                )
                            )
                        }

                        // Settings button
                        IconButton(onClick = onNavigateToSettings) {
                            Icon(
                                Icons.Default.Settings,
                                contentDescription = stringResource(R.string.settings),
                                tint = MaterialTheme.colorScheme.primary
                            )
                        }
                    }
                }

                // Filter chips
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .horizontalScroll(rememberScrollState())
                        .padding(horizontal = Spacing.lg, vertical = Spacing.sm),
                    horizontalArrangement = Arrangement.spacedBy(Spacing.sm)
                ) {
                    FilterChip(
                        selected = timeFilter == TimeFilter.ALL,
                        onClick = { timeFilter = TimeFilter.ALL },
                        label = { Text(stringResource(R.string.filter_all)) },
                        colors = FilterChipDefaults.filterChipColors(
                            selectedContainerColor = MaterialTheme.colorScheme.primary,
                            selectedLabelColor = MaterialTheme.colorScheme.onPrimary
                        )
                    )
                    FilterChip(
                        selected = timeFilter == TimeFilter.QUICK,
                        onClick = { timeFilter = TimeFilter.QUICK },
                        label = { Text(stringResource(R.string.filter_quick)) },
                        leadingIcon = {
                            Icon(
                                Icons.Default.Timer,
                                contentDescription = null,
                                modifier = Modifier.size(16.dp)
                            )
                        },
                        colors = FilterChipDefaults.filterChipColors(
                            selectedContainerColor = MaterialTheme.colorScheme.primary,
                            selectedLabelColor = MaterialTheme.colorScheme.onPrimary
                        )
                    )
                    FilterChip(
                        selected = timeFilter == TimeFilter.MEDIUM,
                        onClick = { timeFilter = TimeFilter.MEDIUM },
                        label = { Text(stringResource(R.string.filter_medium)) },
                        leadingIcon = {
                            Icon(
                                Icons.Default.Timer,
                                contentDescription = null,
                                modifier = Modifier.size(16.dp)
                            )
                        },
                        colors = FilterChipDefaults.filterChipColors(
                            selectedContainerColor = MaterialTheme.colorScheme.primary,
                            selectedLabelColor = MaterialTheme.colorScheme.onPrimary
                        )
                    )
                    FilterChip(
                        selected = timeFilter == TimeFilter.LONG,
                        onClick = { timeFilter = TimeFilter.LONG },
                        label = { Text(stringResource(R.string.filter_long)) },
                        leadingIcon = {
                            Icon(
                                Icons.Default.Timer,
                                contentDescription = null,
                                modifier = Modifier.size(16.dp)
                            )
                        },
                        colors = FilterChipDefaults.filterChipColors(
                            selectedContainerColor = MaterialTheme.colorScheme.primary,
                            selectedLabelColor = MaterialTheme.colorScheme.onPrimary
                        )
                    )
                    FilterChip(
                        selected = showFavoritesOnly,
                        onClick = { showFavoritesOnly = !showFavoritesOnly },
                        label = { Text(stringResource(R.string.filter_favorites)) },
                        leadingIcon = {
                            Icon(
                                if (showFavoritesOnly) Icons.Default.Favorite else Icons.Default.FavoriteBorder,
                                contentDescription = null,
                                modifier = Modifier.size(16.dp)
                            )
                        },
                        colors = FilterChipDefaults.filterChipColors(
                            selectedContainerColor = MaterialTheme.colorScheme.primary,
                            selectedLabelColor = MaterialTheme.colorScheme.onPrimary
                        )
                    )
                }

                if (recipes.isEmpty() && !uiState.isRefreshing) {
                    // Empty state
                    Box(
                        modifier = Modifier.fillMaxSize(),
                        contentAlignment = Alignment.Center
                    ) {
                        Column(
                            horizontalAlignment = Alignment.CenterHorizontally,
                            modifier = Modifier.padding(Spacing.xl)
                        ) {
                            Icon(
                                Icons.Default.Restaurant,
                                contentDescription = null,
                                modifier = Modifier.size(64.dp),
                                tint = MaterialTheme.colorScheme.primary
                            )
                            Spacer(modifier = Modifier.height(Spacing.lg))
                            Text(
                                text = stringResource(R.string.no_recipes),
                                style = MaterialTheme.typography.titleLarge,
                                fontWeight = FontWeight.Bold
                            )
                            Spacer(modifier = Modifier.height(Spacing.sm))
                            Text(
                                text = stringResource(R.string.add_your_first_recipe),
                                style = MaterialTheme.typography.bodyMedium,
                                color = MaterialTheme.colorScheme.onSurfaceVariant
                            )
                        }
                    }
                } else if (filteredRecipes.isEmpty()) {
                    // No filter results
                    Box(
                        modifier = Modifier.fillMaxSize(),
                        contentAlignment = Alignment.Center
                    ) {
                        Column(
                            horizontalAlignment = Alignment.CenterHorizontally,
                            modifier = Modifier.padding(Spacing.xl)
                        ) {
                            Icon(
                                Icons.Default.Restaurant,
                                contentDescription = null,
                                modifier = Modifier.size(64.dp),
                                tint = MaterialTheme.colorScheme.onSurfaceVariant
                            )
                            Spacer(modifier = Modifier.height(Spacing.lg))
                            Text(
                                text = stringResource(R.string.no_matching_recipes),
                                style = MaterialTheme.typography.titleLarge,
                                fontWeight = FontWeight.Bold
                            )
                            Spacer(modifier = Modifier.height(Spacing.sm))
                            Text(
                                text = stringResource(R.string.try_adjusting_filters),
                                style = MaterialTheme.typography.bodyMedium,
                                color = MaterialTheme.colorScheme.onSurfaceVariant
                            )
                        }
                    }
                } else {
                    LazyColumn(
                        contentPadding = PaddingValues(vertical = Spacing.sm)
                    ) {
                        items(filteredRecipes, key = { it.id }) { recipe ->
                            SwipeableRecipeRow(
                                recipe = recipe,
                                onClick = { onNavigateToRecipe(recipe.id) },
                                onFavorite = { viewModel.toggleFavorite(recipe) },
                                onDelete = { viewModel.deleteRecipe(recipe) }
                            )
                        }
                    }
                }
            }
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun SwipeableRecipeRow(
    recipe: Recipe,
    onClick: () -> Unit,
    onFavorite: () -> Unit,
    onDelete: () -> Unit
) {
    val dismissState = rememberSwipeToDismissBoxState(
        confirmValueChange = { dismissValue ->
            when (dismissValue) {
                SwipeToDismissBoxValue.StartToEnd -> {
                    // Swipe right to favorite
                    onFavorite()
                    false // Don't dismiss, just toggle
                }
                SwipeToDismissBoxValue.EndToStart -> {
                    // Swipe left to delete
                    onDelete()
                    true
                }
                SwipeToDismissBoxValue.Settled -> false
            }
        }
    )

    SwipeToDismissBox(
        state = dismissState,
        backgroundContent = {
            val direction = dismissState.dismissDirection

            val color by animateColorAsState(
                targetValue = when (direction) {
                    SwipeToDismissBoxValue.StartToEnd -> {
                        if (recipe.isFavorite) Color.Gray else MaterialTheme.colorScheme.primary
                    }
                    SwipeToDismissBoxValue.EndToStart -> MaterialTheme.colorScheme.error
                    SwipeToDismissBoxValue.Settled -> Color.Transparent
                },
                label = "swipeColor"
            )

            val icon = when (direction) {
                SwipeToDismissBoxValue.StartToEnd -> {
                    if (recipe.isFavorite) Icons.Default.FavoriteBorder else Icons.Default.Favorite
                }
                SwipeToDismissBoxValue.EndToStart -> Icons.Default.Delete
                SwipeToDismissBoxValue.Settled -> null
            }

            val alignment = when (direction) {
                SwipeToDismissBoxValue.StartToEnd -> Alignment.CenterStart
                else -> Alignment.CenterEnd
            }

            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .background(color)
                    .padding(horizontal = Spacing.xl),
                contentAlignment = alignment
            ) {
                icon?.let {
                    Icon(
                        imageVector = it,
                        contentDescription = null,
                        tint = Color.White
                    )
                }
            }
        },
        enableDismissFromStartToEnd = true,
        enableDismissFromEndToStart = true
    ) {
        RecipeRow(
            recipe = recipe,
            onClick = onClick
        )
    }
}

@Composable
private fun RecipeRow(
    recipe: Recipe,
    onClick: () -> Unit
) {
    Column {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .clickable(onClick = onClick)
                .background(MaterialTheme.colorScheme.surface)
                .padding(horizontal = Spacing.lg, vertical = Spacing.md),
            verticalAlignment = Alignment.CenterVertically
        ) {
            // Recipe image or placeholder
            if (recipe.imageUrl != null) {
                AsyncImage(
                    model = recipe.imageUrl,
                    contentDescription = recipe.name,
                    modifier = Modifier
                        .size(80.dp)
                        .clip(RoundedCornerShape(CornerRadius.small)),
                    contentScale = ContentScale.Crop
                )
            } else {
                // Placeholder with fork/knife icon
                Box(
                    modifier = Modifier
                        .size(80.dp)
                        .clip(RoundedCornerShape(CornerRadius.small))
                        .background(MaterialTheme.colorScheme.primaryContainer),
                    contentAlignment = Alignment.Center
                ) {
                    Icon(
                        Icons.Default.Restaurant,
                        contentDescription = null,
                        modifier = Modifier.size(32.dp),
                        tint = MaterialTheme.colorScheme.primary
                    )
                }
            }

            Spacer(modifier = Modifier.width(Spacing.lg))

            // Recipe info
            Column(
                modifier = Modifier.weight(1f)
            ) {
                Text(
                    text = recipe.name,
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.SemiBold,
                    maxLines = 2,
                    overflow = TextOverflow.Ellipsis
                )

                recipe.category?.let { category ->
                    Spacer(modifier = Modifier.height(Spacing.xs))
                    Text(
                        text = category,
                        style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }

                recipe.totalTimeMinutes?.let { time ->
                    Spacer(modifier = Modifier.height(Spacing.xs))
                    Row(
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Icon(
                            Icons.Default.Timer,
                            contentDescription = null,
                            modifier = Modifier.size(16.dp),
                            tint = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                        Spacer(modifier = Modifier.width(Spacing.xs))
                        Text(
                            text = formatTime(time),
                            style = MaterialTheme.typography.bodySmall,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }
                }
            }

            // Chevron
            Icon(
                Icons.AutoMirrored.Filled.KeyboardArrowRight,
                contentDescription = null,
                tint = MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.5f)
            )
        }

        // Divider
        HorizontalDivider(
            modifier = Modifier.padding(start = 80.dp + Spacing.lg + Spacing.lg),
            color = MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.5f)
        )
    }
}

private fun formatTime(minutes: Int): String {
    return when {
        minutes >= 60 -> {
            val hours = minutes / 60
            val mins = minutes % 60
            if (mins > 0) "${hours}h ${mins}m" else "${hours}h"
        }
        else -> "$minutes min"
    }
}
