package com.recipejoe.domain.model

import java.util.UUID

/**
 * Domain model for a user
 */
data class User(
    val id: UUID,
    val email: String?,
    val createdAt: String?
)

/**
 * Authentication state
 */
sealed class AuthState {
    data object Loading : AuthState()
    data object NotAuthenticated : AuthState()
    data class Authenticated(val user: User) : AuthState()
    data class Error(val message: String) : AuthState()
}
