package com.recipejoe.domain.model

import org.junit.Assert.assertEquals
import org.junit.Test
import java.time.Instant
import java.util.UUID

class RecipeTest {

    @Test
    fun `RecipeDetail sortedSteps returns steps in order`() {
        val step1 = RecipeStep(
            id = UUID.randomUUID(),
            recipeId = UUID.randomUUID(),
            stepNumber = 2,
            instruction = "Step 2",
            durationMinutes = 5
        )
        val step2 = RecipeStep(
            id = UUID.randomUUID(),
            recipeId = UUID.randomUUID(),
            stepNumber = 1,
            instruction = "Step 1",
            durationMinutes = 3
        )
        val step3 = RecipeStep(
            id = UUID.randomUUID(),
            recipeId = UUID.randomUUID(),
            stepNumber = 3,
            instruction = "Step 3",
            durationMinutes = 10
        )

        val recipe = Recipe(
            id = UUID.randomUUID(),
            userId = null,
            name = "Test",
            author = null,
            description = null,
            prepTimeMinutes = null,
            cookTimeMinutes = null,
            totalTimeMinutes = null,
            recipeYield = null,
            category = null,
            cuisine = null,
            rating = 0,
            isFavorite = false,
            imageUrl = null,
            sourceUrl = null,
            keywords = null,
            language = null,
            createdAt = Instant.now(),
            updatedAt = Instant.now()
        )

        val detail = RecipeDetail(
            recipe = recipe,
            steps = listOf(step1, step2, step3),
            ingredients = emptyList()
        )

        val sortedSteps = detail.sortedSteps

        assertEquals(3, sortedSteps.size)
        assertEquals("Step 1", sortedSteps[0].instruction)
        assertEquals("Step 2", sortedSteps[1].instruction)
        assertEquals("Step 3", sortedSteps[2].instruction)
    }

    @Test
    fun `RecipeDetail sortedIngredients returns ingredients in display order`() {
        val ingredient1 = RecipeIngredient(
            id = UUID.randomUUID(),
            recipeId = UUID.randomUUID(),
            ingredientId = UUID.randomUUID(),
            measurementTypeId = null,
            quantity = 2.0,
            notes = null,
            displayOrder = 3,
            ingredient = null,
            measurementType = null
        )
        val ingredient2 = RecipeIngredient(
            id = UUID.randomUUID(),
            recipeId = UUID.randomUUID(),
            ingredientId = UUID.randomUUID(),
            measurementTypeId = null,
            quantity = 1.0,
            notes = null,
            displayOrder = 1,
            ingredient = null,
            measurementType = null
        )

        val recipe = Recipe(
            id = UUID.randomUUID(),
            userId = null,
            name = "Test",
            author = null,
            description = null,
            prepTimeMinutes = null,
            cookTimeMinutes = null,
            totalTimeMinutes = null,
            recipeYield = null,
            category = null,
            cuisine = null,
            rating = 0,
            isFavorite = false,
            imageUrl = null,
            sourceUrl = null,
            keywords = null,
            language = null,
            createdAt = Instant.now(),
            updatedAt = Instant.now()
        )

        val detail = RecipeDetail(
            recipe = recipe,
            steps = emptyList(),
            ingredients = listOf(ingredient1, ingredient2)
        )

        val sortedIngredients = detail.sortedIngredients

        assertEquals(2, sortedIngredients.size)
        assertEquals(1, sortedIngredients[0].displayOrder)
        assertEquals(3, sortedIngredients[1].displayOrder)
    }

    @Test
    fun `Ingredient localizedName returns correct language`() {
        val ingredient = Ingredient(
            id = UUID.randomUUID(),
            nameEn = "Flour",
            nameDe = "Mehl",
            defaultMeasurementTypeId = null
        )

        assertEquals("Flour", ingredient.localizedName("en"))
        assertEquals("Mehl", ingredient.localizedName("de"))
        assertEquals("Flour", ingredient.localizedName("fr")) // Default to English
    }

    @Test
    fun `MeasurementType localizedAbbreviation returns correct language`() {
        val measurementType = MeasurementType(
            id = UUID.randomUUID(),
            nameEn = "Tablespoon",
            nameDe = "Esslöffel",
            abbreviationEn = "tbsp",
            abbreviationDe = "EL"
        )

        assertEquals("tbsp", measurementType.localizedAbbreviation("en"))
        assertEquals("EL", measurementType.localizedAbbreviation("de"))
    }

    @Test
    fun `RecipeIngredient formattedQuantity formats correctly`() {
        val measurementType = MeasurementType(
            id = UUID.randomUUID(),
            nameEn = "Gram",
            nameDe = "Gramm",
            abbreviationEn = "g",
            abbreviationDe = "g"
        )

        val ingredient = RecipeIngredient(
            id = UUID.randomUUID(),
            recipeId = UUID.randomUUID(),
            ingredientId = UUID.randomUUID(),
            measurementTypeId = measurementType.id,
            quantity = 250.0,
            notes = null,
            displayOrder = 1,
            ingredient = null,
            measurementType = measurementType
        )

        assertEquals("250 g", ingredient.formattedQuantity("en"))
    }

    @Test
    fun `RecipeIngredient formattedQuantity handles decimal quantities`() {
        val measurementType = MeasurementType(
            id = UUID.randomUUID(),
            nameEn = "Cup",
            nameDe = "Tasse",
            abbreviationEn = "cup",
            abbreviationDe = "Tasse"
        )

        val ingredient = RecipeIngredient(
            id = UUID.randomUUID(),
            recipeId = UUID.randomUUID(),
            ingredientId = UUID.randomUUID(),
            measurementTypeId = measurementType.id,
            quantity = 1.5,
            notes = null,
            displayOrder = 1,
            ingredient = null,
            measurementType = measurementType
        )

        assertEquals("1.5 cup", ingredient.formattedQuantity("en"))
    }

    @Test
    fun `RecipeIngredient formattedQuantity handles null quantity`() {
        val measurementType = MeasurementType(
            id = UUID.randomUUID(),
            nameEn = "Pinch",
            nameDe = "Prise",
            abbreviationEn = "pinch",
            abbreviationDe = "Prise"
        )

        val ingredient = RecipeIngredient(
            id = UUID.randomUUID(),
            recipeId = UUID.randomUUID(),
            ingredientId = UUID.randomUUID(),
            measurementTypeId = measurementType.id,
            quantity = null,
            notes = null,
            displayOrder = 1,
            ingredient = null,
            measurementType = measurementType
        )

        assertEquals("pinch", ingredient.formattedQuantity("en"))
    }
}
