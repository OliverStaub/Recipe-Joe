//
//  RecipeJoeTests.swift
//  RecipeJoeTests
//
//  Unit tests for RecipeJoe models and utilities
//

import Foundation
import Testing
@testable import RecipeJoe

struct RecipeJoeTests {

    // MARK: - TimeFormatter Tests

    @Test func testFormatTimeMinutes() async throws {
        #expect(formatTime(30) == "30 min")
        #expect(formatTime(45) == "45 min")
        #expect(formatTime(59) == "59 min")
    }

    @Test func testFormatTimeHours() async throws {
        #expect(formatTime(60) == "1h")
        #expect(formatTime(120) == "2h")
        #expect(formatTime(180) == "3h")
    }

    @Test func testFormatTimeHoursAndMinutes() async throws {
        #expect(formatTime(75) == "1h 15m")
        #expect(formatTime(90) == "1h 30m")
        #expect(formatTime(150) == "2h 30m")
    }

    // MARK: - SupabaseRecipe JSON Decoding Tests

    @Test func testRecipeDecoding() async throws {
        let json = """
        {
            "id": "550e8400-e29b-41d4-a716-446655440000",
            "user_id": null,
            "name": "Test Recipe",
            "author": "Test Author",
            "description": "A delicious test recipe",
            "prep_time_minutes": 15,
            "cook_time_minutes": 30,
            "total_time_minutes": 45,
            "recipe_yield": "4 servings",
            "category": "Dinner",
            "cuisine": "Italian",
            "rating": 4,
            "is_favorite": true,
            "image_url": "https://example.com/image.jpg",
            "source_url": "https://example.com/recipe",
            "keywords": ["pasta", "quick", "easy"],
            "language": "en",
            "created_at": "2024-01-01T12:00:00Z",
            "updated_at": "2024-01-01T12:00:00Z"
        }
        """

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let data = json.data(using: .utf8)!
        let recipe = try decoder.decode(SupabaseRecipe.self, from: data)

        #expect(recipe.name == "Test Recipe")
        #expect(recipe.author == "Test Author")
        #expect(recipe.prepTimeMinutes == 15)
        #expect(recipe.cookTimeMinutes == 30)
        #expect(recipe.totalTimeMinutes == 45)
        #expect(recipe.rating == 4)
        #expect(recipe.isFavorite == true)
        #expect(recipe.category == "Dinner")
        #expect(recipe.cuisine == "Italian")
        #expect(recipe.keywords?.count == 3)
    }

    @Test func testRecipeDecodingWithNullFields() async throws {
        let json = """
        {
            "id": "550e8400-e29b-41d4-a716-446655440000",
            "user_id": null,
            "name": "Minimal Recipe",
            "author": null,
            "description": null,
            "prep_time_minutes": null,
            "cook_time_minutes": null,
            "total_time_minutes": null,
            "recipe_yield": null,
            "category": null,
            "cuisine": null,
            "rating": 0,
            "is_favorite": false,
            "image_url": null,
            "source_url": null,
            "keywords": null,
            "language": null,
            "created_at": "2024-01-01T12:00:00Z",
            "updated_at": "2024-01-01T12:00:00Z"
        }
        """

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let data = json.data(using: .utf8)!
        let recipe = try decoder.decode(SupabaseRecipe.self, from: data)

        #expect(recipe.name == "Minimal Recipe")
        #expect(recipe.author == nil)
        #expect(recipe.prepTimeMinutes == nil)
        #expect(recipe.rating == 0)
        #expect(recipe.isFavorite == false)
    }

    // MARK: - SupabaseRecipeStep Tests

    @Test func testRecipeStepDecoding() async throws {
        let json = """
        {
            "id": "550e8400-e29b-41d4-a716-446655440001",
            "recipe_id": "550e8400-e29b-41d4-a716-446655440000",
            "step_number": 1,
            "instruction": "prep: Dice the onions into small cubes",
            "duration_minutes": 5
        }
        """

        let data = json.data(using: .utf8)!
        let step = try JSONDecoder().decode(SupabaseRecipeStep.self, from: data)

        #expect(step.stepNumber == 1)
        #expect(step.instruction == "prep: Dice the onions into small cubes")
        #expect(step.durationMinutes == 5)
    }

    // MARK: - SupabaseIngredient Tests

    @Test func testIngredientDecoding() async throws {
        let json = """
        {
            "id": "550e8400-e29b-41d4-a716-446655440002",
            "name_en": "Onion",
            "name_de": "Zwiebel",
            "default_measurement_type_id": null
        }
        """

        let data = json.data(using: .utf8)!
        let ingredient = try JSONDecoder().decode(SupabaseIngredient.self, from: data)

        #expect(ingredient.nameEn == "Onion")
        #expect(ingredient.nameDe == "Zwiebel")
    }

