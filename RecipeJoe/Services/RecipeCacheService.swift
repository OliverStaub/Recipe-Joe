//
//  RecipeCacheService.swift
//  RecipeJoe
//
//  Service for caching recipes locally for offline access and faster startup
//

import Foundation

// MARK: - Codable wrapper for SupabaseRecipeDetail (outside actor for Sendable conformance)

private struct CachedRecipeDetail: Sendable {
    let recipe: SupabaseRecipe
    let steps: [SupabaseRecipeStep]
    let ingredients: [SupabaseRecipeIngredient]
}

extension CachedRecipeDetail: Codable {
    nonisolated init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        recipe = try container.decode(SupabaseRecipe.self, forKey: .recipe)
        steps = try container.decode([SupabaseRecipeStep].self, forKey: .steps)
        ingredients = try container.decode([SupabaseRecipeIngredient].self, forKey: .ingredients)
    }

    nonisolated func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(recipe, forKey: .recipe)
        try container.encode(steps, forKey: .steps)
        try container.encode(ingredients, forKey: .ingredients)
    }

    private enum CodingKeys: String, CodingKey {
        case recipe, steps, ingredients
    }
}

actor RecipeCacheService {
    static let shared = RecipeCacheService()

    private let fileManager = FileManager.default
    private let cacheDirectory: URL
    private let recipesFileName = "cached_recipes.json"
    private let recipeDetailsDirectory = "recipe_details"

    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    private init() {
        // Set up cache directory in Application Support
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        cacheDirectory = appSupport.appendingPathComponent("RecipeJoe/Cache", isDirectory: true)

        // Create directories if needed
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        try? fileManager.createDirectory(
            at: cacheDirectory.appendingPathComponent(recipeDetailsDirectory),
            withIntermediateDirectories: true
        )

        // Configure encoder/decoder for Supabase date format
        encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601

        decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
    }

    // MARK: - Recipes List Cache

    /// Cache the recipes list to local storage
    func cacheRecipes(_ recipes: [SupabaseRecipe]) async throws {
        let url = cacheDirectory.appendingPathComponent(recipesFileName)
        let data = try encoder.encode(recipes)
        try data.write(to: url, options: .atomic)
    }

    /// Load cached recipes from local storage
    func loadCachedRecipes() async -> [SupabaseRecipe]? {
        let url = cacheDirectory.appendingPathComponent(recipesFileName)
        guard fileManager.fileExists(atPath: url.path) else { return nil }

        do {
            let data = try Data(contentsOf: url)
            return try decoder.decode([SupabaseRecipe].self, from: data)
        } catch {
            // Cache corrupted, remove it
            try? fileManager.removeItem(at: url)
            return nil
        }
    }

    // MARK: - Recipe Detail Cache

    /// Cache a recipe detail to local storage
    func cacheRecipeDetail(_ detail: SupabaseRecipeDetail) async throws {
        let url = recipeDetailURL(for: detail.recipe.id)
        let cacheItem = CachedRecipeDetail(
            recipe: detail.recipe,
            steps: detail.steps,
            ingredients: detail.ingredients
        )
        let data = try encoder.encode(cacheItem)
        try data.write(to: url, options: .atomic)
    }

    /// Load a cached recipe detail from local storage
    func loadCachedRecipeDetail(id: UUID) async -> SupabaseRecipeDetail? {
        let url = recipeDetailURL(for: id)
        guard fileManager.fileExists(atPath: url.path) else { return nil }

        do {
            let data = try Data(contentsOf: url)
            let cached = try decoder.decode(CachedRecipeDetail.self, from: data)
            return SupabaseRecipeDetail(
                recipe: cached.recipe,
                steps: cached.steps,
                ingredients: cached.ingredients
            )
        } catch {
            // Cache corrupted, remove it
            try? fileManager.removeItem(at: url)
            return nil
        }
    }

    // MARK: - Cache Management

    /// Remove a specific recipe detail from cache
    func removeRecipeDetail(id: UUID) async {
        let url = recipeDetailURL(for: id)
        try? fileManager.removeItem(at: url)
    }

    /// Clear all cached data
    func clearCache() async throws {
        if fileManager.fileExists(atPath: cacheDirectory.path) {
            try fileManager.removeItem(at: cacheDirectory)
            // Recreate directories
            try fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
            try fileManager.createDirectory(
                at: cacheDirectory.appendingPathComponent(recipeDetailsDirectory),
                withIntermediateDirectories: true
            )
        }
    }

    /// Get cache size in bytes
    func cacheSize() async -> Int64 {
        guard fileManager.fileExists(atPath: cacheDirectory.path) else { return 0 }

        var totalSize: Int64 = 0
        if let enumerator = fileManager.enumerator(at: cacheDirectory, includingPropertiesForKeys: [.fileSizeKey]) {
            // Use while-let instead of for-in to avoid makeIterator in async context
            while let fileURL = enumerator.nextObject() as? URL {
                if let size = try? fileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize {
                    totalSize += Int64(size)
                }
            }
        }
        return totalSize
    }

    // MARK: - Private Helpers

    private func recipeDetailURL(for id: UUID) -> URL {
        cacheDirectory
            .appendingPathComponent(recipeDetailsDirectory)
            .appendingPathComponent("\(id.uuidString).json")
    }
}
