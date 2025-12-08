//
//  SettingsView.swift
//  RecipeJoe
//
//  Created by Oliver Staub on 25.11.2025.
//

import SwiftUI

struct SettingsView: View {
    @ObservedObject private var userSettings = UserSettings.shared

    var body: some View {
        NavigationStack {
            List {
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
                        Label("Recipe Language", systemImage: "globe")
                    }

                    Toggle(isOn: $userSettings.keepOriginalWording) {
                        Label("Keep Original Wording", systemImage: "text.quote")
                    }
                } header: {
                    Text("Recipe Import")
                } footer: {
                    if userSettings.keepOriginalWording {
                        Text("Steps will be imported in their original language without rewording.")
                    } else {
                        Text("Recipes will be imported and translated to \(userSettings.recipeLanguage.displayName). This setting applies to future imports only.")
                    }
                }

                // MARK: - About Section
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text(Bundle.main.appVersion)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
}

// MARK: - Bundle Extension

extension Bundle {
    var appVersion: String {
        let version = infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }
}

#Preview {
    SettingsView()
}
