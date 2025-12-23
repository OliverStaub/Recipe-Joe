//
//  AuthenticationView.swift
//  RecipeJoe
//
//  Sign in screen with Apple Sign In and Email/Password options
//

import AuthenticationServices
import SwiftUI

struct AuthenticationView: View {
    @ObservedObject private var authService = AuthenticationService.shared
    @Environment(\.colorScheme) private var colorScheme

    @State private var isSignUpMode = false
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @FocusState private var focusedField: Field?

    enum Field {
        case email, password, confirmPassword
    }

    // MARK: - Validation

    /// Validate email format (must match AuthenticationService validation)
    private var isValidEmail: Bool {
        let emailRegex = #"^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        return email.range(of: emailRegex, options: .regularExpression) != nil
    }

    private var isValidPassword: Bool {
        password.count >= 6
    }

    private var passwordsMatch: Bool {
        password == confirmPassword
    }

    /// Show email error only after user has typed something
    private var showEmailError: Bool {
        !email.isEmpty && !isValidEmail
    }

    /// Show password error only after user has started typing
    private var showPasswordError: Bool {
        !password.isEmpty && !isValidPassword
    }

    /// Show password mismatch error only after user has typed in confirm field
    private var showPasswordMismatchError: Bool {
        isSignUpMode && !confirmPassword.isEmpty && !passwordsMatch
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Spacer()
                    .frame(height: 40)

                // App branding
                VStack(spacing: 16) {
                    Image(systemName: "fork.knife.circle.fill")
                        .font(.system(size: 80))
                        .foregroundStyle(Color.terracotta)

                    Text("RecipeJoe")
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    Text(isSignUpMode ? "Create an account to start" : "Sign in to start importing your recipes")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }

                // Mode toggle
                Picker("", selection: $isSignUpMode) {
                    Text("Sign In").tag(false)
                    Text("Sign Up").tag(true)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 40)
                .accessibilityIdentifier("authModeToggle")

                // Email/Password form
                VStack(spacing: 12) {
                    // Email field
                    VStack(alignment: .leading, spacing: 4) {
                        TextField("Email", text: $email)
                            .textFieldStyle(.roundedBorder)
                            .textContentType(.emailAddress)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .autocorrectionDisabled()
                            .focused($focusedField, equals: .email)
                            .accessibilityIdentifier("emailTextField")

                        if showEmailError {
                            Text("Please enter a valid email address")
                                .font(.caption)
                                .foregroundStyle(.red)
                                .accessibilityIdentifier("emailValidationError")
                        }
                    }

                    // Password field
                    VStack(alignment: .leading, spacing: 4) {
                        SecureField("Password", text: $password)
                            .textFieldStyle(.roundedBorder)
                            .textContentType(isSignUpMode ? .newPassword : .password)
                            .focused($focusedField, equals: .password)
                            .accessibilityIdentifier("passwordTextField")

                        if showPasswordError {
                            Text("Password must be at least 6 characters")
                                .font(.caption)
                                .foregroundStyle(.red)
                                .accessibilityIdentifier("passwordValidationError")
                        }
                    }

                    // Confirm password field (sign up only)
                    if isSignUpMode {
                        VStack(alignment: .leading, spacing: 4) {
                            SecureField("Confirm Password", text: $confirmPassword)
                                .textFieldStyle(.roundedBorder)
                                .textContentType(.newPassword)
                                .focused($focusedField, equals: .confirmPassword)
                                .accessibilityIdentifier("confirmPasswordTextField")

                            if showPasswordMismatchError {
                                Text("Passwords do not match")
                                    .font(.caption)
                                    .foregroundStyle(.red)
                                    .accessibilityIdentifier("confirmPasswordValidationError")
                            }
                        }
                    }

                    // Submit button
                    Button {
                        Task {
                            await handleEmailAuth()
                        }
                    } label: {
                        Text(isSignUpMode ? "Create Account" : "Sign In")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.terracotta)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .disabled(!isFormValid)
                    .opacity(isFormValid ? 1 : 0.6)
                    .accessibilityIdentifier("emailAuthButton")
                }
                .padding(.horizontal, 40)

                // Error message
                if let errorMessage = authService.errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                        .accessibilityIdentifier("authErrorMessage")
                }

                // Divider
                HStack {
                    Rectangle()
                        .frame(height: 1)
                        .foregroundStyle(.secondary.opacity(0.3))
                    Text("or")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    Rectangle()
                        .frame(height: 1)
                        .foregroundStyle(.secondary.opacity(0.3))
                }
                .padding(.horizontal, 40)

                // Sign In with Apple button
                SignInWithAppleButton(
                    onRequest: { request in
                        request.requestedScopes = [.email, .fullName]
                    },
                    onCompletion: { result in
                        handleSignInResult(result)
                    }
                )
                .signInWithAppleButtonStyle(colorScheme == .dark ? .white : .black)
                .frame(height: 50)
                .padding(.horizontal, 40)
                .accessibilityIdentifier("signInWithAppleButton")

                Spacer()
                    .frame(height: 40)
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .overlay {
            if authService.isLoading {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(.white)
            }
        }
        .onChange(of: isSignUpMode) { _, _ in
            // Clear error when switching modes
            authService.errorMessage = nil
        }
    }

    private var isFormValid: Bool {
        if isSignUpMode {
            return isValidEmail && isValidPassword && passwordsMatch
        } else {
            return isValidEmail && isValidPassword
        }
    }

    private func handleEmailAuth() async {
        focusedField = nil

        do {
            if isSignUpMode {
                try await authService.signUp(email: email, password: password)
            } else {
                try await authService.signIn(email: email, password: password)
            }
        } catch {
            // Error is handled by authService.errorMessage
            print("Auth error: \(error)")
        }
    }

    private func handleSignInResult(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
                return
            }

            Task {
                do {
                    try await authService.signInWithApple(credential: appleIDCredential)
                } catch {
                    print("Sign in failed: \(error)")
                }
            }

        case .failure(let error):
            // User cancelled or other error
            if (error as NSError).code != ASAuthorizationError.canceled.rawValue {
                authService.errorMessage = error.localizedDescription
            }
        }
    }
}

#Preview {
    AuthenticationView()
}
