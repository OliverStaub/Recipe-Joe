package com.recipejoe.presentation.recipe

import android.view.HapticFeedbackConstants
import androidx.compose.foundation.ExperimentalFoundationApi
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.combinedClickable
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
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.rememberModalBottomSheetState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
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
import androidx.compose.ui.platform.LocalView
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.hilt.navigation.compose.hiltViewModel
import coil.compose.AsyncImage
import com.recipejoe.R
import com.recipejoe.domain.model.RecipeDetail
import com.recipejoe.domain.model.RecipeIngredient
import com.recipejoe.domain.model.RecipeStep
import com.recipejoe.presentation.theme.CornerRadius
import com.recipejoe.presentation.theme.Spacing
import java.util.Locale
import java.util.UUID

// Step type prefix mappings to emoji and color
private data class StepTypeMapping(
    val prefix: String,
    val emoji: String,
    val color: Color
)

private val stepTypeMappings = listOf(
    StepTypeMapping("prep: ", "🔪", Color(0xFF2196F3).copy(alpha = 0.15f)),
    StepTypeMapping("heat: ", "🔥", Color(0xFFFF9800).copy(alpha = 0.15f)),
    StepTypeMapping("cook: ", "🍳", Color(0xFFFFEB3B).copy(alpha = 0.15f)),
    StepTypeMapping("mix: ", "🥄", Color(0xFF9C27B0).copy(alpha = 0.15f)),
    StepTypeMapping("assemble: ", "🍽️", Color(0xFF4CAF50).copy(alpha = 0.15f)),
    StepTypeMapping("bake: ", "♨️", Color(0xFFF44336).copy(alpha = 0.15f)),
    StepTypeMapping("rest: ", "⏸️", Color(0xFF9E9E9E).copy(alpha = 0.15f)),
    StepTypeMapping("finish: ", "✨", Color(0xFFE91E63).copy(alpha = 0.15f))
)

private fun getStepTypeInfo(instruction: String): StepTypeMapping? {
    val lowerInstruction = instruction.lowercase()
    return stepTypeMappings.find { lowerInstruction.startsWith(it.prefix) }
}

