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
    @State private var deepLinkRecipeId: UUID?

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
                    MainTabView(deepLinkRecipeId: $deepLinkRecipeId)
                        .task {
                            // Refresh token balance from Supabase
                            try? await TokenService.shared.refreshBalance()
                        }
                } else {
                    // User is not authenticated - show sign in
                    AuthenticationView()
                }
            }
            .environment(\.locale, userSettings.appLocale)
            .onOpenURL { url in
                handleDeepLink(url)
            }
        }
    }

    /// Handle deep links for navigating to recipes
    /// URL format: recipejoe://recipe/{uuid}
    private func handleDeepLink(_ url: URL) {
        guard url.scheme == AppConstants.urlScheme else { return }

        let pathComponents = url.pathComponents.filter { $0 != "/" }

        if pathComponents.count >= 2,
           pathComponents[0] == "recipe",
           let recipeId = UUID(uuidString: pathComponents[1]) {
            deepLinkRecipeId = recipeId
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
