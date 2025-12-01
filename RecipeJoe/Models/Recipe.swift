//
//  Recipe.swift
//  RecipeJoe
//
//  Created by Oliver Staub on 25.11.2025.
//

import Foundation
import SwiftData

@Model
final class Recipe {
    // MARK: - CloudKit Queryable Fields

    /// Recipe name/title
    @Attribute(.spotlight) var name: String

    /// Author of the recipe
    var author: String

    /// Date the recipe was created
    var dateCreated: Date

    /// Date the recipe was last modified
    var dateModified: Date

    /// Preparation time in minutes
    var prepTime: Int64

    /// Cooking time in minutes
    var cookTime: Int64

    /// Total time in minutes (prepTime + cookTime)
    var totalTime: Int64

    /// Yield/servings (e.g., "4 servings", "12 cookies")
    var recipeYield: String

    /// Category (e.g., "Dinner", "Dessert", "Breakfast")
    var recipeCategory: String

    /// Cuisine type (e.g., "Italian", "Mexican", "Japanese")
    var recipeCuisine: String

    /// Keywords for search
    var keywords: [String]

    /// List of ingredients (for search/display)
    var ingredientsList: [String]

    /// User rating 1-5, 0 = not rated
    var rating: Int64

    /// Whether marked as favorite
    var isFavorite: Bool

    /// Recipe image data (thumbnail)
    @Attribute(.externalStorage) var imageData: Data?

    // MARK: - Full Recipe Data

    /// Full schema.org JSON representation of the recipe
    /// Contains: description, instructions, nutrition, etc.
    var recipeData: String

    // MARK: - Initialization

    init(
        name: String = "",
        author: String = "",
        dateCreated: Date = Date(),
        dateModified: Date = Date(),
        prepTime: Int64 = 0,
        cookTime: Int64 = 0,
        totalTime: Int64 = 0,
        recipeYield: String = "",
        recipeCategory: String = "",
        recipeCuisine: String = "",
        keywords: [String] = [],
        ingredientsList: [String] = [],
        rating: Int64 = 0,
        isFavorite: Bool = false,
        imageData: Data? = nil,
        recipeData: String = "{}"
    ) {
        self.name = name
        self.author = author
        self.dateCreated = dateCreated
        self.dateModified = dateModified
        self.prepTime = prepTime
        self.cookTime = cookTime
        self.totalTime = totalTime
        self.recipeYield = recipeYield
        self.recipeCategory = recipeCategory
        self.recipeCuisine = recipeCuisine
        self.keywords = keywords
        self.ingredientsList = ingredientsList
        self.rating = rating
        self.isFavorite = isFavorite
        self.imageData = imageData
        self.recipeData = recipeData
    }
}

// MARK: - Computed Properties

extension Recipe {
    /// Formatted prep time string
    var formattedPrepTime: String {
        formatTime(minutes: prepTime)
    }

    /// Formatted cook time string
    var formattedCookTime: String {
        formatTime(minutes: cookTime)
    }

    /// Formatted total time string
    var formattedTotalTime: String {
        formatTime(minutes: totalTime)
    }

    private func formatTime(minutes: Int64) -> String {
        if minutes == 0 { return "N/A" }
        if minutes < 60 { return "\(minutes) min" }
        let hours = minutes / 60
        let mins = minutes % 60
        if mins == 0 { return "\(hours) hr" }
        return "\(hours) hr \(mins) min"
    }
}
