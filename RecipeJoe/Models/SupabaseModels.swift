//
//  SupabaseModels.swift
//  RecipeJoe
//
//  Codable models for Supabase database tables
//

import Foundation

// MARK: - Recipe Import Request/Response

/// Request to import a recipe from URL
struct RecipeImportRequest: Codable, Sendable {
    let url: String
    let language: String
    let translate: Bool
    let startTimestamp: String?
    let endTimestamp: String?
    let importId: String? // Client-generated UUID for job tracking

    enum CodingKeys: String, CodingKey {
        case url
        case language
        case translate
        case startTimestamp
        case endTimestamp
        case importId = "import_id"
    }
}

/// Response from recipe import Edge Function
struct RecipeImportResponse: Codable, Sendable {
    let success: Bool
    let importId: String? // Job ID for status tracking
    let recipeId: String?
    let recipeName: String?
    let error: String?
    // Token balance info (from server-side deduction)
    let tokensDeducted: Int?
    let tokensRemaining: Int?
    let tokensRequired: Int?
    let tokensAvailable: Int?
    // Rate limiting info
    let rateLimitRemaining: Int?
    let rateLimitReset: String?
    let stats: ImportStats?

    enum CodingKeys: String, CodingKey {
        case success
        case importId = "import_id"
        case recipeId = "recipe_id"
        case recipeName = "recipe_name"
        case error
        case tokensDeducted = "tokens_deducted"
        case tokensRemaining = "tokens_remaining"
        case tokensRequired = "tokens_required"
        case tokensAvailable = "tokens_available"
        case rateLimitRemaining = "rate_limit_remaining"
        case rateLimitReset = "rate_limit_reset"
        case stats
    }
}

/// Import statistics from Edge Function
struct ImportStats: Codable, Sendable {
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
struct TokenUsage: Codable, Sendable {
    let inputTokens: Int
    let outputTokens: Int

    enum CodingKeys: String, CodingKey {
        case inputTokens = "input_tokens"
        case outputTokens = "output_tokens"
    }
}

// MARK: - Media Import (OCR)

/// Media type for OCR import
enum MediaImportType: String, Codable, Sendable {
    case image
    case pdf
}

/// Request to import a recipe from image/PDF via OCR
struct MediaImportRequest: Codable, Sendable {
    let storagePaths: [String]
    let mediaType: String
    let language: String
    let translate: Bool

    enum CodingKeys: String, CodingKey {
        case storagePaths = "storage_paths"
        case mediaType = "media_type"
        case language
        case translate
    }
}

/// Response from media import Edge Function (same structure as URL import)
typealias MediaImportResponse = RecipeImportResponse

// MARK: - Import Status (for job tracking)

/// Status of an import job
enum ImportJobStatus: String, Codable, Sendable {
    case pending
    case success
    case failed
}

/// Import log entry for status checking
struct ImportLogEntry: Codable, Sendable {
    let id: UUID
    let status: String
    let recipeId: UUID?
    let recipeName: String?
    let errorMessage: String?
    let tokensUsed: Int?

    enum CodingKeys: String, CodingKey {
        case id
        case status
        case recipeId = "recipe_id"
        case recipeName = "recipe_name"
        case errorMessage = "error_message"
        case tokensUsed = "tokens_used"
    }

    /// Parsed status enum
    var jobStatus: ImportJobStatus {
        ImportJobStatus(rawValue: status) ?? .failed
    }
}

// MARK: - Database Models

/// Recipe as stored in Supabase
/// Note: nonisolated required for Codable to work with Supabase SDK in non-main-actor context
nonisolated struct SupabaseRecipe: Codable, Identifiable, Sendable {
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
struct SupabaseRecipeStep: Codable, Identifiable, Sendable {
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
struct SupabaseIngredient: Codable, Identifiable, Sendable {
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
struct SupabaseMeasurementType: Codable, Identifiable, Sendable {
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
struct SupabaseRecipeIngredient: Codable, Identifiable, Sendable {
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
struct SupabaseRecipeDetail: Sendable {
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

// MARK: - Update Models

/// Update model for recipe description
struct RecipeDescriptionUpdate: Codable {
    let description: String?
}

/// Update model for recipe prep time
struct RecipePrepTimeUpdate: Codable {
    let prepTimeMinutes: Int?

    enum CodingKeys: String, CodingKey {
        case prepTimeMinutes = "prep_time_minutes"
    }
}

/// Update model for recipe cook time
struct RecipeCookTimeUpdate: Codable {
    let cookTimeMinutes: Int?

    enum CodingKeys: String, CodingKey {
        case cookTimeMinutes = "cook_time_minutes"
    }
}

/// Update model for recipe total time
struct RecipeTotalTimeUpdate: Codable {
    let totalTimeMinutes: Int?

    enum CodingKeys: String, CodingKey {
        case totalTimeMinutes = "total_time_minutes"
    }
}

/// Update model for recipe yield/servings
struct RecipeYieldUpdate: Codable {
    let recipeYield: String?

    enum CodingKeys: String, CodingKey {
        case recipeYield = "recipe_yield"
    }
}

/// Update model for recipe category
struct RecipeCategoryUpdate: Codable {
    let category: String?
}

/// Update model for recipe cuisine
struct RecipeCuisineUpdate: Codable {
    let cuisine: String?
}

/// Update model for recipe ingredient quantity and notes
struct RecipeIngredientUpdate: Codable {
    let quantity: Double?
    let notes: String?
}
