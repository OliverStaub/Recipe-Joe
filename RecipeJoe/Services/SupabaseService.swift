//
//  SupabaseService.swift
//  RecipeJoe
//
//  Created by Oliver Staub on 05.12.2025.
//

import Foundation
import Supabase

/// Service to interact with Supabase Edge Functions
final class SupabaseService: Sendable {
    // MARK: - Singleton

    static let shared = SupabaseService()

    // MARK: - Properties

    /// The Supabase client - exposed for auth operations
    let client: SupabaseClient

    // MARK: - Configuration

    /// Supabase project URL
    private static let supabaseURL = "https://iqamjnyuvvmvakjdobsm.supabase.co"

    /// Supabase publishable key (safe to include in client apps)
    /// This key only allows access to public resources and Edge Functions
    private static let supabaseAnonKey = "sb_publishable_bjC-0a3jReGsoS5pprLevA_dDXqwrxn"

    // MARK: - Initialization

    private init() {
        self.client = SupabaseClient(
            supabaseURL: URL(string: Self.supabaseURL)!,
            supabaseKey: Self.supabaseAnonKey
        )
    }

    // MARK: - Recipe Import

    /// Import a recipe from a URL using the Edge Function
    /// - Parameters:
    ///   - url: The URL of the recipe webpage or video
    ///   - language: Target language for the recipe ("en" or "de")
    ///   - translate: If true, translate recipe to target language when source differs
    ///   - startTimestamp: Optional start time for video (MM:SS or HH:MM:SS format). If nil, starts from beginning.
    ///   - endTimestamp: Optional end time for video (MM:SS or HH:MM:SS format). If nil, goes to end.
    ///   - importId: Client-generated UUID for job tracking. If connection is lost, client can check status using this ID.
    /// - Returns: The import response with recipe details
    func importRecipe(
        from url: String,
        language: String = "en",
        translate: Bool = true,
        startTimestamp: String? = nil,
        endTimestamp: String? = nil,
        importId: String? = nil
    ) async throws -> RecipeImportResponse {
        let request = RecipeImportRequest(
            url: url,
            language: language,
            translate: translate,
            startTimestamp: startTimestamp,
            endTimestamp: endTimestamp,
            importId: importId
        )

        let response: RecipeImportResponse = try await client.functions.invoke(
            "recipe-import",
            options: FunctionInvokeOptions(body: request)
        )

        return response
    }

    /// Check the status of an import job
    /// - Parameter importId: The import job ID to check
    /// - Returns: The import log entry with status, or nil if not found
    func checkImportStatus(importId: UUID) async throws -> ImportLogEntry? {
        let response: [ImportLogEntry] = try await client
            .from("import_logs")
            .select("id, status, recipe_id, recipe_name, error_message, tokens_used")
            .eq("id", value: importId.uuidString)
            .limit(1)
            .execute()
            .value

        return response.first
    }

    // MARK: - Recipe Fetching

    /// Fetch all recipes
    func fetchRecipes() async throws -> [SupabaseRecipe] {
        let response: [SupabaseRecipe] = try await client
            .from("recipes")
            .select()
            .order("created_at", ascending: false)
            .execute()
            .value

        return response
    }

    /// Fetch a single recipe with all related data
    func fetchRecipeDetail(id: UUID) async throws -> SupabaseRecipeDetail {
        async let recipeTask: SupabaseRecipe = client
            .from("recipes")
            .select()
            .eq("id", value: id.uuidString)
            .single()
            .execute()
            .value

        async let stepsTask: [SupabaseRecipeStep] = client
            .from("recipe_steps")
            .select()
            .eq("recipe_id", value: id.uuidString)
            .order("step_number")
            .execute()
            .value

        async let ingredientsTask: [SupabaseRecipeIngredient] = client
            .from("recipe_ingredients")
            .select("*, ingredient:ingredients(*), measurement_type:measurement_types(*)")
            .eq("recipe_id", value: id.uuidString)
            .order("display_order")
            .execute()
            .value

        let (recipe, steps, ingredients) = try await (recipeTask, stepsTask, ingredientsTask)
        return SupabaseRecipeDetail(recipe: recipe, steps: steps, ingredients: ingredients)
    }

    // MARK: - Image Upload

