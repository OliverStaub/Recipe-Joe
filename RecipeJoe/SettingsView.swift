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
                } header: {
                    Text("Recipe Import")
                } footer: {
                    Text("Recipes will be imported and translated to \(userSettings.recipeLanguage.displayName).")
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
