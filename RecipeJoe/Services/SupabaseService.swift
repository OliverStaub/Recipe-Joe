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

    // MARK: - Edge Function Calls

    /// Response structure from the anthropic-relay function
    struct AnthropicRelayResponse: Codable {
        let success: Bool
        let message: String?
        let model: String?
        let error: String?
    }

    /// Request structure for the anthropic-relay function
    struct AnthropicRelayRequest: Codable {
        let prompt: String
    }

    /// Call the anthropic-relay Edge Function
    /// - Parameter prompt: The prompt to send to Claude
    /// - Returns: The response message from Claude
    func callAnthropicRelay(prompt: String = "Hello! Please say hello back.") async throws -> String {
        let request = AnthropicRelayRequest(prompt: prompt)

        let response: AnthropicRelayResponse = try await client.functions.invoke(
            "anthropic-relay",
            options: FunctionInvokeOptions(body: request)
        )

        if response.success, let message = response.message {
            return message
        } else if let error = response.error {
            throw SupabaseError.functionError(error)
        } else {
            throw SupabaseError.unknownError
        }
    }

    // MARK: - Recipe Import

    /// Import a recipe from a URL using the Edge Function
    /// - Parameters:
    ///   - url: The URL of the recipe webpage
    ///   - language: Target language for the recipe ("en" or "de")
    /// - Returns: The import response with recipe details
    func importRecipe(from url: String, language: String = "en") async throws -> RecipeImportResponse {
        let request = RecipeImportRequest(url: url, language: language)

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
