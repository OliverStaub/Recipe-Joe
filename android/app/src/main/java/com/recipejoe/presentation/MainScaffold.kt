package com.recipejoe.presentation

import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Home
import androidx.compose.material.icons.filled.Search
import androidx.compose.material.icons.outlined.Add
import androidx.compose.material.icons.outlined.Home
import androidx.compose.material.icons.outlined.Search
import androidx.compose.material3.Icon
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.res.stringResource
import com.recipejoe.R
import com.recipejoe.presentation.home.HomeScreen
import com.recipejoe.presentation.recipe.AddRecipeScreen
import com.recipejoe.presentation.search.SearchScreen
import java.util.UUID

sealed class BottomNavItem(
    val route: String,
    val titleResId: Int,
    val selectedIcon: ImageVector,
    val unselectedIcon: ImageVector
) {
    data object Home : BottomNavItem(
        route = "home",
        titleResId = R.string.home,
        selectedIcon = Icons.Filled.Home,
        unselectedIcon = Icons.Outlined.Home
    )
    data object AddRecipe : BottomNavItem(
        route = "add_recipe",
        titleResId = R.string.add_recipe,
        selectedIcon = Icons.Filled.Add,
        unselectedIcon = Icons.Outlined.Add
    )
    data object Search : BottomNavItem(
        route = "search",
        titleResId = R.string.search,
        selectedIcon = Icons.Filled.Search,
        unselectedIcon = Icons.Outlined.Search
    )
}

@Composable
fun MainScaffold(
    onNavigateToRecipe: (UUID) -> Unit,
    onNavigateToSettings: () -> Unit,
    onNavigateToBuyTokens: () -> Unit
) {
    val navItems = listOf(
        BottomNavItem.Home,
        BottomNavItem.AddRecipe,
        BottomNavItem.Search
    )

    var selectedIndex by rememberSaveable { mutableIntStateOf(0) }

    Scaffold(
        bottomBar = {
            NavigationBar {
                navItems.forEachIndexed { index, item ->
                    NavigationBarItem(
                        icon = {
                            Icon(
                                imageVector = if (selectedIndex == index) item.selectedIcon else item.unselectedIcon,
                                contentDescription = stringResource(item.titleResId)
                            )
                        },
                        label = { Text(stringResource(item.titleResId)) },
                        selected = selectedIndex == index,
                        onClick = { selectedIndex = index }
                    )
                }
            }
        }
    ) { paddingValues ->
        when (selectedIndex) {
            0 -> HomeScreen(
                onNavigateToRecipe = onNavigateToRecipe,
                onNavigateToSettings = onNavigateToSettings,
                modifier = Modifier.padding(paddingValues)
            )
            1 -> AddRecipeScreen(
                onNavigateToRecipe = { recipeId ->
                    // Switch to home tab and navigate to recipe
                    selectedIndex = 0
                    onNavigateToRecipe(recipeId)
                },
                onNavigateToBuyTokens = onNavigateToBuyTokens,
                modifier = Modifier.padding(paddingValues)
            )
            2 -> SearchScreen(
                onNavigateToRecipe = onNavigateToRecipe,
                modifier = Modifier.padding(paddingValues)
            )
        }
    }
}