    /// Upload a recipe image to Supabase Storage
    /// - Parameters:
    ///   - imageData: The image data to upload
    ///   - recipeId: The recipe ID to associate with the image
    /// - Returns: The public URL of the uploaded image
    func uploadRecipeImage(imageData: Data, recipeId: UUID) async throws -> String {
        let fileName = "\(recipeId.uuidString).jpg"
        let filePath = fileName

        // Upload to storage
        try await client.storage
            .from("recipe-images")
            .upload(
                filePath,
                data: imageData,
                options: FileOptions(
                    contentType: "image/jpeg",
                    upsert: true
                )
            )

        // Get public URL
        let publicURL = try client.storage
            .from("recipe-images")
            .getPublicURL(path: filePath)

        // Update the recipe with the image URL
        try await updateRecipeImageUrl(id: recipeId, imageUrl: publicURL.absoluteString)

        return publicURL.absoluteString
    }

    /// Update a recipe's image URL
    func updateRecipeImageUrl(id: UUID, imageUrl: String) async throws {
        try await client
            .from("recipes")
            .update(["image_url": imageUrl])
            .eq("id", value: id.uuidString)
            .execute()
    }

    // MARK: - Media Import (OCR)

    /// Upload a temporary file for OCR import processing
    /// - Parameters:
    ///   - data: The file data to upload
    ///   - contentType: MIME type (e.g., "image/jpeg", "application/pdf")
    ///   - fileExtension: File extension (e.g., "jpg", "pdf")
    /// - Returns: The storage path for use with importRecipeFromMedia
    func uploadTempImport(data: Data, contentType: String, fileExtension: String) async throws -> String {
        let fileName = "\(UUID().uuidString).\(fileExtension)"
        let filePath = "temp/\(fileName)"

        try await client.storage
            .from("recipe-imports")
            .upload(
                filePath,
                data: data,
                options: FileOptions(
                    contentType: contentType,
                    upsert: false
                )
            )

        return filePath
    }

    /// Import a recipe from uploaded images or PDF using OCR
    /// - Parameters:
    ///   - storagePaths: The storage paths returned from uploadTempImport (for multiple images combined into one recipe)
    ///   - mediaType: The type of media (.image or .pdf)
    ///   - language: Target language for the recipe ("en" or "de")
    ///   - translate: If true, translate recipe to target language when source differs
    /// - Returns: The import response with recipe details
    func importRecipeFromMedia(
        storagePaths: [String],
        mediaType: MediaImportType,
        language: String = "en",
        translate: Bool = true
    ) async throws -> MediaImportResponse {
        let request = MediaImportRequest(
            storagePaths: storagePaths,
            mediaType: mediaType.rawValue,
            language: language,
            translate: translate
        )

        let response: MediaImportResponse = try await client.functions.invoke(
            "recipe-ocr-import",
            options: FunctionInvokeOptions(body: request)
        )

        return response
    }

    // MARK: - Recipe Updates

    /// Update a recipe's name
    func updateRecipeName(id: UUID, name: String) async throws {
        try await client
            .from("recipes")
            .update(["name": name])
            .eq("id", value: id.uuidString)
            .execute()
    }

    /// Update a recipe's description
    func updateRecipeDescription(id: UUID, description: String?) async throws {
        try await client
            .from("recipes")
            .update(RecipeDescriptionUpdate(description: description))
            .eq("id", value: id.uuidString)
            .execute()
    }

    /// Update a recipe's prep time
    func updateRecipePrepTime(id: UUID, prepTimeMinutes: Int?) async throws {
        try await client
            .from("recipes")
            .update(RecipePrepTimeUpdate(prepTimeMinutes: prepTimeMinutes))
            .eq("id", value: id.uuidString)
            .execute()
    }

    /// Update a recipe's cook time
    func updateRecipeCookTime(id: UUID, cookTimeMinutes: Int?) async throws {
        try await client
            .from("recipes")
            .update(RecipeCookTimeUpdate(cookTimeMinutes: cookTimeMinutes))
            .eq("id", value: id.uuidString)
            .execute()
    }

    /// Update a recipe's total time
    func updateRecipeTotalTime(id: UUID, totalTimeMinutes: Int?) async throws {
        try await client
            .from("recipes")
            .update(RecipeTotalTimeUpdate(totalTimeMinutes: totalTimeMinutes))
            .eq("id", value: id.uuidString)
            .execute()
    }

    /// Update a recipe's yield/servings
    func updateRecipeYield(id: UUID, recipeYield: String?) async throws {
        try await client
            .from("recipes")
            .update(RecipeYieldUpdate(recipeYield: recipeYield))
            .eq("id", value: id.uuidString)
            .execute()
    }

