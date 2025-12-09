//
//  RecipeJoeApp.swift
//  RecipeJoe
//
//  Created by Oliver Staub on 23.11.2025.
//

import SwiftUI

@main
struct RecipeJoeApp: App {
    @ObservedObject private var userSettings = UserSettings.shared

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environment(\.locale, userSettings.appLocale)
        }
    }
}
