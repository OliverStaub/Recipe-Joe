//
//  RecipeJoeApp.swift
//  RecipeJoe
//
//  Created by Oliver Staub on 23.11.2025.
//

import Kingfisher
import SwiftUI

@main
struct RecipeJoeApp: App {
    @ObservedObject private var userSettings = UserSettings.shared
    @ObservedObject private var authService = AuthenticationService.shared

    init() {
        configureImageCache()
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if authService.isLoading {
                    // Loading state while checking auth
                    ProgressView()
                } else if authService.isAuthenticated {
                    // User is authenticated - show main app
                    MainTabView()
                } else {
                    // User is not authenticated - show sign in
                    AuthenticationView()
                }
            }
            .environment(\.locale, userSettings.appLocale)
        }
    }

    private func configureImageCache() {
        // Configure Kingfisher cache for persistent image caching
        let cache = ImageCache.default

        // Memory cache: 100 MB
        cache.memoryStorage.config.totalCostLimit = 100 * 1024 * 1024

        // Disk cache: 500 MB, expires after 30 days
        cache.diskStorage.config.sizeLimit = 500 * 1024 * 1024
        cache.diskStorage.config.expiration = .days(30)
    }
}
