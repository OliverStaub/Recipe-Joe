package com.recipejoe.presentation.recipe

import android.Manifest
import android.net.Uri
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.slideInVertically
import androidx.compose.animation.slideOutVertically
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowForward
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.CameraAlt
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.Description
import androidx.compose.material.icons.filled.Error
import androidx.compose.material.icons.filled.PhotoLibrary
import androidx.compose.material.icons.filled.Videocam
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.OutlinedTextFieldDefaults
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalFocusManager
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.core.content.FileProvider
import androidx.hilt.navigation.compose.hiltViewModel
import com.recipejoe.R
import com.recipejoe.presentation.common.components.ImportProgressView
import com.recipejoe.presentation.common.components.ImportStep
import com.recipejoe.presentation.theme.CornerRadius
import com.recipejoe.presentation.theme.Spacing
import java.io.File
import java.util.UUID

@Composable
fun AddRecipeScreen(
    onNavigateToRecipe: (UUID) -> Unit,
    onNavigateToBuyTokens: () -> Unit,
    modifier: Modifier = Modifier,
    viewModel: AddRecipeViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()
    val tokenBalance by viewModel.tokenBalance.collectAsState()
    val focusManager = LocalFocusManager.current
    val context = LocalContext.current

    var url by rememberSaveable { mutableStateOf("") }
    var startTimestamp by rememberSaveable { mutableStateOf("") }
    var endTimestamp by rememberSaveable { mutableStateOf("") }
    var showMediaMenu by remember { mutableStateOf(false) }
    var photoUri by remember { mutableStateOf<Uri?>(null) }

    val isVideoUrl = viewModel.isVideoUrl(url)
    val videoPlatformName = viewModel.getVideoPlatformName(url)

    // Image picker launcher
    val imagePickerLauncher = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.GetContent()
    ) { uri ->
        uri?.let {
            context.contentResolver.openInputStream(it)?.use { stream ->
                val bytes = stream.readBytes()
                viewModel.importFromImage(bytes, true)
            }
        }
    }

    // Document picker launcher (PDF)
    val documentPickerLauncher = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.GetContent()
    ) { uri ->
        uri?.let {
            context.contentResolver.openInputStream(it)?.use { stream ->
                val bytes = stream.readBytes()
                viewModel.importFromPdf(bytes, true)
            }
        }
    }

    // Camera launcher
    val cameraLauncher = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.TakePicture()
    ) { success ->
        if (success) {
            photoUri?.let { uri ->
                context.contentResolver.openInputStream(uri)?.use { stream ->
                    val bytes = stream.readBytes()
                    viewModel.importFromImage(bytes, true)
                }
            }
        }
    }

    // Camera permission launcher
    val cameraPermissionLauncher = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.RequestPermission()
    ) { granted ->
        if (granted) {
            val photoFile = File.createTempFile("recipe_", ".jpg", context.cacheDir)
            photoUri = FileProvider.getUriForFile(
                context,
                "${context.packageName}.provider",
                photoFile
            )
            photoUri?.let { cameraLauncher.launch(it) }
        }
    }

    // Navigate to recipe after successful import
    LaunchedEffect(uiState.importedRecipeId) {
        uiState.importedRecipeId?.let { recipeId ->
            // Small delay to show success state
            kotlinx.coroutines.delay(1500)
            viewModel.clearImportedRecipe()
            onNavigateToRecipe(recipeId)
        }
    }

    Column(
        modifier = modifier
            .fillMaxSize()
            .verticalScroll(rememberScrollState())
            .padding(horizontal = Spacing.xl)
    ) {
        Spacer(modifier = Modifier.height(Spacing.lg))

        // Header with title and token balance
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Text(
                text = stringResource(R.string.new_recipe),
                style = MaterialTheme.typography.headlineLarge,
                fontWeight = FontWeight.Bold
            )

            TokenBadge(balance = tokenBalance)
        }

        Spacer(modifier = Modifier.height(Spacing.xl))

        // URL Input Row with dynamic button
        URLInputRow(
            url = url,
            onUrlChange = { url = it },
            isLoading = uiState.isLoading,
            onImport = {
                focusManager.clearFocus()
                viewModel.importFromUrl(
                    url = url,
                    translate = true,
                    startTimestamp = startTimestamp.takeIf { it.isNotBlank() },
                    endTimestamp = endTimestamp.takeIf { it.isNotBlank() }
                )
            },
            onShowMediaMenu = { showMediaMenu = true },
            showMediaMenu = showMediaMenu,
            onDismissMediaMenu = { showMediaMenu = false },
            onSelectPhoto = {
                showMediaMenu = false
                imagePickerLauncher.launch("image/*")
            },
            onTakePhoto = {
                showMediaMenu = false
                cameraPermissionLauncher.launch(Manifest.permission.CAMERA)
            },
            onSelectPdf = {
                showMediaMenu = false
                documentPickerLauncher.launch("application/pdf")
            }
        )

        Spacer(modifier = Modifier.height(Spacing.md))

        // Platform icons
        PlatformIconsRow()

        // Video timestamp section (only shown for video URLs)
        AnimatedVisibility(
            visible = isVideoUrl,
            enter = fadeIn() + slideInVertically(),
            exit = fadeOut() + slideOutVertically()
        ) {
            TimestampInputSection(
                startTimestamp = startTimestamp,
                onStartChange = { startTimestamp = formatTimestamp(it, startTimestamp) },
                endTimestamp = endTimestamp,
                onEndChange = { endTimestamp = formatTimestamp(it, endTimestamp) },
                platformName = videoPlatformName,
                modifier = Modifier.padding(top = Spacing.lg)
            )
        }

        Spacer(modifier = Modifier.height(Spacing.xl))

        // Import status section
        ImportStatusSection(
            isLoading = uiState.isLoading,
            currentStep = uiState.currentStep,
            error = uiState.error,
            importedRecipeName = uiState.importedRecipeName,
            stepsCount = uiState.stepsCount,
            ingredientsCount = uiState.ingredientsCount
        )
    }
}

