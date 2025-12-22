// Zod schemas for Claude structured output
// Note: Using .nullish() for fields Claude might omit or return as null
import { z } from "https://deno.land/x/zod@v3.22.4/mod.ts";

// Ingredient schema for Claude output
export const IngredientSchema = z.object({
  name_en: z.string().describe("Ingredient name in English"),
  name_de: z.string().describe("Ingredient name in German"),
  quantity: z.number().nullish().describe("Numeric quantity, null if 'to taste' or unspecified"),
  measurement_type: z.string().nullish().describe("Measurement unit in English (e.g., 'gram', 'cup', 'piece'), null if unspecified"),
  notes: z.string().nullish().describe("Preparation notes (e.g., 'finely chopped', 'room temperature')"),
  is_new: z.boolean().default(true).describe("True if this ingredient is not in the existing ingredients list"),
  existing_ingredient_id: z.string().nullish().describe("UUID of existing ingredient if is_new is false, null otherwise"),
});

// Step schema for Claude output
export const StepSchema = z.object({
  step_number: z.number().int().positive(),
  instruction: z.string().describe("Single action instruction, simplified and clear"),
  duration_minutes: z.number().int().nullish().describe("Estimated duration for this step in minutes"),
});

// Full recipe schema for Claude output
export const RecipeImportSchema = z.object({
  is_valid_recipe: z.boolean().describe("False if the URL does not contain a recipe"),
  error_message: z.string().nullish().describe("Error message if not a valid recipe"),
  recipe: z.object({
    name: z.string(),
    author: z.string().nullish(),
    description: z.string().nullish(),
    prep_time_minutes: z.number().int().nullish(),
    cook_time_minutes: z.number().int().nullish(),
    recipe_yield: z.string().nullish().describe("Servings or yield (e.g., '4 servings', '12 cookies')"),
    category: z.string().nullish().describe("Recipe category (e.g., 'Dinner', 'Dessert', 'Breakfast')"),
    cuisine: z.string().nullish().describe("Cuisine type (e.g., 'Italian', 'Mexican', 'German')"),
    keywords: z.array(z.string()).nullish().default([]),
    image_url: z.string().nullish().describe("URL of the main recipe image from the source website"),
  }).nullish(),
  steps: z.array(StepSchema).nullish(),
  ingredients: z.array(IngredientSchema).nullish(),
});

export type RecipeImport = z.infer<typeof RecipeImportSchema>;
export type ImportedIngredient = z.infer<typeof IngredientSchema>;
export type ImportedStep = z.infer<typeof StepSchema>;