private fun getInstructionWithoutPrefix(instruction: String): String {
    val lowerInstruction = instruction.lowercase()
    for (mapping in stepTypeMappings) {
        if (lowerInstruction.startsWith(mapping.prefix)) {
            return instruction.drop(mapping.prefix.length)
        }
    }
    return instruction
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun RecipeDetailScreen(
    onNavigateBack: () -> Unit,
    viewModel: RecipeDetailViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()
    var showDeleteDialog by remember { mutableStateOf(false) }

    // Step highlighting state
    var highlightedStepId by rememberSaveable { mutableStateOf<UUID?>(null) }

    // Edit sheet states
    var showStepEditSheet by remember { mutableStateOf(false) }
    var editingStep by remember { mutableStateOf<RecipeStep?>(null) }
    var editStepText by remember { mutableStateOf("") }

    var showIngredientEditSheet by remember { mutableStateOf(false) }
    var editingIngredient by remember { mutableStateOf<RecipeIngredient?>(null) }
    var editIngredientQuantity by remember { mutableStateOf("") }
    var editIngredientNotes by remember { mutableStateOf("") }

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
                    RecipeDetailContent(
                        detail = state.detail,
                        highlightedStepId = highlightedStepId,
                        onStepTap = { stepId ->
                            highlightedStepId = if (highlightedStepId == stepId) null else stepId
                        },
                        onStepLongPress = { step ->
                            editingStep = step
                            editStepText = step.instruction
                            showStepEditSheet = true
                        },
                        onIngredientLongPress = { ingredient ->
                            editingIngredient = ingredient
                            editIngredientQuantity = ingredient.quantity?.toString() ?: ""
                            editIngredientNotes = ingredient.notes ?: ""
                            showIngredientEditSheet = true
                        }
                    )
                }
            }
        }
    }

    // Step edit bottom sheet
    if (showStepEditSheet) {
        ModalBottomSheet(
            onDismissRequest = { showStepEditSheet = false },
            sheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true)
        ) {
            StepEditContent(
                stepNumber = editingStep?.stepNumber ?: 1,
                instruction = editStepText,
                onInstructionChange = { editStepText = it },
                onSave = {
                    editingStep?.let { step ->
                        viewModel.updateStepInstruction(step.id, editStepText)
                    }
                    showStepEditSheet = false
                },
                onCancel = { showStepEditSheet = false }
            )
        }
    }

    // Ingredient edit bottom sheet
    if (showIngredientEditSheet) {
        ModalBottomSheet(
            onDismissRequest = { showIngredientEditSheet = false },
            sheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true)
        ) {
            IngredientEditContent(
                ingredientName = editingIngredient?.ingredient?.localizedName(Locale.getDefault().language) ?: "",
                quantity = editIngredientQuantity,
                onQuantityChange = { editIngredientQuantity = it },
                notes = editIngredientNotes,
                onNotesChange = { editIngredientNotes = it },
                measurementAbbreviation = editingIngredient?.measurementType?.let {
                    if (Locale.getDefault().language == "de") it.abbreviationDe else it.abbreviationEn
                },
                onSave = {
                    editingIngredient?.let { ingredient ->
                        viewModel.updateIngredient(
                            ingredientId = ingredient.id,
                            quantity = editIngredientQuantity.toDoubleOrNull(),
                            notes = editIngredientNotes.takeIf { it.isNotBlank() }
                        )
                    }
                    showIngredientEditSheet = false
                },
                onCancel = { showIngredientEditSheet = false }
            )
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

@OptIn(ExperimentalFoundationApi::class)
@Composable
private fun RecipeDetailContent(
    detail: RecipeDetail,
    highlightedStepId: UUID?,
    onStepTap: (UUID) -> Unit,
    onStepLongPress: (RecipeStep) -> Unit,
    onIngredientLongPress: (RecipeIngredient) -> Unit
) {
    val languageCode = Locale.getDefault().language
    val view = LocalView.current

    Column(
        modifier = Modifier
            .fillMaxSize()
            .verticalScroll(rememberScrollState())
    ) {
        // Hero image
        if (detail.recipe.imageUrl != null) {
            AsyncImage(
                model = detail.recipe.imageUrl,
                contentDescription = detail.recipe.name,
                modifier = Modifier
                    .fillMaxWidth()
                    .aspectRatio(16f / 9f)
                    .clip(RoundedCornerShape(bottomStart = CornerRadius.large, bottomEnd = CornerRadius.large)),
                contentScale = ContentScale.Crop
            )
        } else {
            // Placeholder
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .height(200.dp)
                    .background(MaterialTheme.colorScheme.primaryContainer),
                contentAlignment = Alignment.Center
            ) {
                Icon(
                    Icons.Default.Restaurant,
                    contentDescription = null,
                    modifier = Modifier.size(64.dp),
                    tint = MaterialTheme.colorScheme.primary
                )
            }
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
                        value = formatTime(time)
                    )
                }
                detail.recipe.cookTimeMinutes?.let { time ->
                    MetadataItem(
                        icon = Icons.Default.Timer,
                        label = stringResource(R.string.cook_time),
                        value = formatTime(time)
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
                SectionHeader(
                    title = stringResource(R.string.ingredients),
                    emoji = "🧺"
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
                            IngredientRow(
                                ingredient = ingredient,
                                languageCode = languageCode,
                                onLongPress = {
                                    view.performHapticFeedback(HapticFeedbackConstants.LONG_PRESS)
                                    onIngredientLongPress(ingredient)
                                }
                            )
                        }
                    }
                }
            }

            // Instructions section
            if (detail.sortedSteps.isNotEmpty()) {
                Spacer(modifier = Modifier.height(Spacing.xl))
                SectionHeader(
                    title = stringResource(R.string.instructions),
                    emoji = "📝"
                )
                Spacer(modifier = Modifier.height(Spacing.md))

                Column(
                    verticalArrangement = Arrangement.spacedBy(Spacing.sm)
                ) {
                    detail.sortedSteps.forEach { step ->
                        StepRow(
                            step = step,
                            isHighlighted = highlightedStepId == step.id,
                            onTap = {
                                view.performHapticFeedback(HapticFeedbackConstants.CONTEXT_CLICK)
                                onStepTap(step.id)
                            },
                            onLongPress = {
                                view.performHapticFeedback(HapticFeedbackConstants.LONG_PRESS)
                                onStepLongPress(step)
                            }
                        )
                    }
                }
            }

            Spacer(modifier = Modifier.height(Spacing.xxl))
        }
    }
}

@Composable
private fun SectionHeader(
    title: String,
    emoji: String
) {
    Row(
        verticalAlignment = Alignment.CenterVertically
    ) {
        Text(
            text = emoji,
            fontSize = 20.sp
        )
        Spacer(modifier = Modifier.width(Spacing.sm))
        Text(
            text = title,
            style = MaterialTheme.typography.titleLarge,
            fontWeight = FontWeight.Bold
        )
    }
}

