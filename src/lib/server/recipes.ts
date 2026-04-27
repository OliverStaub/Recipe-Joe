/**
 * Server-side recipe queries.
 *
 * All access is funnelled through these helpers so RLS rules + ownership
 * semantics live in one place. The queries assume the supabase client is
 * already scoped to the authenticated user (via the SSR client in hooks).
 */
import type { SupabaseClient } from '@supabase/supabase-js';
import type { Database } from '$lib/types/database';
import type {
	Recipe,
	RecipeImport,
	RecipeWithRelations,
	RecipeWithUserState
} from '$lib/types/recipe';

type Client = SupabaseClient<Database>;

export async function listSavedRecipes(
	supabase: Client,
	userId: string
): Promise<RecipeWithUserState[]> {
	const { data, error } = await supabase
		.from('user_recipes')
		.select('is_favorite, saved_at, recipes!inner(*)')
		.eq('user_id', userId)
		.order('saved_at', { ascending: false });

	if (error) throw error;
	type Joined = { is_favorite: boolean; saved_at: string; recipes: Recipe | Recipe[] };
	return (data as unknown as Joined[]).map((row) => {
		// inner join guarantees a single recipe row per user_recipes row
		const recipe = (Array.isArray(row.recipes) ? row.recipes[0] : row.recipes) as Recipe;
		return {
			...recipe,
			is_favorite: row.is_favorite,
			saved_at: row.saved_at
		};
	});
}

export async function searchSavedRecipes(
	supabase: Client,
	userId: string,
	query: string
): Promise<RecipeWithUserState[]> {
	const { data, error } = await supabase
		.from('user_recipes')
		.select('is_favorite, saved_at, recipes!inner(*)')
		.eq('user_id', userId)
		.ilike('recipes.name', `%${query}%`)
		.order('saved_at', { ascending: false });

	if (error) throw error;
	type Joined = { is_favorite: boolean; saved_at: string; recipes: Recipe | Recipe[] };
	return (data as unknown as Joined[]).map((row) => {
		// inner join guarantees a single recipe row per user_recipes row
		const recipe = (Array.isArray(row.recipes) ? row.recipes[0] : row.recipes) as Recipe;
		return {
			...recipe,
			is_favorite: row.is_favorite,
			saved_at: row.saved_at
		};
	});
}

export async function getRecipe(
	supabase: Client,
	userId: string,
	recipeId: string
): Promise<RecipeWithRelations | null> {
	const [{ data: recipe, error: recipeError }, { data: link }] = await Promise.all([
		supabase
			.from('recipes')
			.select(
				`
				*,
				recipe_steps ( id, recipe_id, step_number, instruction, duration_minutes, created_at ),
				recipe_ingredients (
					id, recipe_id, ingredient_id, measurement_type_id, quantity, notes, display_order, created_at,
					ingredients ( id, name_en, name_de ),
					measurement_types ( id, name_en, name_de, abbreviation_en, abbreviation_de )
				)
			`
			)
			.eq('id', recipeId)
			.maybeSingle(),
		supabase
			.from('user_recipes')
			.select('is_favorite')
			.eq('user_id', userId)
			.eq('recipe_id', recipeId)
			.maybeSingle()
	]);

	if (recipeError) throw recipeError;
	if (!recipe) return null;

	const result = recipe as unknown as RecipeWithRelations;
	result.is_favorite = link?.is_favorite ?? false;
	result.recipe_steps.sort((a, b) => a.step_number - b.step_number);
	result.recipe_ingredients.sort((a, b) => a.display_order - b.display_order);
	return result;
}

export async function setFavorite(
	supabase: Client,
	userId: string,
	recipeId: string,
	isFavorite: boolean
): Promise<void> {
	const { error } = await supabase
		.from('user_recipes')
		.upsert(
			{ user_id: userId, recipe_id: recipeId, is_favorite: isFavorite },
			{ onConflict: 'user_id,recipe_id' }
		);
	if (error) throw error;
}

export async function unsaveRecipe(
	supabase: Client,
	userId: string,
	recipeId: string
): Promise<void> {
	const { error } = await supabase
		.from('user_recipes')
		.delete()
		.eq('user_id', userId)
		.eq('recipe_id', recipeId);
	if (error) throw error;
}

export async function listPendingImports(
	supabase: Client,
	userId: string
): Promise<RecipeImport[]> {
	const { data, error } = await supabase
		.from('recipe_imports')
		.select('*')
		.eq('user_id', userId)
		.in('status', ['queued', 'running', 'error'])
		.order('created_at', { ascending: false });

	if (error) throw error;
	return data ?? [];
}

export async function dismissImport(
	supabase: Client,
	userId: string,
	importId: string
): Promise<void> {
	const { error } = await supabase
		.from('recipe_imports')
		.delete()
		.eq('user_id', userId)
		.eq('id', importId);
	if (error) throw error;
}

/**
 * Find a recipe that already exists for this URL+language, regardless of
 * which user originally imported it. The caller decides what to do (link the
 * current user via user_recipes vs. queue a fresh import).
 */
export async function findExistingRecipe(
	supabase: Client,
	sourceUrl: string,
	language: 'en' | 'de'
) {
	const { data, error } = await supabase
		.from('recipes')
		.select('id, name')
		.eq('source_url', sourceUrl)
		.eq('language', language)
		.maybeSingle();
	if (error) throw error;
	return data;
}

export async function saveRecipeToLibrary(
	supabase: Client,
	userId: string,
	recipeId: string
): Promise<void> {
	const { error } = await supabase
		.from('user_recipes')
		.upsert(
			{ user_id: userId, recipe_id: recipeId },
			{ onConflict: 'user_id,recipe_id', ignoreDuplicates: true }
		);
	if (error) throw error;
}

export async function createImport(
	supabase: Client,
	userId: string,
	sourceUrl: string,
	language: 'en' | 'de'
): Promise<RecipeImport> {
	const { data, error } = await supabase
		.from('recipe_imports')
		.insert({ user_id: userId, source_url: sourceUrl, language })
		.select('*')
		.single();
	if (error || !data) throw error ?? new Error('Failed to create import');
	return data;
}
