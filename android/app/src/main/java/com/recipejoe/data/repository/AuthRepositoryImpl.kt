package com.recipejoe.data.repository

import com.recipejoe.data.remote.SupabaseClientProvider
import com.recipejoe.domain.model.AuthState
import com.recipejoe.domain.model.User
import io.github.jan.supabase.auth.auth
import io.github.jan.supabase.auth.providers.Google
import io.github.jan.supabase.auth.providers.builtin.Email
import io.github.jan.supabase.auth.providers.builtin.IDToken
import io.github.jan.supabase.auth.status.SessionStatus
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map
import timber.log.Timber
import java.util.UUID
import javax.inject.Inject
import javax.inject.Singleton

interface AuthRepository {
    val authState: Flow<AuthState>
    val currentUserId: UUID?
    val currentUserEmail: String?
    val isAuthenticated: Boolean

    suspend fun signInWithGoogle(idToken: String)
    suspend fun signInWithEmail(email: String, password: String)
    suspend fun signUpWithEmail(email: String, password: String)
    suspend fun resetPassword(email: String)
    suspend fun signOut()
    suspend fun deleteAccount()
}

@Singleton
class AuthRepositoryImpl @Inject constructor(
    private val supabaseProvider: SupabaseClientProvider
) : AuthRepository {

    private val client get() = supabaseProvider.client
    private val auth get() = client.auth

    override val authState: Flow<AuthState> = auth.sessionStatus.map { status ->
        when (status) {
            is SessionStatus.Authenticated -> {
                val user = status.session.user
                if (user != null) {
                    AuthState.Authenticated(
                        User(
                            id = UUID.fromString(user.id),
                            email = user.email,
                            createdAt = user.createdAt?.toString()
                        )
                    )
                } else {
                    AuthState.NotAuthenticated
                }
            }
            is SessionStatus.NotAuthenticated -> AuthState.NotAuthenticated
            SessionStatus.Initializing -> AuthState.Loading
            is SessionStatus.RefreshFailure -> {
                Timber.e("Auth refresh failed: ${status.cause}")
                AuthState.NotAuthenticated
            }
        }
    }

    override val currentUserId: UUID?
        get() = auth.currentUserOrNull()?.id?.let { UUID.fromString(it) }

    override val currentUserEmail: String?
        get() = auth.currentUserOrNull()?.email

    override val isAuthenticated: Boolean
        get() = auth.currentUserOrNull() != null

    override suspend fun signInWithGoogle(idToken: String) {
        try {
            auth.signInWith(IDToken) {
                this.idToken = idToken
                provider = Google
            }
        } catch (e: Exception) {
            Timber.e(e, "Google sign in failed")
            throw AuthException.SignInFailed(e.message ?: "Google sign in failed")
        }
    }

    override suspend fun signInWithEmail(email: String, password: String) {
        try {
            auth.signInWith(Email) {
                this.email = email
                this.password = password
            }
        } catch (e: Exception) {
            Timber.e(e, "Email sign in failed")
            throw parseAuthError(e)
        }
    }

    override suspend fun signUpWithEmail(email: String, password: String) {
        try {
            auth.signUpWith(Email) {
                this.email = email
                this.password = password
            }

            // Check if email confirmation is required (user is not authenticated yet)
            if (auth.currentUserOrNull() == null) {
                throw AuthException.EmailConfirmationRequired
            }
        } catch (e: AuthException) {
            throw e
        } catch (e: Exception) {
            Timber.e(e, "Email sign up failed")
            throw parseAuthError(e)
        }
    }

    override suspend fun resetPassword(email: String) {
        try {
            auth.resetPasswordForEmail(email)
        } catch (e: Exception) {
            Timber.e(e, "Password reset failed")
            throw AuthException.ResetPasswordFailed(e.message ?: "Failed to send reset email")
        }
    }

    override suspend fun signOut() {
        try {
            auth.signOut()
        } catch (e: Exception) {
            Timber.e(e, "Sign out failed")
            throw e
        }
    }

    override suspend fun deleteAccount() {
        try {
            // Note: Full account deletion requires a server-side function
            // For now, just sign out
            auth.signOut()
        } catch (e: Exception) {
            Timber.e(e, "Delete account failed")
            throw e
        }
    }

    private fun parseAuthError(error: Exception): AuthException {
        val message = error.message?.lowercase() ?: ""

        return when {
            message.contains("email not confirmed") -> AuthException.EmailConfirmationRequired
            message.contains("invalid login credentials") ||
            message.contains("invalid credentials") -> AuthException.InvalidCredentials
            message.contains("user not found") -> AuthException.InvalidCredentials
            message.contains("too many requests") ||
            message.contains("rate limit") -> AuthException.RateLimited
            message.contains("user already registered") ||
            message.contains("already exists") -> AuthException.UserAlreadyExists
            message.contains("weak password") ||
            (message.contains("password") && message.contains("short")) -> AuthException.WeakPassword
            message.contains("invalid email") -> AuthException.InvalidEmail
            else -> AuthException.SignInFailed(error.message ?: "Authentication failed")
        }
    }
}

sealed class AuthException : Exception() {
    data object InvalidEmail : AuthException() {
        private fun readResolve(): Any = InvalidEmail
        override val message = "Please enter a valid email address"
    }
    data object WeakPassword : AuthException() {
        private fun readResolve(): Any = WeakPassword
        override val message = "Password must be at least 6 characters"
    }
    data object InvalidCredentials : AuthException() {
        private fun readResolve(): Any = InvalidCredentials
        override val message = "Invalid email or password"
    }
    data object EmailConfirmationRequired : AuthException() {
        private fun readResolve(): Any = EmailConfirmationRequired
        override val message = "Please check your email to confirm your account"
    }
    data object UserAlreadyExists : AuthException() {
        private fun readResolve(): Any = UserAlreadyExists
        override val message = "An account with this email already exists"
    }
    data object RateLimited : AuthException() {
        private fun readResolve(): Any = RateLimited
        override val message = "Too many attempts. Please try again later"
    }
    data class SignInFailed(override val message: String) : AuthException()
    data class ResetPasswordFailed(override val message: String) : AuthException()
}
