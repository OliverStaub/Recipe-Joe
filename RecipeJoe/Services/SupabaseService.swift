//
//  SupabaseService.swift
//  RecipeJoe
//
//  Created by Oliver Staub on 05.12.2025.
//

import Foundation
import Supabase

/// Service to interact with Supabase Edge Functions
@MainActor
final class SupabaseService {
    // MARK: - Singleton

    static let shared = SupabaseService()

    // MARK: - Properties

    private let client: SupabaseClient

    // MARK: - Configuration

    /// Supabase project URL - Replace with your actual project URL
    private static let supabaseURL = "REMOVED_URL"

    /// Supabase anon key - Safe to expose in client apps
    /// This key only allows access to public resources and Edge Functions
    private static let supabaseAnonKey = "REMOVED_KEY"

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
    ///   - url: The URL of the recipe webpage
    ///   - language: Target language for the recipe ("en" or "de")
    ///   - reword: If true, AI will reword and translate. If false, keeps original text with category prefixes only.
    /// - Returns: The import response with recipe details
    func importRecipe(from url: String, language: String = "en", reword: Bool = true) async throws -> RecipeImportResponse {
        let request = RecipeImportRequest(url: url, language: language, reword: reword)

        let response: RecipeImportResponse = try await client.functions.invoke(
            "recipe-import",
            options: FunctionInvokeOptions(body: request)
        )

        return response
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

    // MARK: - Delete Recipe

    /// Delete a recipe and all its related data (steps, ingredients cascade automatically)
    func deleteRecipe(id: UUID) async throws {
        try await client
            .from("recipes")
            .delete()
            .eq("id", value: id.uuidString)
            .execute()
    }
}

// MARK: - Errors

enum SupabaseError: LocalizedError {
    case functionError(String)
    case unknownError

    var errorDescription: String? {
        switch self {
        case .functionError(let message):
            return "Function error: \(message)"
        case .unknownError:
            return "An unknown error occurred"
        }
    }
}
