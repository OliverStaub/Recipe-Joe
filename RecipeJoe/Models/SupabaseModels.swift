//
//  SupabaseModels.swift
//  RecipeJoe
//
//  Codable models for Supabase database tables
//

import Foundation

// MARK: - Recipe Import Request/Response

/// Request to import a recipe from URL
struct RecipeImportRequest: Codable {
    let url: String
    let language: String
    let reword: Bool
}

/// Response from recipe import Edge Function
struct RecipeImportResponse: Codable {
    let success: Bool
    let recipeId: String?
    let recipeName: String?
    let error: String?
    let stats: ImportStats?

    enum CodingKeys: String, CodingKey {
        case success
        case recipeId = "recipe_id"
        case recipeName = "recipe_name"
        case error
        case stats
    }
}

/// Import statistics from Edge Function
struct ImportStats: Codable {
    let stepsCount: Int
    let ingredientsCount: Int
    let newIngredientsCount: Int
    let tokensUsed: TokenUsage

    enum CodingKeys: String, CodingKey {
        case stepsCount = "steps_count"
        case ingredientsCount = "ingredients_count"
        case newIngredientsCount = "new_ingredients_count"
        case tokensUsed = "tokens_used"
    }
}

/// Token usage from Claude API
struct TokenUsage: Codable {
    let inputTokens: Int
    let outputTokens: Int

    enum CodingKeys: String, CodingKey {
        case inputTokens = "input_tokens"
        case outputTokens = "output_tokens"
    }
}

// MARK: - Database Models

/// Recipe as stored in Supabase
struct SupabaseRecipe: Codable, Identifiable {
    let id: UUID
    let userId: UUID?
    let name: String
    let author: String?
    let description: String?
    let prepTimeMinutes: Int?
    let cookTimeMinutes: Int?
    let totalTimeMinutes: Int?
    let recipeYield: String?
    let category: String?
    let cuisine: String?
    let rating: Int
    let isFavorite: Bool
    let imageUrl: String?
    let sourceUrl: String?
    let keywords: [String]?
    let language: String?
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case name
        case author
        case description
        case prepTimeMinutes = "prep_time_minutes"
        case cookTimeMinutes = "cook_time_minutes"
        case totalTimeMinutes = "total_time_minutes"
        case recipeYield = "recipe_yield"
        case category
        case cuisine
        case rating
        case isFavorite = "is_favorite"
        case imageUrl = "image_url"
        case sourceUrl = "source_url"
        case keywords
        case language
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

/// Recipe step as stored in Supabase
struct SupabaseRecipeStep: Codable, Identifiable {
    let id: UUID
    let recipeId: UUID
    let stepNumber: Int
    let instruction: String
    let durationMinutes: Int?

    enum CodingKeys: String, CodingKey {
        case id
        case recipeId = "recipe_id"
        case stepNumber = "step_number"
        case instruction
        case durationMinutes = "duration_minutes"
    }
}

/// Ingredient as stored in Supabase (shared across users)
struct SupabaseIngredient: Codable, Identifiable {
    let id: UUID
    let nameEn: String
    let nameDe: String
    let defaultMeasurementTypeId: UUID?

    enum CodingKeys: String, CodingKey {
        case id
        case nameEn = "name_en"
        case nameDe = "name_de"
        case defaultMeasurementTypeId = "default_measurement_type_id"
    }

    /// Returns the localized name based on current locale
    var localizedName: String {
        Locale.current.language.languageCode?.identifier == "de" ? nameDe : nameEn
    }
}

/// Measurement type as stored in Supabase
struct SupabaseMeasurementType: Codable, Identifiable {
    let id: UUID
    let nameEn: String
    let nameDe: String
    let abbreviationEn: String
    let abbreviationDe: String

    enum CodingKeys: String, CodingKey {
        case id
        case nameEn = "name_en"
        case nameDe = "name_de"
        case abbreviationEn = "abbreviation_en"
        case abbreviationDe = "abbreviation_de"
    }

    /// Returns the localized name based on current locale
    var localizedName: String {
        Locale.current.language.languageCode?.identifier == "de" ? nameDe : nameEn
    }

    /// Returns the localized abbreviation based on current locale
    var localizedAbbreviation: String {
        Locale.current.language.languageCode?.identifier == "de" ? abbreviationDe : abbreviationEn
    }
}

/// Recipe ingredient junction as stored in Supabase
struct SupabaseRecipeIngredient: Codable, Identifiable {
    let id: UUID
    let recipeId: UUID
    let ingredientId: UUID
    let measurementTypeId: UUID?
    let quantity: Double?
    let notes: String?
    let displayOrder: Int

    // Joined data (when fetching with relations)
    var ingredient: SupabaseIngredient?
    var measurementType: SupabaseMeasurementType?

    enum CodingKeys: String, CodingKey {
        case id
        case recipeId = "recipe_id"
        case ingredientId = "ingredient_id"
        case measurementTypeId = "measurement_type_id"
        case quantity
        case notes
        case displayOrder = "display_order"
        case ingredient
        case measurementType = "measurement_type"
    }

    /// Formatted quantity string (e.g., "2 tbsp" or "500 g")
    var formattedQuantity: String {
        var parts: [String] = []

        if let qty = quantity {
            // Format nicely - remove trailing zeros
            if qty == qty.rounded() {
                parts.append(String(format: "%.0f", qty))
            } else {
                parts.append(String(format: "%.1f", qty))
            }
        }

        if let measurement = measurementType {
            parts.append(measurement.localizedAbbreviation)
        }

        return parts.joined(separator: " ")
    }
}

// MARK: - Full Recipe with Relations

/// Complete recipe with all related data
struct SupabaseRecipeDetail {
    let recipe: SupabaseRecipe
    let steps: [SupabaseRecipeStep]
    let ingredients: [SupabaseRecipeIngredient]

    /// Steps sorted by step number
    var sortedSteps: [SupabaseRecipeStep] {
        steps.sorted { $0.stepNumber < $1.stepNumber }
    }

    /// Ingredients sorted by display order
    var sortedIngredients: [SupabaseRecipeIngredient] {
        ingredients.sorted { $0.displayOrder < $1.displayOrder }
    }
}
