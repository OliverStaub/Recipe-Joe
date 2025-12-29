package com.recipejoe.presentation.auth

import android.app.Activity
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Email
import androidx.compose.material.icons.filled.Lock
import androidx.compose.material.icons.filled.Visibility
import androidx.compose.material.icons.filled.VisibilityOff
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.SnackbarHost
import androidx.compose.material3.SnackbarHostState
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.focus.FocusDirection
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalFocusManager
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.text.input.VisualTransformation
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import com.google.android.gms.auth.api.signin.GoogleSignIn
import com.google.android.gms.auth.api.signin.GoogleSignInOptions
import com.google.android.gms.common.api.ApiException
import com.recipejoe.BuildConfig
import com.recipejoe.R
import com.recipejoe.presentation.theme.Spacing
import com.recipejoe.presentation.theme.TouchTarget
import timber.log.Timber

@Composable
fun AuthScreen(
    viewModel: AuthViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()
    val snackbarHostState = remember { SnackbarHostState() }
    val context = LocalContext.current
    val focusManager = LocalFocusManager.current

    var email by rememberSaveable { mutableStateOf("") }
    var password by rememberSaveable { mutableStateOf("") }
    var passwordVisible by rememberSaveable { mutableStateOf(false) }
    var isSignUp by rememberSaveable { mutableStateOf(false) }
    var showForgotPassword by rememberSaveable { mutableStateOf(false) }

    // Google Sign-In launcher
    val googleSignInLauncher = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.StartActivityForResult()
    ) { result ->
        if (result.resultCode == Activity.RESULT_OK) {
            val task = GoogleSignIn.getSignedInAccountFromIntent(result.data)
            try {
                val account = task.getResult(ApiException::class.java)
                account.idToken?.let { idToken ->
                    viewModel.signInWithGoogle(idToken)
                }
            } catch (e: ApiException) {
                Timber.e(e, "Google sign in failed")
            }
        }
    }

    // Show error in snackbar
    LaunchedEffect(uiState.error) {
        uiState.error?.let { error ->
            snackbarHostState.showSnackbar(error)
            viewModel.clearError()
        }
    }

    Scaffold(
        snackbarHost = { SnackbarHost(snackbarHostState) }
    ) { paddingValues ->
        Box(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
        ) {
            Column(
                modifier = Modifier
                    .fillMaxSize()
                    .verticalScroll(rememberScrollState())
                    .padding(horizontal = Spacing.xxl),
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.Center
            ) {
                // Logo/Title
                Text(
                    text = "RecipeJoe",
                    style = MaterialTheme.typography.displayLarge,
                    color = MaterialTheme.colorScheme.primary
                )

                Spacer(modifier = Modifier.height(Spacing.sm))

                Text(
                    text = if (isSignUp) stringResource(R.string.create_account)
                           else stringResource(R.string.sign_in),
                    style = MaterialTheme.typography.headlineMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )

                Spacer(modifier = Modifier.height(Spacing.xl))

                // Google Sign-In Button
                OutlinedButton(
                    onClick = {
                        val gso = GoogleSignInOptions.Builder(GoogleSignInOptions.DEFAULT_SIGN_IN)
                            .requestIdToken(BuildConfig.GOOGLE_WEB_CLIENT_ID)
                            .requestEmail()
                            .build()
                        val googleSignInClient = GoogleSignIn.getClient(context, gso)
                        googleSignInLauncher.launch(googleSignInClient.signInIntent)
                    },
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(TouchTarget.buttonHeight),
                    enabled = !uiState.isLoading
                ) {
                    Text(stringResource(R.string.sign_in_with_google))
                }

                Spacer(modifier = Modifier.height(Spacing.xl))

                Text(
                    text = "or",
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )

                Spacer(modifier = Modifier.height(Spacing.xl))

                // Email field
                OutlinedTextField(
                    value = email,
                    onValueChange = { email = it },
                    label = { Text(stringResource(R.string.email)) },
                    leadingIcon = {
                        Icon(Icons.Default.Email, contentDescription = null)
                    },
                    keyboardOptions = KeyboardOptions(
                        keyboardType = KeyboardType.Email,
                        imeAction = ImeAction.Next
                    ),
                    keyboardActions = KeyboardActions(
                        onNext = { focusManager.moveFocus(FocusDirection.Down) }
                    ),
                    singleLine = true,
                    modifier = Modifier.fillMaxWidth(),
                    enabled = !uiState.isLoading
                )

                Spacer(modifier = Modifier.height(Spacing.md))

                // Password field
                OutlinedTextField(
                    value = password,
                    onValueChange = { password = it },
                    label = { Text(stringResource(R.string.password)) },
                    leadingIcon = {
                        Icon(Icons.Default.Lock, contentDescription = null)
                    },
                    trailingIcon = {
                        IconButton(onClick = { passwordVisible = !passwordVisible }) {
                            Icon(
                                if (passwordVisible) Icons.Default.VisibilityOff
                                else Icons.Default.Visibility,
                                contentDescription = null
                            )
                        }
                    },
                    visualTransformation = if (passwordVisible) VisualTransformation.None
                                           else PasswordVisualTransformation(),
                    keyboardOptions = KeyboardOptions(
                        keyboardType = KeyboardType.Password,
                        imeAction = ImeAction.Done
                    ),
                    keyboardActions = KeyboardActions(
                        onDone = {
                            focusManager.clearFocus()
                            if (isSignUp) {
                                viewModel.signUpWithEmail(email, password)
                            } else {
                                viewModel.signInWithEmail(email, password)
                            }
                        }
                    ),
                    singleLine = true,
                    modifier = Modifier.fillMaxWidth(),
                    enabled = !uiState.isLoading
                )

                if (!isSignUp) {
                    TextButton(
                        onClick = { showForgotPassword = true },
                        modifier = Modifier.align(Alignment.End)
                    ) {
                        Text(stringResource(R.string.forgot_password))
                    }
                }

                Spacer(modifier = Modifier.height(Spacing.lg))

                // Sign In / Sign Up Button
                Button(
                    onClick = {
                        focusManager.clearFocus()
                        if (isSignUp) {
                            viewModel.signUpWithEmail(email, password)
                        } else {
                            viewModel.signInWithEmail(email, password)
                        }
                    },
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(TouchTarget.buttonHeight),
                    enabled = !uiState.isLoading && email.isNotBlank() && password.isNotBlank()
                ) {
                    if (uiState.isLoading) {
                        CircularProgressIndicator(
                            modifier = Modifier.size(24.dp),
                            color = MaterialTheme.colorScheme.onPrimary
                        )
                    } else {
                        Text(
                            if (isSignUp) stringResource(R.string.create_account)
                            else stringResource(R.string.sign_in)
                        )
                    }
                }

                Spacer(modifier = Modifier.height(Spacing.lg))

                // Toggle Sign In / Sign Up
                TextButton(
                    onClick = {
                        isSignUp = !isSignUp
                        viewModel.clearError()
                    }
                ) {
                    Text(
                        if (isSignUp) "Already have an account? Sign In"
                        else "Don't have an account? Create one"
                    )
                }
            }
        }
    }

    // Forgot Password Dialog
    if (showForgotPassword) {
        var resetEmail by remember { mutableStateOf(email) }

        AlertDialog(
            onDismissRequest = { showForgotPassword = false },
            title = { Text(stringResource(R.string.reset_password)) },
            text = {
                Column {
                    Text("Enter your email address and we'll send you a link to reset your password.")
                    Spacer(modifier = Modifier.height(Spacing.md))
                    OutlinedTextField(
                        value = resetEmail,
                        onValueChange = { resetEmail = it },
                        label = { Text(stringResource(R.string.email)) },
                        keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Email),
                        singleLine = true,
                        modifier = Modifier.fillMaxWidth()
                    )
                }
            },
            confirmButton = {
                Button(
                    onClick = {
                        viewModel.resetPassword(resetEmail)
                        showForgotPassword = false
                    }
                ) {
                    Text(stringResource(R.string.reset_password))
                }
            },
            dismissButton = {
                TextButton(onClick = { showForgotPassword = false }) {
                    Text(stringResource(R.string.cancel))
                }
            }
        )
    }

    // Email Confirmation Dialog
    if (uiState.showEmailConfirmation) {
        AlertDialog(
            onDismissRequest = { viewModel.dismissEmailConfirmation() },
            title = { Text(stringResource(R.string.check_email)) },
            text = {
                Text(
                    "We've sent a confirmation email to your address. Please check your inbox and click the link to verify your account.",
                    textAlign = TextAlign.Center
                )
            },
            confirmButton = {
                Button(onClick = { viewModel.dismissEmailConfirmation() }) {
                    Text("OK")
                }
            }
        )
    }

    // Reset Email Sent Dialog
    if (uiState.showResetEmailSent) {
        AlertDialog(
            onDismissRequest = { viewModel.dismissResetEmailSent() },
            title = { Text(stringResource(R.string.check_email)) },
            text = {
                Text(
                    "We've sent a password reset link to your email address.",
                    textAlign = TextAlign.Center
                )
            },
            confirmButton = {
                Button(onClick = { viewModel.dismissResetEmailSent() }) {
                    Text("OK")
                }
            }
        )
    }
}
