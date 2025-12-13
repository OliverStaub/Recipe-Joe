// Database operations for recipe import

import { createClient, SupabaseClient } from "https://esm.sh/@supabase/supabase-js@2";
import type { RecipeImport } from "../schemas.ts";
import type { ExistingIngredient, MeasurementType } from "../types.ts";

export function getSupabaseClient(): SupabaseClient {
  const supabaseUrl = Deno.env.get('SUPABASE_URL');
  const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');

  if (!supabaseUrl || !supabaseServiceKey) {
    throw new Error('Missing Supabase environment variables');
  }

  return createClient(supabaseUrl, supabaseServiceKey);
}

export async function fetchExistingIngredients(
  supabase: SupabaseClient
): Promise<ExistingIngredient[]> {
  const { data, error } = await supabase
    .from('ingredients')
    .select('id, name_en, name_de')
    .order('name_en');

  if (error) {
    console.error('Failed to fetch ingredients:', error);
    return []; // Return empty array on error, don't fail the import
  }

  return data || [];
}

export async function fetchMeasurementTypes(
  supabase: SupabaseClient
): Promise<MeasurementType[]> {
  const { data, error } = await supabase
    .from('measurement_types')
    .select('id, name_en, name_de, abbreviation_en, abbreviation_de');

  if (error) {
    throw new Error(`Failed to fetch measurement types: ${error.message}`);
  }

  return data || [];
}

interface InsertResult {
  recipeId: string;
  newIngredientsCount: number;
}

export async function insertRecipe(
  supabase: SupabaseClient,
  recipeData: RecipeImport,
  sourceUrl: string,
  measurementTypes: MeasurementType[],
  language: string = 'en',
  imageUrl?: string | null,
  userId?: string | null
): Promise<InsertResult> {
  const recipe = recipeData.recipe;

  if (!recipe) {
    throw new Error('No recipe data to insert');
  }

  // 1. Insert the recipe
  const { data: recipeRow, error: recipeError } = await supabase
    .from('recipes')
    .insert({
      user_id: userId || null, // User ID from auth, required for RLS
      name: recipe.name,
      author: recipe.author,
      description: recipe.description,
      prep_time_minutes: recipe.prep_time_minutes,
      cook_time_minutes: recipe.cook_time_minutes,
      total_time_minutes: (recipe.prep_time_minutes || 0) + (recipe.cook_time_minutes || 0) || null,
      recipe_yield: recipe.recipe_yield,
      category: recipe.category,
      cuisine: recipe.cuisine,
      keywords: recipe.keywords,
      source_url: sourceUrl,
      language: language,
      image_url: imageUrl || null,
    })
    .select('id')
    .single();

  if (recipeError) {
    throw new Error(`Failed to insert recipe: ${recipeError.message}`);
  }

  const recipeId = recipeRow.id;

  // 2. Insert steps
  if (recipeData.steps && recipeData.steps.length > 0) {
    const stepsToInsert = recipeData.steps.map(step => ({
      recipe_id: recipeId,
      step_number: step.step_number,
      instruction: step.instruction,
      duration_minutes: step.duration_minutes,
    }));

    const { error: stepsError } = await supabase
      .from('recipe_steps')
      .insert(stepsToInsert);

    if (stepsError) {
      console.error('Failed to insert steps:', stepsError);
      // Continue - steps are not critical
    }
  }

  // 3. Insert ingredients (create new ones if needed)
  let newIngredientsCount = 0;

  if (recipeData.ingredients && recipeData.ingredients.length > 0) {
    const ingredientsToInsert = [];

    for (let i = 0; i < recipeData.ingredients.length; i++) {
      const ing = recipeData.ingredients[i];
      let ingredientId: string | null = null;

      // If Claude provided an existing ingredient ID, verify it exists
      if (ing.existing_ingredient_id && !ing.is_new) {
        const { data: existingById } = await supabase
          .from('ingredients')
          .select('id')
          .eq('id', ing.existing_ingredient_id)
          .maybeSingle();

        if (existingById) {
          ingredientId = existingById.id;
        }
      }

      // If no valid ID yet, try to find by name or create new
      if (!ingredientId) {
        // First check if ingredient already exists (by name)
        // Try matching by English name first, then German name
        let existingIng = null;

        const { data: matchByEn } = await supabase
          .from('ingredients')
          .select('id')
          .ilike('name_en', ing.name_en)
          .limit(1)
          .maybeSingle();

        if (matchByEn) {
          existingIng = matchByEn;
        } else {
          const { data: matchByDe } = await supabase
            .from('ingredients')
            .select('id')
            .ilike('name_de', ing.name_de)
            .limit(1)
            .maybeSingle();
          existingIng = matchByDe;
        }

        if (existingIng) {
          ingredientId = existingIng.id;
        } else {
          // Create new ingredient
          const { data: newIng, error: ingError } = await supabase
            .from('ingredients')
            .insert({
              name_en: ing.name_en,
              name_de: ing.name_de,
            })
            .select('id')
            .single();

          if (ingError) {
            console.error('Failed to insert ingredient:', ing.name_en, ingError);
            continue; // Skip this ingredient
          }

          ingredientId = newIng.id;
          newIngredientsCount++;
        }
      }

      if (!ingredientId) continue;

      // Find measurement type ID
      const measurementType = measurementTypes.find(
        m => m.name_en.toLowerCase() === ing.measurement_type.toLowerCase()
      );

      ingredientsToInsert.push({
        recipe_id: recipeId,
        ingredient_id: ingredientId,
        measurement_type_id: measurementType?.id || null,
        quantity: ing.quantity,
        notes: ing.notes,
        display_order: i,
      });
    }

    if (ingredientsToInsert.length > 0) {
      const { error: recipeIngError } = await supabase
        .from('recipe_ingredients')
        .insert(ingredientsToInsert);

      if (recipeIngError) {
        console.error('Failed to insert recipe ingredients:', recipeIngError);
        // Continue - we still have the recipe
      }
    }
  }

  return { recipeId, newIngredientsCount };
}
