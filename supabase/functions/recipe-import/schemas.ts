// Zod schemas for Claude structured output
import { z } from "https://deno.land/x/zod@v3.22.4/mod.ts";

// Ingredient schema for Claude output
export const IngredientSchema = z.object({
  name_en: z.string().describe("Ingredient name in English"),
  name_de: z.string().describe("Ingredient name in German"),
  quantity: z.number().nullable().describe("Numeric quantity, null if 'to taste' or unspecified"),
  measurement_type: z.string().nullable().describe("Measurement unit in English (e.g., 'gram', 'cup', 'piece'), null if unspecified"),
  notes: z.string().nullable().describe("Preparation notes (e.g., 'finely chopped', 'room temperature')"),
  is_new: z.boolean().describe("True if this ingredient is not in the existing ingredients list"),
  existing_ingredient_id: z.string().nullable().describe("UUID of existing ingredient if is_new is false, null otherwise"),
});

// Step schema for Claude output
export const StepSchema = z.object({
  step_number: z.number().int().positive(),
  instruction: z.string().describe("Single action instruction, simplified and clear"),
  duration_minutes: z.number().int().nullable().describe("Estimated duration for this step in minutes"),
});

// Full recipe schema for Claude output
export const RecipeImportSchema = z.object({
  is_valid_recipe: z.boolean().describe("False if the URL does not contain a recipe"),
  error_message: z.string().nullish().describe("Error message if not a valid recipe"),
  recipe: z.object({
    name: z.string(),
    author: z.string().nullable(),
    description: z.string().nullable(),
    prep_time_minutes: z.number().int().nullable(),
    cook_time_minutes: z.number().int().nullable(),
    recipe_yield: z.string().nullable().describe("Servings or yield (e.g., '4 servings', '12 cookies')"),
    category: z.string().nullable().describe("Recipe category (e.g., 'Dinner', 'Dessert', 'Breakfast')"),
    cuisine: z.string().nullable().describe("Cuisine type (e.g., 'Italian', 'Mexican', 'German')"),
    keywords: z.array(z.string()),
    image_url: z.string().nullable().describe("URL of the main recipe image from the source website"),
  }).nullable(),
  steps: z.array(StepSchema).nullable(),
  ingredients: z.array(IngredientSchema).nullable(),
});

export type RecipeImport = z.infer<typeof RecipeImportSchema>;
export type ImportedIngredient = z.infer<typeof IngredientSchema>;
export type ImportedStep = z.infer<typeof StepSchema>;
