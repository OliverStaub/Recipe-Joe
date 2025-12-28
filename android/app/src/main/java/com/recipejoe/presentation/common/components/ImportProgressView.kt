package com.recipejoe.presentation.common.components

import androidx.compose.animation.core.LinearEasing
import androidx.compose.animation.core.animateFloat
import androidx.compose.animation.core.infiniteRepeatable
import androidx.compose.animation.core.rememberInfiniteTransition
import androidx.compose.animation.core.tween
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Restaurant
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.rotate
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import com.recipejoe.R
import com.recipejoe.presentation.theme.Spacing

enum class ImportStep {
    FETCHING,
    FETCHING_TRANSCRIPT,
    UPLOADING,
    RECOGNIZING,
    PARSING,
    EXTRACTING,
    SAVING
}

@Composable
fun ImportProgressView(
    currentStep: ImportStep,
    modifier: Modifier = Modifier
) {
    val infiniteTransition = rememberInfiniteTransition(label = "rotation")
    val rotation by infiniteTransition.animateFloat(
        initialValue = 0f,
        targetValue = 360f,
        animationSpec = infiniteRepeatable(
            animation = tween(durationMillis = 2000, easing = LinearEasing)
        ),
        label = "rotation"
    )

    val stepTitle = when (currentStep) {
        ImportStep.FETCHING -> stringResource(R.string.import_step_fetching)
        ImportStep.FETCHING_TRANSCRIPT -> stringResource(R.string.import_step_transcript)
        ImportStep.UPLOADING -> stringResource(R.string.import_step_uploading)
        ImportStep.RECOGNIZING -> stringResource(R.string.import_step_recognizing)
        ImportStep.PARSING -> stringResource(R.string.import_step_parsing)
        ImportStep.EXTRACTING -> stringResource(R.string.import_step_extracting)
        ImportStep.SAVING -> stringResource(R.string.import_step_saving)
    }

    val showHint = currentStep in listOf(
        ImportStep.RECOGNIZING,
        ImportStep.PARSING,
        ImportStep.EXTRACTING
    )

    Column(
        modifier = modifier
            .fillMaxWidth()
            .padding(Spacing.xl),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        // Spinning fork icon
        Icon(
            imageVector = Icons.Default.Restaurant,
            contentDescription = null,
            modifier = Modifier
                .size(80.dp)
                .rotate(rotation),
            tint = MaterialTheme.colorScheme.primary
        )

        Spacer(modifier = Modifier.height(Spacing.lg))

        // Step indicator text
        Text(
            text = stepTitle,
            style = MaterialTheme.typography.titleMedium,
            color = MaterialTheme.colorScheme.primary
        )

        // Hint that user can leave
        if (showHint) {
            Spacer(modifier = Modifier.height(Spacing.md))
            Text(
                text = stringResource(R.string.import_hint_can_leave),
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                textAlign = TextAlign.Center
            )
        }
    }
}
