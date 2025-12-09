//
//  SettingsView.swift
//  RecipeJoe
//
//  Created by Oliver Staub on 25.11.2025.
//

import SwiftUI

struct SettingsView: View {
    @ObservedObject private var userSettings = UserSettings.shared
    @Environment(\.locale) private var locale

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
            }
            .navigationTitle("Settings".localized(for: locale))
        }
    }
}

#Preview {
    SettingsView()
}
