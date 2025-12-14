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
    @State private var showForgotPassword = false
    @FocusState private var focusedField: Field?

    enum Field {
        case email, password, confirmPassword
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
                VStack(spacing: 16) {
                    TextField("Email", text: $email)
                        .textFieldStyle(.roundedBorder)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                        .focused($focusedField, equals: .email)
                        .accessibilityIdentifier("emailTextField")

                    SecureField("Password", text: $password)
                        .textFieldStyle(.roundedBorder)
                        .textContentType(isSignUpMode ? .newPassword : .password)
                        .focused($focusedField, equals: .password)
                        .accessibilityIdentifier("passwordTextField")

                    if isSignUpMode {
                        SecureField("Confirm Password", text: $confirmPassword)
                            .textFieldStyle(.roundedBorder)
                            .textContentType(.newPassword)
                            .focused($focusedField, equals: .confirmPassword)
                            .accessibilityIdentifier("confirmPasswordTextField")
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

                    // Forgot password (only in sign in mode)
                    if !isSignUpMode {
                        Button("Forgot Password?") {
                            showForgotPassword = true
                        }
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .accessibilityIdentifier("forgotPasswordButton")
                    }
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
        .alert("Reset Password", isPresented: $showForgotPassword) {
            TextField("Email", text: $email)
                .textContentType(.emailAddress)
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
            Button("Cancel", role: .cancel) {}
            Button("Send Reset Link") {
                Task {
                    try? await authService.resetPassword(email: email)
                }
            }
        } message: {
            Text("Enter your email address and we'll send you a link to reset your password.")
        }
        .onChange(of: isSignUpMode) { _, _ in
            // Clear error when switching modes
            authService.errorMessage = nil
        }
    }

    private var isFormValid: Bool {
        let emailValid = !email.isEmpty && email.contains("@")
        let passwordValid = password.count >= 6

        if isSignUpMode {
            return emailValid && passwordValid && password == confirmPassword
        } else {
            return emailValid && passwordValid
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