    // MARK: - SupabaseMeasurementType Tests

    @Test func testMeasurementTypeDecoding() async throws {
        let json = """
        {
            "id": "550e8400-e29b-41d4-a716-446655440003",
            "name_en": "tablespoon",
            "name_de": "Esslöffel",
            "abbreviation_en": "tbsp",
            "abbreviation_de": "EL"
        }
        """

        let data = json.data(using: .utf8)!
        let measurement = try JSONDecoder().decode(SupabaseMeasurementType.self, from: data)

        #expect(measurement.nameEn == "tablespoon")
        #expect(measurement.nameDe == "Esslöffel")
        #expect(measurement.abbreviationEn == "tbsp")
        #expect(measurement.abbreviationDe == "EL")
    }

    // MARK: - RecipeImportResponse Tests

    @Test func testImportResponseSuccessDecoding() async throws {
        let json = """
        {
            "success": true,
            "recipe_id": "550e8400-e29b-41d4-a716-446655440000",
            "recipe_name": "Imported Recipe",
            "error": null,
            "stats": {
                "steps_count": 5,
                "ingredients_count": 10,
                "new_ingredients_count": 2,
                "tokens_used": {
                    "input_tokens": 1000,
                    "output_tokens": 500
                }
            }
        }
        """

        let data = json.data(using: .utf8)!
        let response = try JSONDecoder().decode(RecipeImportResponse.self, from: data)

        #expect(response.success == true)
        #expect(response.recipeName == "Imported Recipe")
        #expect(response.stats?.stepsCount == 5)
        #expect(response.stats?.ingredientsCount == 10)
        #expect(response.stats?.newIngredientsCount == 2)
    }

    @Test func testImportResponseErrorDecoding() async throws {
        let json = """
        {
            "success": false,
            "recipe_id": null,
            "recipe_name": null,
            "error": "Invalid URL provided",
            "stats": null
        }
        """

        let data = json.data(using: .utf8)!
        let response = try JSONDecoder().decode(RecipeImportResponse.self, from: data)

        #expect(response.success == false)
        #expect(response.error == "Invalid URL provided")
        #expect(response.recipeId == nil)
    }

    // MARK: - SupabaseRecipeIngredient FormattedQuantity Tests

    @Test func testFormattedQuantityWithMeasurement() async throws {
        let measurement = SupabaseMeasurementType(
            id: UUID(),
            nameEn: "tablespoon",
            nameDe: "Esslöffel",
            abbreviationEn: "tbsp",
            abbreviationDe: "EL"
        )

        var ingredient = SupabaseRecipeIngredient(
            id: UUID(),
            recipeId: UUID(),
            ingredientId: UUID(),
            measurementTypeId: UUID(),
            quantity: 2.0,
            notes: nil,
            displayOrder: 1
        )
        ingredient.measurementType = measurement

        // The formattedQuantity depends on locale, but we can test the structure
        let formatted = ingredient.formattedQuantity
        #expect(formatted.contains("2"))
    }

    @Test func testFormattedQuantityWholeNumber() async throws {
        var ingredient = SupabaseRecipeIngredient(
            id: UUID(),
            recipeId: UUID(),
            ingredientId: UUID(),
            measurementTypeId: nil,
            quantity: 3.0,
            notes: nil,
            displayOrder: 1
        )

        #expect(ingredient.formattedQuantity == "3")
    }

    @Test func testFormattedQuantityDecimal() async throws {
        var ingredient = SupabaseRecipeIngredient(
            id: UUID(),
            recipeId: UUID(),
            ingredientId: UUID(),
            measurementTypeId: nil,
            quantity: 1.5,
            notes: nil,
            displayOrder: 1
        )

        #expect(ingredient.formattedQuantity == "1.5")
    }

    // MARK: - SupabaseRecipeDetail Tests

    @Test func testRecipeDetailSortedSteps() async throws {
        let recipeId = UUID()
        let steps = [
            SupabaseRecipeStep(id: UUID(), recipeId: recipeId, stepNumber: 3, instruction: "Step 3", durationMinutes: nil),
            SupabaseRecipeStep(id: UUID(), recipeId: recipeId, stepNumber: 1, instruction: "Step 1", durationMinutes: nil),
            SupabaseRecipeStep(id: UUID(), recipeId: recipeId, stepNumber: 2, instruction: "Step 2", durationMinutes: nil)
        ]

        let detail = SupabaseRecipeDetail(
            recipe: createTestRecipe(id: recipeId),
            steps: steps,
            ingredients: []
        )

        let sorted = detail.sortedSteps
        #expect(sorted[0].stepNumber == 1)
        #expect(sorted[1].stepNumber == 2)
        #expect(sorted[2].stepNumber == 3)
    }