@Composable
private fun TokenBadge(balance: Int) {
    Card(
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.primaryContainer
        )
    ) {
        Text(
            text = "$balance tokens",
            style = MaterialTheme.typography.labelMedium,
            modifier = Modifier.padding(
                horizontal = Spacing.md,
                vertical = Spacing.sm
            )
        )
    }
}

@Composable
private fun URLInputRow(
    url: String,
    onUrlChange: (String) -> Unit,
    isLoading: Boolean,
    onImport: () -> Unit,
    onShowMediaMenu: () -> Unit,
    showMediaMenu: Boolean,
    onDismissMediaMenu: () -> Unit,
    onSelectPhoto: () -> Unit,
    onTakePhoto: () -> Unit,
    onSelectPdf: () -> Unit
) {
    val hasUrl = url.isNotBlank()

    Row(
        modifier = Modifier.fillMaxWidth(),
        verticalAlignment = Alignment.CenterVertically
    ) {
        OutlinedTextField(
            value = url,
            onValueChange = onUrlChange,
            modifier = Modifier.weight(1f),
            placeholder = { Text(stringResource(R.string.paste_url_hint)) },
            keyboardOptions = KeyboardOptions(
                keyboardType = KeyboardType.Uri,
                imeAction = ImeAction.Go
            ),
            keyboardActions = KeyboardActions(
                onGo = { if (hasUrl) onImport() }
            ),
            singleLine = true,
            enabled = !isLoading,
            shape = RoundedCornerShape(24.dp),
            colors = OutlinedTextFieldDefaults.colors(
                unfocusedContainerColor = MaterialTheme.colorScheme.surfaceVariant,
                focusedContainerColor = MaterialTheme.colorScheme.surfaceVariant
            )
        )

        Spacer(modifier = Modifier.width(Spacing.sm))

        // Dynamic action button
        Box {
            IconButton(
                onClick = {
                    when {
                        isLoading -> { /* Do nothing */ }
                        hasUrl -> onImport()
                        else -> onShowMediaMenu()
                    }
                },
                modifier = Modifier
                    .size(48.dp)
                    .clip(CircleShape)
                    .background(MaterialTheme.colorScheme.primary),
                enabled = !isLoading
            ) {
                Icon(
                    imageVector = if (hasUrl) Icons.AutoMirrored.Filled.ArrowForward else Icons.Default.Add,
                    contentDescription = if (hasUrl) stringResource(R.string.import_recipe) else stringResource(R.string.add_media),
                    tint = MaterialTheme.colorScheme.onPrimary
                )
            }

            // Media menu dropdown
            DropdownMenu(
                expanded = showMediaMenu,
                onDismissRequest = onDismissMediaMenu
            ) {
                DropdownMenuItem(
                    text = { Text(stringResource(R.string.photo_library)) },
                    onClick = onSelectPhoto,
                    leadingIcon = { Icon(Icons.Default.PhotoLibrary, contentDescription = null) }
                )
                DropdownMenuItem(
                    text = { Text(stringResource(R.string.take_photo)) },
                    onClick = onTakePhoto,
                    leadingIcon = { Icon(Icons.Default.CameraAlt, contentDescription = null) }
                )
                DropdownMenuItem(
                    text = { Text(stringResource(R.string.import_pdf)) },
                    onClick = onSelectPdf,
                    leadingIcon = { Icon(Icons.Default.Description, contentDescription = null) }
                )
            }
        }
    }
}

