//
//  DataController.swift
//  RecipeJoe
//
//  Created by Oliver Staub on 25.11.2025.
//

import Foundation
import SwiftData

/// Configures and provides the SwiftData ModelContainer with CloudKit sync
enum DataController {
    /// Whether CloudKit sync is enabled
    /// Set to true once you've added the iCloud capability in Xcode
    private static let cloudKitEnabled = false

    /// Shared ModelContainer for the app
    /// Uses CloudKit for sync with private database when enabled
    static let sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Recipe.self
        ])

        // Use CloudKit if enabled, otherwise local-only storage
        let modelConfiguration: ModelConfiguration
        if cloudKitEnabled {
            modelConfiguration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                cloudKitDatabase: .private("iCloud.Oliver.RecipeJoe")
            )
        } else {
            // Local-only storage until CloudKit capability is added
            modelConfiguration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                cloudKitDatabase: .none
            )
        }

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    /// Preview container for SwiftUI previews (in-memory, no CloudKit)
    static let previewContainer: ModelContainer = {
        let schema = Schema([
            Recipe.self
        ])

        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true,
            cloudKitDatabase: .none
        )

        do {
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])

            // Add sample data for previews
            let context = container.mainContext
            let sampleRecipe = Recipe(
                name: "Sample Pasta",
                author: "Chef Joe",
                dateCreated: Date(),
                dateModified: Date(),
                prepTime: 15,
                cookTime: 20,
                totalTime: 35,
                recipeYield: "4 servings",
                recipeCategory: "Dinner",
                recipeCuisine: "Italian",
                keywords: ["pasta", "quick", "easy"],
                ingredientsList: ["pasta", "tomatoes", "garlic", "olive oil"],
                rating: 4,
                isFavorite: true,
                recipeData: "{}"
            )
            context.insert(sampleRecipe)

            return container
        } catch {
            fatalError("Could not create preview ModelContainer: \(error)")
        }
    }()
}
