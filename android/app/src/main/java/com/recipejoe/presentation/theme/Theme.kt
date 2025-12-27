package com.recipejoe.presentation.theme

import android.os.Build
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.dynamicDarkColorScheme
import androidx.compose.material3.dynamicLightColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext

// Terracotta brand color
val Terracotta = Color(0xFFC65D00)
val TerracottaDark = Color(0xFFA04D00)
val TerracottaLight = Color(0xFFFF8A3D)

// Light theme colors
private val LightColorScheme = lightColorScheme(
    primary = Terracotta,
    onPrimary = Color.White,
    primaryContainer = Color(0xFFFFDBCC),
    onPrimaryContainer = Color(0xFF2D1600),
    secondary = Color(0xFF765849),
    onSecondary = Color.White,
    secondaryContainer = Color(0xFFFFDBCC),
    onSecondaryContainer = Color(0xFF2C160B),
    tertiary = Color(0xFF626033),
    onTertiary = Color.White,
    tertiaryContainer = Color(0xFFE9E5AC),
    onTertiaryContainer = Color(0xFF1D1D00),
    error = Color(0xFFBA1A1A),
    onError = Color.White,
    errorContainer = Color(0xFFFFDAD6),
    onErrorContainer = Color(0xFF410002),
    background = Color(0xFFFFFBFF),
    onBackground = Color(0xFF201A17),
    surface = Color(0xFFFFFBFF),
    onSurface = Color(0xFF201A17),
    surfaceVariant = Color(0xFFF4DED4),
    onSurfaceVariant = Color(0xFF52443C),
    outline = Color(0xFF85746B),
    outlineVariant = Color(0xFFD7C2B8)
)

// Dark theme colors
private val DarkColorScheme = darkColorScheme(
    primary = Color(0xFFFFB690),
    onPrimary = Color(0xFF4D2600),
    primaryContainer = Color(0xFF6E3900),
    onPrimaryContainer = Color(0xFFFFDBCC),
    secondary = Color(0xFFE6BEAC),
    onSecondary = Color(0xFF44291E),
    secondaryContainer = Color(0xFF5D3F33),
    onSecondaryContainer = Color(0xFFFFDBCC),
    tertiary = Color(0xFFCDC992),
    onTertiary = Color(0xFF333209),
    tertiaryContainer = Color(0xFF4A481E),
    onTertiaryContainer = Color(0xFFE9E5AC),
    error = Color(0xFFFFB4AB),
    onError = Color(0xFF690005),
    errorContainer = Color(0xFF93000A),
    onErrorContainer = Color(0xFFFFB4AB),
    background = Color(0xFF201A17),
    onBackground = Color(0xFFECE0DA),
    surface = Color(0xFF201A17),
    onSurface = Color(0xFFECE0DA),
    surfaceVariant = Color(0xFF52443C),
    onSurfaceVariant = Color(0xFFD7C2B8),
    outline = Color(0xFF9F8D84),
    outlineVariant = Color(0xFF52443C)
)

@Composable
fun RecipeJoeTheme(
    darkTheme: Boolean = isSystemInDarkTheme(),
    dynamicColor: Boolean = false, // Disabled to keep brand colors
    content: @Composable () -> Unit
) {
    val colorScheme = when {
        dynamicColor && Build.VERSION.SDK_INT >= Build.VERSION_CODES.S -> {
            val context = LocalContext.current
            if (darkTheme) dynamicDarkColorScheme(context) else dynamicLightColorScheme(context)
        }
        darkTheme -> DarkColorScheme
        else -> LightColorScheme
    }

    MaterialTheme(
        colorScheme = colorScheme,
        typography = Typography,
        content = content
    )
}
