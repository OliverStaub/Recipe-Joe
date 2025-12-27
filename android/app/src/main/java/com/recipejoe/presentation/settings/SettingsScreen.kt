package com.recipejoe.presentation.settings

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.automirrored.filled.ExitToApp
import androidx.compose.material.icons.filled.DeleteForever
import androidx.compose.material.icons.filled.Person
import androidx.compose.material.icons.filled.ShoppingCart
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.ListItem
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.SnackbarHost
import androidx.compose.material3.SnackbarHostState
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.hilt.navigation.compose.hiltViewModel
import com.recipejoe.BuildConfig
import com.recipejoe.R
import com.recipejoe.domain.model.AuthState
import com.recipejoe.presentation.theme.CornerRadius
import com.recipejoe.presentation.theme.Spacing

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SettingsScreen(
    onNavigateBack: () -> Unit,
    onNavigateToBuyTokens: () -> Unit,
    viewModel: SettingsViewModel = hiltViewModel()
) {
    val authState by viewModel.authState.collectAsState()
    val tokenBalance by viewModel.tokenBalance.collectAsState()
    val uiState by viewModel.uiState.collectAsState()
    val snackbarHostState = remember { SnackbarHostState() }

    var showSignOutDialog by remember { mutableStateOf(false) }
    var showDeleteAccountDialog by remember { mutableStateOf(false) }

    LaunchedEffect(uiState.error) {
        uiState.error?.let { error ->
            snackbarHostState.showSnackbar(error)
            viewModel.clearError()
        }
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text(stringResource(R.string.settings)) },
                navigationIcon = {
                    IconButton(onClick = onNavigateBack) {
                        Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "Back")
                    }
                }
            )
        },
        snackbarHost = { SnackbarHost(snackbarHostState) }
    ) { paddingValues ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
                .verticalScroll(rememberScrollState())
                .padding(Spacing.lg)
        ) {
            // Account section
            Text(
                text = stringResource(R.string.account),
                style = MaterialTheme.typography.titleSmall,
                color = MaterialTheme.colorScheme.primary
            )

            Spacer(modifier = Modifier.height(Spacing.sm))

            Card(
                modifier = Modifier.fillMaxWidth(),
                shape = androidx.compose.foundation.shape.RoundedCornerShape(CornerRadius.card)
            ) {
                Column {
                    // User info
                    if (authState is AuthState.Authenticated) {
                        ListItem(
                            headlineContent = { Text(stringResource(R.string.email)) },
                            supportingContent = {
                                Text(viewModel.userEmail ?: "")
                            },
                            leadingContent = {
                                Icon(Icons.Default.Person, contentDescription = null)
                            }
                        )
                        HorizontalDivider()
                    }

                    // Token balance
                    ListItem(
                        headlineContent = { Text(stringResource(R.string.token_balance)) },
                        supportingContent = {
                            Text(stringResource(R.string.tokens_remaining, tokenBalance))
                        },
                        leadingContent = {
                            Icon(Icons.Default.ShoppingCart, contentDescription = null)
                        },
                        modifier = Modifier.clickable { onNavigateToBuyTokens() }
                    )
                }
            }

            Spacer(modifier = Modifier.height(Spacing.xl))

            // Buy Tokens
            Card(
                modifier = Modifier
                    .fillMaxWidth()
                    .clickable { onNavigateToBuyTokens() },
                shape = androidx.compose.foundation.shape.RoundedCornerShape(CornerRadius.card),
                colors = CardDefaults.cardColors(
                    containerColor = MaterialTheme.colorScheme.primaryContainer
                )
            ) {
                ListItem(
                    headlineContent = {
                        Text(
                            stringResource(R.string.buy_tokens),
                            color = MaterialTheme.colorScheme.onPrimaryContainer
                        )
                    },
                    supportingContent = {
                        Text(
                            "Get more tokens to import recipes",
                            color = MaterialTheme.colorScheme.onPrimaryContainer.copy(alpha = 0.7f)
                        )
                    },
                    leadingContent = {
                        Icon(
                            Icons.Default.ShoppingCart,
                            contentDescription = null,
                            tint = MaterialTheme.colorScheme.onPrimaryContainer
                        )
                    }
                )
            }

            Spacer(modifier = Modifier.height(Spacing.xl))

            // Sign Out
            Text(
                text = "Actions",
                style = MaterialTheme.typography.titleSmall,
                color = MaterialTheme.colorScheme.primary
            )

            Spacer(modifier = Modifier.height(Spacing.sm))

            Card(
                modifier = Modifier.fillMaxWidth(),
                shape = androidx.compose.foundation.shape.RoundedCornerShape(CornerRadius.card)
            ) {
                Column {
                    ListItem(
                        headlineContent = { Text(stringResource(R.string.sign_out)) },
                        leadingContent = {
                            Icon(Icons.AutoMirrored.Filled.ExitToApp, contentDescription = null)
                        },
                        modifier = Modifier.clickable { showSignOutDialog = true }
                    )

                    HorizontalDivider()

                    ListItem(
                        headlineContent = {
                            Text(
                                stringResource(R.string.delete_account),
                                color = MaterialTheme.colorScheme.error
                            )
                        },
                        leadingContent = {
                            Icon(
                                Icons.Default.DeleteForever,
                                contentDescription = null,
                                tint = MaterialTheme.colorScheme.error
                            )
                        },
                        modifier = Modifier.clickable { showDeleteAccountDialog = true }
                    )
                }
            }

            Spacer(modifier = Modifier.height(Spacing.xl))

            // About section
            Text(
                text = stringResource(R.string.about),
                style = MaterialTheme.typography.titleSmall,
                color = MaterialTheme.colorScheme.primary
            )

            Spacer(modifier = Modifier.height(Spacing.sm))

            Card(
                modifier = Modifier.fillMaxWidth(),
                shape = androidx.compose.foundation.shape.RoundedCornerShape(CornerRadius.card)
            ) {
                Column {
                    ListItem(
                        headlineContent = { Text(stringResource(R.string.version, BuildConfig.VERSION_NAME)) }
                    )
                    HorizontalDivider()
                    ListItem(
                        headlineContent = { Text(stringResource(R.string.privacy_policy)) },
                        modifier = Modifier.clickable { /* TODO: Open privacy policy */ }
                    )
                    HorizontalDivider()
                    ListItem(
                        headlineContent = { Text(stringResource(R.string.terms_of_service)) },
                        modifier = Modifier.clickable { /* TODO: Open terms */ }
                    )
                }
            }
        }
    }

    // Sign out dialog
    if (showSignOutDialog) {
        AlertDialog(
            onDismissRequest = { showSignOutDialog = false },
            title = { Text(stringResource(R.string.sign_out)) },
            text = { Text("Are you sure you want to sign out?") },
            confirmButton = {
                TextButton(
                    onClick = {
                        viewModel.signOut()
                        showSignOutDialog = false
                    }
                ) {
                    Text(stringResource(R.string.sign_out))
                }
            },
            dismissButton = {
                TextButton(onClick = { showSignOutDialog = false }) {
                    Text(stringResource(R.string.cancel))
                }
            }
        )
    }

    // Delete account dialog
    if (showDeleteAccountDialog) {
        AlertDialog(
            onDismissRequest = { showDeleteAccountDialog = false },
            title = { Text(stringResource(R.string.delete_account)) },
            text = { Text(stringResource(R.string.delete_account_confirm)) },
            confirmButton = {
                TextButton(
                    onClick = {
                        viewModel.deleteAccount()
                        showDeleteAccountDialog = false
                    }
                ) {
                    Text(
                        stringResource(R.string.delete),
                        color = MaterialTheme.colorScheme.error
                    )
                }
            },
            dismissButton = {
                TextButton(onClick = { showDeleteAccountDialog = false }) {
                    Text(stringResource(R.string.cancel))
                }
            }
        )
    }
}