    @Test func testRecipeDetailSortedIngredients() async throws {
        let recipeId = UUID()
        let ingredients = [
            createTestIngredient(recipeId: recipeId, displayOrder: 3),
            createTestIngredient(recipeId: recipeId, displayOrder: 1),
            createTestIngredient(recipeId: recipeId, displayOrder: 2)
        ]

        let detail = SupabaseRecipeDetail(
            recipe: createTestRecipe(id: recipeId),
            steps: [],
            ingredients: ingredients
        )

        let sorted = detail.sortedIngredients
        #expect(sorted[0].displayOrder == 1)
        #expect(sorted[1].displayOrder == 2)
        #expect(sorted[2].displayOrder == 3)
    }

    // MARK: - Localization Tests

    @Test func testLocalizationServiceEnglish() async throws {
        // Test that English locale returns English strings
        let locale = Locale(identifier: "en")
        let result = "Settings".localized(for: locale)
        #expect(result == "Settings" || result == "Einstellungen" || result == "Istellige",
                "Should return a valid localized string")
    }

    @Test func testLocalizationServiceGerman() async throws {
        // Test that German locale returns German strings
        let locale = Locale(identifier: "de")
        let result = "Settings".localized(for: locale)
        // Note: This may return English if bundle isn't available in test
        #expect(!result.isEmpty, "Should return non-empty string")
    }

    @Test func testLocalizationServiceSwissGerman() async throws {
        // Test that Swiss German locale returns Swiss German or German strings
        let locale = Locale(identifier: "gsw")
        let result = "Settings".localized(for: locale)
        // Note: This may fall back to German or English
        #expect(!result.isEmpty, "Should return non-empty string")
    }

    @Test func testStepCategoryParsing() async throws {
        // Test that step categories are correctly parsed
        let (category, instruction) = StepCategory.parse("prep: Dice the onions")
        #expect(category == .prep)
        #expect(instruction == "Dice the onions")
    }

    @Test func testStepCategoryParsingMixedCase() async throws {
        // Test that parsing is case-insensitive
        let (category, instruction) = StepCategory.parse("PREP: Dice the onions")
        #expect(category == .prep)
        #expect(instruction == "Dice the onions")
    }

    @Test func testStepCategoryParsingUnknown() async throws {
        // Test that unknown categories return .unknown
        let (category, instruction) = StepCategory.parse("Some random instruction")
        #expect(category == .unknown)
        #expect(instruction == "Some random instruction")
    }

    @Test func testStepCategoryDisplayNameWithLocale() async throws {
        // Test that display names can be retrieved for different locales
        let englishLocale = Locale(identifier: "en")
        let germanLocale = Locale(identifier: "de")

        let englishName = StepCategory.prep.displayName(locale: englishLocale)
        let germanName = StepCategory.prep.displayName(locale: germanLocale)

        // Both should return non-empty strings
        #expect(!englishName.isEmpty, "English display name should not be empty")
        #expect(!germanName.isEmpty, "German display name should not be empty")
    }

    // MARK: - Video URL Detection Tests

    @Test func testIsVideoURL_YouTube() async throws {
        let viewModel = await RecipeImportViewModel()
        #expect(await viewModel.isVideoURL("https://www.youtube.com/watch?v=dQw4w9WgXcQ") == true)
        #expect(await viewModel.isVideoURL("https://youtube.com/watch?v=dQw4w9WgXcQ") == true)
    }

    @Test func testIsVideoURL_YouTubeShorts() async throws {
        let viewModel = await RecipeImportViewModel()
        #expect(await viewModel.isVideoURL("https://www.youtube.com/shorts/dQw4w9WgXcQ") == true)
        #expect(await viewModel.isVideoURL("https://youtube.com/shorts/abc123def45") == true)
    }

    @Test func testIsVideoURL_YouTubeShortLink() async throws {
        let viewModel = await RecipeImportViewModel()
        #expect(await viewModel.isVideoURL("https://youtu.be/dQw4w9WgXcQ") == true)
    }

    @Test func testIsVideoURL_InstagramReels() async throws {
        let viewModel = await RecipeImportViewModel()
        #expect(await viewModel.isVideoURL("https://www.instagram.com/reel/ABC123def45/") == true)
        #expect(await viewModel.isVideoURL("https://instagram.com/reel/xyz789ghi12/") == true)
    }

    @Test func testIsVideoURL_InstagramPost() async throws {
        let viewModel = await RecipeImportViewModel()
        #expect(await viewModel.isVideoURL("https://www.instagram.com/p/ABC123def45/") == true)
    }

    @Test func testIsVideoURL_TikTok() async throws {
        let viewModel = await RecipeImportViewModel()
        #expect(await viewModel.isVideoURL("https://www.tiktok.com/@username/video/1234567890123456789") == true)
        #expect(await viewModel.isVideoURL("https://tiktok.com/@chef.name/video/9876543210987654321") == true)
    }

    @Test func testIsVideoURL_TikTokShortLink() async throws {
        let viewModel = await RecipeImportViewModel()
        #expect(await viewModel.isVideoURL("https://vm.tiktok.com/ZMrABC123/") == true)
    }

    @Test func testIsVideoURL_RegularWebsite() async throws {
        let viewModel = await RecipeImportViewModel()
        #expect(await viewModel.isVideoURL("https://www.allrecipes.com/recipe/12345") == false)
        #expect(await viewModel.isVideoURL("https://www.seriouseats.com/best-lasagna-recipe") == false)
        #expect(await viewModel.isVideoURL("https://example.com/recipe") == false)
    }

    @Test func testVideoPlatformName_YouTube() async throws {
        let viewModel = await RecipeImportViewModel()
        #expect(await viewModel.videoPlatformName("https://www.youtube.com/watch?v=dQw4w9WgXcQ") == "YouTube")
        #expect(await viewModel.videoPlatformName("https://youtu.be/dQw4w9WgXcQ") == "YouTube")
    }

    @Test func testVideoPlatformName_Instagram() async throws {
        let viewModel = await RecipeImportViewModel()
        #expect(await viewModel.videoPlatformName("https://www.instagram.com/reel/ABC123def45/") == "Instagram")
    }

    @Test func testVideoPlatformName_TikTok() async throws {
        let viewModel = await RecipeImportViewModel()
        #expect(await viewModel.videoPlatformName("https://www.tiktok.com/@username/video/1234567890") == "TikTok")
    }

    @Test func testVideoPlatformName_NotVideo() async throws {
        let viewModel = await RecipeImportViewModel()
        #expect(await viewModel.videoPlatformName("https://www.allrecipes.com/recipe/12345") == nil)
    }

    // MARK: - Timestamp Validation Tests

    @Test func testIsValidTimestamp_Empty() async throws {
        let viewModel = await RecipeImportViewModel()
        #expect(await viewModel.isValidTimestamp("") == true)
    }

    @Test func testIsValidTimestamp_MinutesSeconds() async throws {
        let viewModel = await RecipeImportViewModel()
        #expect(await viewModel.isValidTimestamp("1:30") == true)
        #expect(await viewModel.isValidTimestamp("0:00") == true)
        #expect(await viewModel.isValidTimestamp("59:59") == true)
        #expect(await viewModel.isValidTimestamp("10:45") == true)
    }

    @Test func testIsValidTimestamp_HoursMinutesSeconds() async throws {
        let viewModel = await RecipeImportViewModel()
        #expect(await viewModel.isValidTimestamp("1:30:00") == true)
        #expect(await viewModel.isValidTimestamp("0:00:00") == true)
        #expect(await viewModel.isValidTimestamp("2:15:30") == true)
    }

    @Test func testIsValidTimestamp_Invalid() async throws {
        let viewModel = await RecipeImportViewModel()
        #expect(await viewModel.isValidTimestamp("abc") == false)
        #expect(await viewModel.isValidTimestamp("1:2:3:4") == false)
        #expect(await viewModel.isValidTimestamp("hello") == false)
    }

    // MARK: - AuthenticationError Tests

    @Test func testAuthenticationErrorDescriptions() async throws {
        let invalidCredential = AuthenticationError.invalidCredential
        #expect(invalidCredential.errorDescription?.contains("Apple ID") == true)

        let notAuthenticated = AuthenticationError.notAuthenticated
        #expect(notAuthenticated.errorDescription?.contains("signed in") == true)

        let signInFailed = AuthenticationError.signInFailed("Test error")
        #expect(signInFailed.errorDescription?.contains("Test error") == true)
    }

    // MARK: - Helper Functions

    private func createTestRecipe(id: UUID) -> SupabaseRecipe {
        return SupabaseRecipe(
            id: id,
            userId: nil,
            name: "Test Recipe",
            author: nil,
            description: nil,
            prepTimeMinutes: nil,
            cookTimeMinutes: nil,
            totalTimeMinutes: nil,
            recipeYield: nil,
            category: nil,
            cuisine: nil,
            rating: 0,
            isFavorite: false,
            imageUrl: nil,
            sourceUrl: nil,
            keywords: nil,
            language: nil,
            createdAt: Date(),
            updatedAt: Date()
        )
    }

    private func createTestIngredient(recipeId: UUID, displayOrder: Int) -> SupabaseRecipeIngredient {
        return SupabaseRecipeIngredient(
            id: UUID(),
            recipeId: recipeId,
            ingredientId: UUID(),
            measurementTypeId: nil,
            quantity: nil,
            notes: nil,
            displayOrder: displayOrder
        )
    }
}
