package com.recipejoe.presentation.theme

import androidx.compose.ui.unit.dp

/**
 * Spacing scale matching iOS design guidelines:
 * xs = 4pt, sm = 8pt, md = 12pt, lg = 16pt, xl = 24pt, 2xl = 40pt
 */
object Spacing {
    val xs = 4.dp    // Icon-text gaps, minimal spacing
    val sm = 8.dp    // Badges, compact elements, button padding
    val md = 12.dp   // Section internals, row spacing
    val lg = 16.dp   // Content padding, standard spacing
    val xl = 24.dp   // Section spacing, major separations
    val xxl = 40.dp  // Form horizontal padding
}

/**
 * Corner radius scale matching iOS design guidelines:
 * 8pt (small badges), 10pt (buttons), 12pt (cards), 16pt (large containers)
 */
object CornerRadius {
    val small = 8.dp   // Small badges, thumbnails
    val button = 10.dp // Buttons
    val card = 12.dp   // Cards, section containers
    val large = 16.dp  // Large containers, header images
}

/**
 * Touch target sizes matching iOS design guidelines:
 * Minimum 48pt for all interactive elements
 */
object TouchTarget {
    val minimum = 48.dp
    val buttonHeight = 50.dp
}