    /// Update a recipe's category
    func updateRecipeCategory(id: UUID, category: String?) async throws {
        try await client
            .from("recipes")
            .update(RecipeCategoryUpdate(category: category))
            .eq("id", value: id.uuidString)
            .execute()
    }

    /// Update a recipe's cuisine
    func updateRecipeCuisine(id: UUID, cuisine: String?) async throws {
        try await client
            .from("recipes")
            .update(RecipeCuisineUpdate(cuisine: cuisine))
            .eq("id", value: id.uuidString)
            .execute()
    }

    /// Update a recipe step's instruction
    func updateRecipeStep(id: UUID, instruction: String) async throws {
        try await client
            .from("recipe_steps")
            .update(["instruction": instruction])
            .eq("id", value: id.uuidString)
            .execute()
    }

    /// Update a recipe ingredient's quantity and notes
    func updateRecipeIngredient(id: UUID, quantity: Double?, notes: String?) async throws {
        try await client
            .from("recipe_ingredients")
            .update(RecipeIngredientUpdate(quantity: quantity, notes: notes))
            .eq("id", value: id.uuidString)
            .execute()
    }

    // MARK: - Favorite Toggle

    /// Toggle a recipe's favorite status
    func toggleFavorite(id: UUID, isFavorite: Bool) async throws {
        try await client
            .from("recipes")
            .update(["is_favorite": isFavorite])
            .eq("id", value: id.uuidString)
            .execute()
    }

    // MARK: - Delete Recipe

    /// Delete a recipe and all its related data (steps, ingredients cascade automatically)
    func deleteRecipe(id: UUID) async throws {
        try await client
            .from("recipes")
            .delete()
            .eq("id", value: id.uuidString)
            .execute()
    }

    // MARK: - Token Management

    /// Fetch the current user's token balance from Supabase
    /// - Returns: The current token balance
    func fetchTokenBalance() async throws -> Int {
        struct TokenBalance: Decodable {
            let balance: Int
        }

        let response: TokenBalance = try await client
            .from("user_tokens")
            .select("balance")
            .single()
            .execute()
            .value

        return response.balance
    }

    /// Validate a StoreKit purchase with the server and credit tokens
    /// - Parameters:
    ///   - transactionId: The StoreKit transaction ID
    ///   - productId: The product identifier (e.g., "tokens_10")
    ///   - originalTransactionId: The original transaction ID (for subscription/refund tracking)
    func validatePurchase(
        transactionId: String,
        productId: String,
        originalTransactionId: String?
    ) async throws {
        struct ValidateRequest: Encodable {
            let transactionId: String
            let productId: String
            let originalTransactionId: String?
        }

        struct ValidateResponse: Decodable {
            let success: Bool
            let balance: Int?
            let tokensAdded: Int?
            let alreadyProcessed: Bool?
            let error: String?
        }

        let request = ValidateRequest(
            transactionId: transactionId,
            productId: productId,
            originalTransactionId: originalTransactionId
        )

        let response: ValidateResponse = try await client.functions.invoke(
            "validate-purchase",
            options: FunctionInvokeOptions(body: request)
        )

        if !response.success {
            throw SupabaseError.functionError(response.error ?? "Purchase validation failed")
        }

        // Update token balance if returned
        if let newBalance = response.balance {
            Task { @MainActor in
                TokenService.shared.updateBalance(newBalance)
            }
        }
    }
}

// MARK: - Errors

enum SupabaseError: LocalizedError {
    case functionError(String)
    case unknownError
    case uploadFailed(String)
    case ocrFailed(String)
    case noRecipeFound
    case fileTooLarge(maxSizeMB: Int)
    case unsupportedFileType(String)

    var errorDescription: String? {
        switch self {
        case .functionError(let message):
            return "Function error: \(message)"
        case .unknownError:
            return "An unknown error occurred"
        case .uploadFailed(let message):
            return "Upload failed: \(message)"
        case .ocrFailed(let message):
            return "Could not read text: \(message)"
        case .noRecipeFound:
            return "No recipe found in the image"
        case .fileTooLarge(let maxSizeMB):
            return "File too large (max \(maxSizeMB)MB)"
        case .unsupportedFileType(let type):
            return "Unsupported file type: \(type)"
        }
    }
}
