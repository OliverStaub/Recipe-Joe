package com.recipejoe.presentation.auth

import app.cash.turbine.test
import com.recipejoe.data.repository.AuthException
import com.recipejoe.data.repository.AuthRepository
import com.recipejoe.domain.model.AuthState
import com.recipejoe.domain.model.User
import io.mockk.coEvery
import io.mockk.coVerify
import io.mockk.every
import io.mockk.mockk
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.test.StandardTestDispatcher
import kotlinx.coroutines.test.resetMain
import kotlinx.coroutines.test.runTest
import kotlinx.coroutines.test.setMain
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import java.util.UUID

@OptIn(ExperimentalCoroutinesApi::class)
class AuthViewModelTest {

    private lateinit var authRepository: AuthRepository
    private lateinit var viewModel: AuthViewModel

    private val testDispatcher = StandardTestDispatcher()
    private val authStateFlow = MutableStateFlow<AuthState>(AuthState.NotAuthenticated)

    private val testUser = User(
        id = UUID.randomUUID(),
        email = "test@example.com",
        createdAt = null
    )

    @Before
    fun setup() {
        Dispatchers.setMain(testDispatcher)
        authRepository = mockk(relaxed = true)
        every { authRepository.authState } returns authStateFlow
    }

    @After
    fun tearDown() {
        Dispatchers.resetMain()
    }

    @Test
    fun `signInWithGoogle calls repository and handles success`() = runTest {
        coEvery { authRepository.signInWithGoogle(any()) } answers {
            authStateFlow.value = AuthState.Authenticated(testUser)
        }

        viewModel = AuthViewModel(authRepository)
        testDispatcher.scheduler.advanceUntilIdle()

        viewModel.signInWithGoogle("test-id-token")
        testDispatcher.scheduler.advanceUntilIdle()

        coVerify { authRepository.signInWithGoogle("test-id-token") }
    }

    @Test
    fun `signInWithEmail with invalid email shows error`() = runTest {
        viewModel = AuthViewModel(authRepository)
        testDispatcher.scheduler.advanceUntilIdle()

        viewModel.signInWithEmail("invalid-email", "password123")
        testDispatcher.scheduler.advanceUntilIdle()

        viewModel.uiState.test {
            val state = awaitItem()
            assertEquals("Please enter a valid email address", state.error)
        }
    }

    @Test
    fun `signInWithEmail with valid credentials calls repository`() = runTest {
        coEvery { authRepository.signInWithEmail(any(), any()) } answers {
            authStateFlow.value = AuthState.Authenticated(testUser)
        }

        viewModel = AuthViewModel(authRepository)
        testDispatcher.scheduler.advanceUntilIdle()

        viewModel.signInWithEmail("test@example.com", "password123")
        testDispatcher.scheduler.advanceUntilIdle()

        coVerify { authRepository.signInWithEmail("test@example.com", "password123") }
    }

    @Test
    fun `signUpWithEmail with weak password shows error`() = runTest {
        viewModel = AuthViewModel(authRepository)
        testDispatcher.scheduler.advanceUntilIdle()

        viewModel.signUpWithEmail("test@example.com", "12345")
        testDispatcher.scheduler.advanceUntilIdle()

        viewModel.uiState.test {
            val state = awaitItem()
            assertEquals("Password must be at least 6 characters", state.error)
        }
    }

    @Test
    fun `signUpWithEmail with valid data calls repository`() = runTest {
        coEvery { authRepository.signUpWithEmail(any(), any()) } answers {
            authStateFlow.value = AuthState.Authenticated(testUser)
        }

        viewModel = AuthViewModel(authRepository)
        testDispatcher.scheduler.advanceUntilIdle()

        viewModel.signUpWithEmail("test@example.com", "password123")
        testDispatcher.scheduler.advanceUntilIdle()

        coVerify { authRepository.signUpWithEmail("test@example.com", "password123") }
    }

    @Test
    fun `signUpWithEmail handles email confirmation required`() = runTest {
        coEvery { authRepository.signUpWithEmail(any(), any()) } throws AuthException.EmailConfirmationRequired

        viewModel = AuthViewModel(authRepository)
        testDispatcher.scheduler.advanceUntilIdle()

        viewModel.signUpWithEmail("test@example.com", "password123")
        testDispatcher.scheduler.advanceUntilIdle()

        viewModel.uiState.test {
            val state = awaitItem()
            assertTrue(state.showEmailConfirmation)
        }
    }

    @Test
    fun `resetPassword with valid email calls repository`() = runTest {
        coEvery { authRepository.resetPassword(any()) } returns Unit

        viewModel = AuthViewModel(authRepository)
        testDispatcher.scheduler.advanceUntilIdle()

        viewModel.resetPassword("test@example.com")
        testDispatcher.scheduler.advanceUntilIdle()

        coVerify { authRepository.resetPassword("test@example.com") }

        viewModel.uiState.test {
            val state = awaitItem()
            assertTrue(state.showResetEmailSent)
        }
    }

    @Test
    fun `clearError removes error from uiState`() = runTest {
        viewModel = AuthViewModel(authRepository)
        testDispatcher.scheduler.advanceUntilIdle()

        // Trigger an error
        viewModel.signInWithEmail("invalid", "pass")
        testDispatcher.scheduler.advanceUntilIdle()

        // Clear the error
        viewModel.clearError()
        testDispatcher.scheduler.advanceUntilIdle()

        viewModel.uiState.test {
            val state = awaitItem()
            assertNull(state.error)
        }
    }

    @Test
    fun `dismissEmailConfirmation sets showEmailConfirmation to false`() = runTest {
        coEvery { authRepository.signUpWithEmail(any(), any()) } throws AuthException.EmailConfirmationRequired

        viewModel = AuthViewModel(authRepository)
        testDispatcher.scheduler.advanceUntilIdle()

        viewModel.signUpWithEmail("test@example.com", "password123")
        testDispatcher.scheduler.advanceUntilIdle()

        viewModel.dismissEmailConfirmation()
        testDispatcher.scheduler.advanceUntilIdle()

        viewModel.uiState.test {
            val state = awaitItem()
            assertFalse(state.showEmailConfirmation)
        }
    }
}