@OptIn(ExperimentalFoundationApi::class)
@Composable
private fun IngredientRow(
    ingredient: RecipeIngredient,
    languageCode: String,
    onLongPress: () -> Unit
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .combinedClickable(
                onClick = { },
                onLongClick = onLongPress
            )
            .padding(vertical = Spacing.xs)
    ) {
        val quantity = ingredient.formattedQuantity(languageCode)
        if (quantity.isNotBlank()) {
            Text(
                text = quantity,
                style = MaterialTheme.typography.bodyMedium,
                fontWeight = FontWeight.Medium,
                modifier = Modifier.width(70.dp)
            )
        }
        Column {
            Text(
                text = ingredient.ingredient?.localizedName(languageCode) ?: "",
                style = MaterialTheme.typography.bodyMedium
            )
            ingredient.notes?.let { notes ->
                Text(
                    text = notes,
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
        }
    }
}

@OptIn(ExperimentalFoundationApi::class)
@Composable
private fun StepRow(
    step: RecipeStep,
    isHighlighted: Boolean,
    onTap: () -> Unit,
    onLongPress: () -> Unit
) {
    val stepTypeInfo = getStepTypeInfo(step.instruction)
    val instructionText = getInstructionWithoutPrefix(step.instruction)

    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(CornerRadius.small))
            .background(
                if (isHighlighted) MaterialTheme.colorScheme.primaryContainer.copy(alpha = 0.5f)
                else Color.Transparent
            )
            .combinedClickable(
                onClick = onTap,
                onLongClick = onLongPress
            )
            .padding(Spacing.md),
        verticalAlignment = Alignment.Top
    ) {
        // Step number
        Text(
            text = "${step.stepNumber}",
            style = MaterialTheme.typography.titleMedium,
            fontWeight = FontWeight.SemiBold,
            color = if (isHighlighted) MaterialTheme.colorScheme.primary
                    else MaterialTheme.colorScheme.onSurfaceVariant,
            modifier = Modifier.width(28.dp)
        )

        // Step type emoji badge
        stepTypeInfo?.let { typeInfo ->
            Box(
                modifier = Modifier
                    .size(32.dp)
                    .clip(RoundedCornerShape(6.dp))
                    .background(typeInfo.color),
                contentAlignment = Alignment.Center
            ) {
                Text(
                    text = typeInfo.emoji,
                    fontSize = 16.sp
                )
            }
            Spacer(modifier = Modifier.width(Spacing.sm))
        }

        // Instruction
        Column(
            modifier = Modifier.weight(1f)
        ) {
            Text(
                text = instructionText,
                style = MaterialTheme.typography.bodyMedium,
                fontWeight = if (isHighlighted) FontWeight.Medium else FontWeight.Normal
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
                        text = "$duration min",
                        style = MaterialTheme.typography.labelSmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
            }
        }
    }
}

@Composable
private fun StepEditContent(
    stepNumber: Int,
    instruction: String,
    onInstructionChange: (String) -> Unit,
    onSave: () -> Unit,
    onCancel: () -> Unit
) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .padding(Spacing.lg)
    ) {
        Text(
            text = "Step $stepNumber",
            style = MaterialTheme.typography.titleLarge,
            fontWeight = FontWeight.Bold
        )

        Spacer(modifier = Modifier.height(Spacing.lg))

        OutlinedTextField(
            value = instruction,
            onValueChange = onInstructionChange,
            modifier = Modifier
                .fillMaxWidth()
                .height(150.dp),
            label = { Text("Instruction") }
        )

        Spacer(modifier = Modifier.height(Spacing.lg))

        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.End
        ) {
            TextButton(onClick = onCancel) {
                Text("Cancel")
            }
            Spacer(modifier = Modifier.width(Spacing.md))
            TextButton(onClick = onSave) {
                Text(
                    "Save",
                    fontWeight = FontWeight.Bold,
                    color = MaterialTheme.colorScheme.primary
                )
            }
        }

        Spacer(modifier = Modifier.height(Spacing.xl))
    }
}

@Composable
private fun IngredientEditContent(
    ingredientName: String,
    quantity: String,
    onQuantityChange: (String) -> Unit,
    notes: String,
    onNotesChange: (String) -> Unit,
    measurementAbbreviation: String?,
    onSave: () -> Unit,
    onCancel: () -> Unit
) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .padding(Spacing.lg)
    ) {
        Text(
            text = ingredientName,
            style = MaterialTheme.typography.titleLarge,
            fontWeight = FontWeight.Bold
        )

        Spacer(modifier = Modifier.height(Spacing.lg))

        Row(
            verticalAlignment = Alignment.CenterVertically
        ) {
            OutlinedTextField(
                value = quantity,
                onValueChange = onQuantityChange,
                modifier = Modifier.weight(1f),
                label = { Text("Quantity") },
                singleLine = true
            )
            measurementAbbreviation?.let {
                Spacer(modifier = Modifier.width(Spacing.md))
                Text(
                    text = it,
                    style = MaterialTheme.typography.bodyLarge,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
        }

        Spacer(modifier = Modifier.height(Spacing.md))

        OutlinedTextField(
            value = notes,
            onValueChange = onNotesChange,
            modifier = Modifier.fillMaxWidth(),
            label = { Text("Notes (optional)") },
            singleLine = true
        )

        Spacer(modifier = Modifier.height(Spacing.lg))

        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.End
        ) {
            TextButton(onClick = onCancel) {
                Text("Cancel")
            }
            Spacer(modifier = Modifier.width(Spacing.md))
            TextButton(onClick = onSave) {
                Text(
                    "Save",
                    fontWeight = FontWeight.Bold,
                    color = MaterialTheme.colorScheme.primary
                )
            }
        }

        Spacer(modifier = Modifier.height(Spacing.xl))
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
