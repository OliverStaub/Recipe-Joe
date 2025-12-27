package com.recipejoe.presentation.home

import app.cash.turbine.test
import com.recipejoe.data.repository.RecipeRepository
import com.recipejoe.data.repository.TokenRepository
import com.recipejoe.domain.model.Recipe
import io.mockk.coEvery
import io.mockk.coVerify
import io.mockk.every
import io.mockk.mockk
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.flowOf
import kotlinx.coroutines.test.StandardTestDispatcher
import kotlinx.coroutines.test.resetMain
import kotlinx.coroutines.test.runTest
import kotlinx.coroutines.test.setMain
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Before
import org.junit.Test
import java.time.Instant
import java.util.UUID

@OptIn(ExperimentalCoroutinesApi::class)
class HomeViewModelTest {

    private lateinit var recipeRepository: RecipeRepository
    private lateinit var tokenRepository: TokenRepository
    private lateinit var viewModel: HomeViewModel

    private val testDispatcher = StandardTestDispatcher()

    private val testRecipe = Recipe(
        id = UUID.randomUUID(),
        userId = UUID.randomUUID(),
        name = "Test Recipe",
        author = "Test Author",
        description = "Test Description",
        prepTimeMinutes = 10,
        cookTimeMinutes = 20,
        totalTimeMinutes = 30,
        recipeYield = "4 servings",
        category = "Main Course",
        cuisine = "Italian",
        rating = 5,
        isFavorite = false,
        imageUrl = "https://example.com/image.jpg",
        sourceUrl = "https://example.com/recipe",
        keywords = listOf("pasta", "italian"),
        language = "en",
        createdAt = Instant.now(),
        updatedAt = Instant.now()
    )

    @Before
    fun setup() {
        Dispatchers.setMain(testDispatcher)
        recipeRepository = mockk(relaxed = true)
        tokenRepository = mockk(relaxed = true)

        every { recipeRepository.getRecipes() } returns flowOf(listOf(testRecipe))
        every { tokenRepository.tokenBalance } returns MutableStateFlow(10)
    }

    @After
    fun tearDown() {
        Dispatchers.resetMain()
    }

    @Test
    fun `recipes flow emits recipes from repository`() = runTest {
        viewModel = HomeViewModel(recipeRepository, tokenRepository)
        testDispatcher.scheduler.advanceUntilIdle()

        viewModel.recipes.test {
            val recipes = awaitItem()
            assertEquals(1, recipes.size)
            assertEquals("Test Recipe", recipes[0].name)
        }
    }

    @Test
    fun `refreshData calls repository refresh methods`() = runTest {
        coEvery { recipeRepository.refreshRecipes() } returns Unit
        coEvery { tokenRepository.refreshBalance() } returns 10

        viewModel = HomeViewModel(recipeRepository, tokenRepository)
        testDispatcher.scheduler.advanceUntilIdle()

        viewModel.refreshData()
        testDispatcher.scheduler.advanceUntilIdle()

        coVerify { recipeRepository.refreshRecipes() }
        coVerify { tokenRepository.refreshBalance() }
    }

    @Test
    fun `toggleFavorite updates recipe favorite status`() = runTest {
        coEvery { recipeRepository.updateFavorite(any(), any()) } returns Unit

        viewModel = HomeViewModel(recipeRepository, tokenRepository)
        testDispatcher.scheduler.advanceUntilIdle()

        viewModel.toggleFavorite(testRecipe)
        testDispatcher.scheduler.advanceUntilIdle()

        coVerify { recipeRepository.updateFavorite(testRecipe.id, true) }
    }

    @Test
    fun `deleteRecipe removes recipe from repository`() = runTest {
        coEvery { recipeRepository.deleteRecipe(any()) } returns Unit

        viewModel = HomeViewModel(recipeRepository, tokenRepository)
        testDispatcher.scheduler.advanceUntilIdle()

        viewModel.deleteRecipe(testRecipe)
        testDispatcher.scheduler.advanceUntilIdle()

        coVerify { recipeRepository.deleteRecipe(testRecipe.id) }
    }

    @Test
    fun `uiState starts with isRefreshing false`() = runTest {
        viewModel = HomeViewModel(recipeRepository, tokenRepository)
        testDispatcher.scheduler.advanceUntilIdle()

        viewModel.uiState.test {
            val state = awaitItem()
            assertFalse(state.isRefreshing)
        }
    }

    @Test
    fun `clearError clears error from uiState`() = runTest {
        viewModel = HomeViewModel(recipeRepository, tokenRepository)
        testDispatcher.scheduler.advanceUntilIdle()

        viewModel.clearError()
        testDispatcher.scheduler.advanceUntilIdle()

        viewModel.uiState.test {
            val state = awaitItem()
            assertEquals(null, state.error)
        }
    }
}
