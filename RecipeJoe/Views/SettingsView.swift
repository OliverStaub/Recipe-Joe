//
//  SettingsView.swift
//  RecipeJoe
//
//  Created by Oliver Staub on 25.11.2025.
//

import SwiftUI

struct SettingsView: View {
    @ObservedObject private var userSettings = UserSettings.shared
    @ObservedObject private var authService = AuthenticationService.shared
    @Environment(\.locale) private var locale
    @State private var showSignOutConfirmation = false
    @State private var showDeleteAccountConfirmation = false

    var body: some View {
        NavigationStack {
            List {
                // MARK: - App Language Section
                Section {
                    Picker(selection: $userSettings.appLanguage) {
                        ForEach(AppLanguage.allCases) { language in
                            HStack {
                                Text(language.flag)
                                Text(language.displayName)
                            }
                            .tag(language)
                        }
                    } label: {
                        Label("App Language".localized(for: locale), systemImage: "globe")
                    }
                } header: {
                    Text("Language".localized(for: locale))
                } footer: {
                    Text("Choose the language for the app interface.".localized(for: locale))
                }

                // MARK: - Recipe Import Section
                Section {
                    Picker(selection: $userSettings.recipeLanguage) {
                        ForEach(RecipeLanguage.allCases) { language in
                            HStack {
                                Text(language.flag)
                                Text(language.displayName)
                            }
                            .tag(language)
                        }
                    } label: {
                        Label("Recipe Language".localized(for: locale), systemImage: "doc.text")
                    }

                    Toggle(isOn: $userSettings.keepOriginalWording) {
                        Label("Keep Original Wording".localized(for: locale), systemImage: "text.quote")
                    }
                } header: {
                    Text("Recipe Import".localized(for: locale))
                } footer: {
                    if userSettings.keepOriginalWording {
                        Text("Steps will be imported in their original language without rewording.".localized(for: locale))
                    } else {
                        // For interpolated strings, we need a different approach
                        let template = "Recipes will be imported and translated to %@. This setting applies to future imports only."
                        Text(String(format: template.localized(for: locale), userSettings.recipeLanguage.displayName))
                    }
                }

                // MARK: - About Section
                Section("About".localized(for: locale)) {
                    HStack {
                        Text("Version".localized(for: locale))
                        Spacer()
                        Text(Bundle.main.appVersion)
                            .foregroundStyle(.secondary)
                    }
                }

                // MARK: - Account Section
                Section("Account".localized(for: locale)) {
                    // User info
                    if let email = authService.currentUserEmail {
                        HStack {
                            Label("Signed in as".localized(for: locale), systemImage: "person.circle")
                            Spacer()
                            Text(email)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                    } else {
                        HStack {
                            Label("Signed in".localized(for: locale), systemImage: "person.circle")
                            Spacer()
                            Text("Apple ID")
                                .foregroundStyle(.secondary)
                        }
                    }

                    // Sign Out button
                    Button {
                        showSignOutConfirmation = true
                    } label: {
                        Label("Sign Out".localized(for: locale), systemImage: "rectangle.portrait.and.arrow.right")
                    }
                    .accessibilityIdentifier("signOutButton")

                    // Delete Account button
                    Button(role: .destructive) {
                        showDeleteAccountConfirmation = true
                    } label: {
                        Label("Delete Account".localized(for: locale), systemImage: "trash")
                    }
                    .accessibilityIdentifier("deleteAccountButton")
                }
            }
            .navigationTitle("Settings".localized(for: locale))
            .alert(
                "Sign Out".localized(for: locale),
                isPresented: $showSignOutConfirmation
            ) {
                Button("Cancel".localized(for: locale), role: .cancel) {}
                Button("Sign Out".localized(for: locale), role: .destructive) {
                    Task {
                        try? await authService.signOut()
                    }
                }
            } message: {
                Text("Are you sure you want to sign out?".localized(for: locale))
            }
            .alert(
                "Delete Account".localized(for: locale),
                isPresented: $showDeleteAccountConfirmation
            ) {
                Button("Cancel".localized(for: locale), role: .cancel) {}
                Button("Delete Account".localized(for: locale), role: .destructive) {
                    Task {
                        try? await authService.deleteAccount()
                    }
                }
            } message: {
                Text("This will permanently delete your account and all your recipes. This action cannot be undone.".localized(for: locale))
            }
        }
    }
}

#Preview {
    SettingsView()
}
