package com.recipejoe.presentation.navigation

import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.navigation.NavHostController
import androidx.navigation.NavType
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.navArgument
import com.recipejoe.domain.model.AuthState
import com.recipejoe.presentation.MainScaffold
import com.recipejoe.presentation.auth.AuthScreen
import com.recipejoe.presentation.auth.AuthViewModel
import com.recipejoe.presentation.recipe.RecipeDetailScreen
import com.recipejoe.presentation.settings.SettingsScreen
import com.recipejoe.presentation.tokens.BuyTokensScreen
import java.util.UUID

sealed class Screen(val route: String) {
    data object Auth : Screen("auth")
    data object Main : Screen("main")
    data object RecipeDetail : Screen("recipe/{recipeId}") {
        fun createRoute(recipeId: UUID) = "recipe/${recipeId}"
    }
    data object Settings : Screen("settings")
    data object BuyTokens : Screen("buy_tokens")
}

@Composable
fun NavGraph(
    navController: NavHostController,
    authViewModel: AuthViewModel = hiltViewModel()
) {
    val authState by authViewModel.authState.collectAsState()

    val startDestination = when (authState) {
        is AuthState.Authenticated -> Screen.Main.route
        is AuthState.Loading -> Screen.Auth.route
        else -> Screen.Auth.route
    }

    NavHost(
        navController = navController,
        startDestination = startDestination
    ) {
        composable(Screen.Auth.route) {
            AuthScreen()
        }

        composable(Screen.Main.route) {
            MainScaffold(
                onNavigateToRecipe = { recipeId ->
                    navController.navigate(Screen.RecipeDetail.createRoute(recipeId))
                },
                onNavigateToSettings = {
                    navController.navigate(Screen.Settings.route)
                },
                onNavigateToBuyTokens = {
                    navController.navigate(Screen.BuyTokens.route)
                }
            )
        }

        composable(
            route = Screen.RecipeDetail.route,
            arguments = listOf(
                navArgument("recipeId") { type = NavType.StringType }
            )
        ) {
            RecipeDetailScreen(
                onNavigateBack = { navController.popBackStack() }
            )
        }

        composable(Screen.Settings.route) {
            SettingsScreen(
                onNavigateBack = { navController.popBackStack() },
                onNavigateToBuyTokens = {
                    navController.navigate(Screen.BuyTokens.route)
                }
            )
        }

        composable(Screen.BuyTokens.route) {
            BuyTokensScreen(
                onNavigateBack = { navController.popBackStack() }
            )
        }
    }

    // Handle auth state changes
    when (authState) {
        is AuthState.Authenticated -> {
            if (navController.currentDestination?.route == Screen.Auth.route) {
                navController.navigate(Screen.Main.route) {
                    popUpTo(Screen.Auth.route) { inclusive = true }
                }
            }
        }
        is AuthState.NotAuthenticated -> {
            if (navController.currentDestination?.route != Screen.Auth.route) {
                navController.navigate(Screen.Auth.route) {
                    popUpTo(0) { inclusive = true }
                }
            }
        }
        else -> {}
    }
}