@Composable
private fun PlatformIconsRow() {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(start = Spacing.lg),
        horizontalArrangement = Arrangement.spacedBy(Spacing.md)
    ) {
        Text(
            text = "YouTube",
            style = MaterialTheme.typography.labelSmall,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )
        Text(
            text = "TikTok",
            style = MaterialTheme.typography.labelSmall,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )
        Text(
            text = "Instagram",
            style = MaterialTheme.typography.labelSmall,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )
        Text(
            text = stringResource(R.string.websites),
            style = MaterialTheme.typography.labelSmall,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )
    }
}

@Composable
private fun TimestampInputSection(
    startTimestamp: String,
    onStartChange: (String) -> Unit,
    endTimestamp: String,
    onEndChange: (String) -> Unit,
    platformName: String?,
    modifier: Modifier = Modifier
) {
    Card(
        modifier = modifier.fillMaxWidth(),
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.surfaceVariant
        ),
        shape = RoundedCornerShape(CornerRadius.card)
    ) {
        Column(
            modifier = Modifier.padding(Spacing.lg)
        ) {
            // Header
            Row(
                verticalAlignment = Alignment.CenterVertically
            ) {
                Icon(
                    Icons.Default.Videocam,
                    contentDescription = null,
                    tint = MaterialTheme.colorScheme.primary,
                    modifier = Modifier.size(20.dp)
                )
                Spacer(modifier = Modifier.width(Spacing.sm))
                Text(
                    text = platformName?.let { "$it Video" } ?: "Video",
                    style = MaterialTheme.typography.titleSmall,
                    fontWeight = FontWeight.Medium
                )
            }

            Spacer(modifier = Modifier.height(Spacing.sm))

            Text(
                text = stringResource(R.string.timestamp_hint),
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )

            Spacer(modifier = Modifier.height(Spacing.md))

            // Timestamp inputs
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(Spacing.lg)
            ) {
                TimestampField(
                    label = stringResource(R.string.start),
                    placeholder = "0:00",
                    value = startTimestamp,
                    onValueChange = onStartChange,
                    modifier = Modifier.weight(1f)
                )
                TimestampField(
                    label = stringResource(R.string.end),
                    placeholder = stringResource(R.string.end_of_video),
                    value = endTimestamp,
                    onValueChange = onEndChange,
                    modifier = Modifier.weight(1f)
                )
            }
        }
    }
}

