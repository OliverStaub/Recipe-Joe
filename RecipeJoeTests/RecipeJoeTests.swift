//
//  RecipeJoeTests.swift
//  RecipeJoeTests
//
//  Created by Oliver Staub on 23.11.2025.
//

import Testing
import SwiftData
@testable import RecipeJoe

struct RecipeJoeTests {

    @Test func testRecipeInitialization() async throws {
        let recipe = Recipe(
            name: "Test Recipe",
            author: "Test Author",
            prepTime: 15,
            cookTime: 30,
            totalTime: 45,
            recipeYield: "4 servings",
            recipeCategory: "Dinner",
            recipeCuisine: "Italian",
            rating: 4,
            isFavorite: true
        )

        #expect(recipe.name == "Test Recipe")
        #expect(recipe.author == "Test Author")
        #expect(recipe.prepTime == 15)
        #expect(recipe.cookTime == 30)
        #expect(recipe.totalTime == 45)
        #expect(recipe.rating == 4)
        #expect(recipe.isFavorite == true)
    }

    @Test func testRecipeFormattedTimeMinutes() async throws {
        let recipe = Recipe(
            name: "Time Test",
            prepTime: 45,
            cookTime: 30,
            totalTime: 75
        )

        #expect(recipe.formattedPrepTime == "45 min")
        #expect(recipe.formattedCookTime == "30 min")
        #expect(recipe.formattedTotalTime == "1 hr 15 min")
    }

    @Test func testRecipeFormattedTimeHours() async throws {
        let recipe = Recipe(
            name: "Long Recipe",
            prepTime: 60,
            cookTime: 120,
            totalTime: 180
        )

        #expect(recipe.formattedPrepTime == "1 hr")
        #expect(recipe.formattedCookTime == "2 hr")
        #expect(recipe.formattedTotalTime == "3 hr")
    }

    @Test func testRecipeFormattedTimeZero() async throws {
        let recipe = Recipe(name: "Zero Time")

        #expect(recipe.formattedPrepTime == "N/A")
        #expect(recipe.formattedCookTime == "N/A")
        #expect(recipe.formattedTotalTime == "N/A")
    }

    @Test func testRecipeDefaultValues() async throws {
        let recipe = Recipe()

        #expect(recipe.name == "")
        #expect(recipe.author == "")
        #expect(recipe.rating == 0)
        #expect(recipe.isFavorite == false)
        #expect(recipe.keywords.isEmpty)
        #expect(recipe.ingredientsList.isEmpty)
        #expect(recipe.recipeData == "{}")
    }

    @Test func testRecipeKeywordsAndIngredients() async throws {
        let recipe = Recipe(
            name: "Test",
            keywords: ["vegetarian", "quick", "easy"],
            ingredientsList: ["tomato", "pasta", "garlic"]
        )

        #expect(recipe.keywords.count == 3)
        #expect(recipe.keywords.contains("vegetarian"))
        #expect(recipe.ingredientsList.count == 3)
        #expect(recipe.ingredientsList.contains("pasta"))
    }

    @Test @MainActor func testRecipeModelContainer() async throws {
        // Test that we can create an in-memory container
        let schema = Schema([Recipe.self])
        let config = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true,
            cloudKitDatabase: .none
        )

        let container = try ModelContainer(for: schema, configurations: [config])
        let context = container.mainContext

        // Insert a recipe
        let recipe = Recipe(name: "Container Test Recipe")
        context.insert(recipe)

        // Fetch recipes
        let descriptor = FetchDescriptor<Recipe>()
        let recipes = try context.fetch(descriptor)

        #expect(recipes.count == 1)
        #expect(recipes.first?.name == "Container Test Recipe")
    }

    @Test @MainActor func testRecipeUpdate() async throws {
        let schema = Schema([Recipe.self])
        let config = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true,
            cloudKitDatabase: .none
        )

        let container = try ModelContainer(for: schema, configurations: [config])
        let context = container.mainContext

        // Insert and modify a recipe
        let recipe = Recipe(name: "Original Name", rating: 3)
        context.insert(recipe)

        recipe.name = "Updated Name"
        recipe.rating = 5
        recipe.isFavorite = true

        let descriptor = FetchDescriptor<Recipe>()
        let recipes = try context.fetch(descriptor)

        #expect(recipes.first?.name == "Updated Name")
        #expect(recipes.first?.rating == 5)
        #expect(recipes.first?.isFavorite == true)
    }
}