@Composable
private fun TimestampField(
    label: String,
    placeholder: String,
    value: String,
    onValueChange: (String) -> Unit,
    modifier: Modifier = Modifier
) {
    Column(modifier = modifier) {
        Text(
            text = label,
            style = MaterialTheme.typography.labelSmall,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )
        Spacer(modifier = Modifier.height(Spacing.xs))
        OutlinedTextField(
            value = value,
            onValueChange = onValueChange,
            placeholder = { Text(placeholder, style = MaterialTheme.typography.bodySmall) },
            keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
            singleLine = true,
            modifier = Modifier.fillMaxWidth(),
            textStyle = MaterialTheme.typography.bodyMedium
        )
    }
}

@Composable
private fun ImportStatusSection(
    isLoading: Boolean,
    currentStep: ImportStep?,
    error: String?,
    importedRecipeName: String?,
    stepsCount: Int?,
    ingredientsCount: Int?
) {
    when {
        isLoading && currentStep != null -> {
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(vertical = Spacing.xxl),
                contentAlignment = Alignment.Center
            ) {
                ImportProgressView(currentStep = currentStep)
            }
        }
        error != null -> {
            Card(
                modifier = Modifier.fillMaxWidth(),
                colors = CardDefaults.cardColors(
                    containerColor = MaterialTheme.colorScheme.errorContainer
                )
            ) {
                Row(
                    modifier = Modifier.padding(Spacing.lg),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Icon(
                        Icons.Default.Error,
                        contentDescription = null,
                        tint = MaterialTheme.colorScheme.error
                    )
                    Spacer(modifier = Modifier.width(Spacing.md))
                    Column {
                        Text(
                            text = stringResource(R.string.import_failed),
                            style = MaterialTheme.typography.titleSmall,
                            fontWeight = FontWeight.Medium,
                            color = MaterialTheme.colorScheme.onErrorContainer
                        )
                        Text(
                            text = error,
                            style = MaterialTheme.typography.bodySmall,
                            color = MaterialTheme.colorScheme.onErrorContainer
                        )
                    }
                }
            }
        }
        importedRecipeName != null -> {
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(vertical = Spacing.xxl),
                horizontalAlignment = Alignment.CenterHorizontally
            ) {
                Icon(
                    Icons.Default.CheckCircle,
                    contentDescription = null,
                    modifier = Modifier.size(80.dp),
                    tint = MaterialTheme.colorScheme.primary
                )
                Spacer(modifier = Modifier.height(Spacing.lg))
                Text(
                    text = stringResource(R.string.recipe_imported),
                    style = MaterialTheme.typography.titleLarge,
                    fontWeight = FontWeight.SemiBold
                )
                Spacer(modifier = Modifier.height(Spacing.sm))
                Text(
                    text = importedRecipeName,
                    style = MaterialTheme.typography.titleMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                    textAlign = TextAlign.Center
                )
                if (stepsCount != null && ingredientsCount != null) {
                    Spacer(modifier = Modifier.height(Spacing.md))
                    Row(
                        horizontalArrangement = Arrangement.spacedBy(Spacing.lg)
                    ) {
                        StatBadge(value = stepsCount, label = stringResource(R.string.steps))
                        StatBadge(value = ingredientsCount, label = stringResource(R.string.ingredients))
                    }
                }
            }
        }
    }
}

@Composable
private fun StatBadge(value: Int, label: String) {
    Column(horizontalAlignment = Alignment.CenterHorizontally) {
        Text(
            text = value.toString(),
            style = MaterialTheme.typography.titleMedium,
            fontWeight = FontWeight.Bold,
            color = MaterialTheme.colorScheme.primary
        )
        Text(
            text = label,
            style = MaterialTheme.typography.labelSmall,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )
    }
}

private fun formatTimestamp(newValue: String, oldValue: String): String {
    // Only auto-format if user is typing (not deleting)
    if (newValue.length <= oldValue.length) return newValue

    // Remove any non-digit/colon characters
    val cleaned = newValue.filter { it.isDigit() || it == ':' }

    // Auto-insert colon after 2 digits if no colon present
    return if (cleaned.length == 2 && !cleaned.contains(':')) {
        "$cleaned:"
    } else {
        cleaned
    }
}
