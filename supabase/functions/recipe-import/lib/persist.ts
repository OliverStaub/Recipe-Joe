/**
 * Persist a Claude-extracted recipe into the shared `recipes` schema.
 *
 * Recipes are deduplicated by (source_url, language) — if a recipe already
 * exists, callers should never get here (the SvelteKit action checks first).
 * As a defence-in-depth measure we still UPSERT on conflict.
 */
import type { SupabaseClient } from '@supabase/supabase-js';
import type { RecipeImport } from './schemas.ts';

interface MeasurementType {
	id: string;
	name_en: string;
}

export interface PersistOptions {
	admin: SupabaseClient;
	parsed: RecipeImport;
	sourceUrl: string;
	language: 'en' | 'de';
	imageUrl: string | null;
	measurementTypes: MeasurementType[];
}

export interface PersistResult {
	recipeId: string;
	newIngredientsCount: number;
}

export async function persistRecipe(opts: PersistOptions): Promise<PersistResult> {
	const { admin, parsed, sourceUrl, language, imageUrl, measurementTypes } = opts;
	const recipe = parsed.recipe!;
	const totalMinutes = (recipe.prep_time_minutes ?? 0) + (recipe.cook_time_minutes ?? 0) || null;

	const { data: row, error } = await admin
		.from('recipes')
		.upsert(
			{
				source_url: sourceUrl,
				language,
				name: recipe.name,
				author: recipe.author,
				description: recipe.description,
				prep_time_minutes: recipe.prep_time_minutes,
				cook_time_minutes: recipe.cook_time_minutes,
				total_time_minutes: totalMinutes,
				recipe_yield: recipe.recipe_yield,
				category: recipe.category,
				cuisine: recipe.cuisine,
				keywords: recipe.keywords,
				image_url: imageUrl
			},
			{ onConflict: 'source_url,language' }
		)
		.select('id')
		.single();

	if (error || !row) throw new Error(`Insert recipe failed: ${error?.message ?? 'no row'}`);
	const recipeId = row.id as string;

	// Replace child rows so re-imports stay consistent.
	await admin.from('recipe_steps').delete().eq('recipe_id', recipeId);
	await admin.from('recipe_ingredients').delete().eq('recipe_id', recipeId);

	await insertSteps(admin, recipeId, parsed);
	const newIngredientsCount = await insertIngredients(admin, recipeId, parsed, measurementTypes);

	return { recipeId, newIngredientsCount };
}

async function insertSteps(
	admin: SupabaseClient,
	recipeId: string,
	parsed: RecipeImport
): Promise<void> {
	if (!parsed.steps?.length) return;
	const rows = parsed.steps.map((s) => ({
		recipe_id: recipeId,
		step_number: s.step_number,
		instruction: s.instruction,
		duration_minutes: s.duration_minutes
	}));
	const { error } = await admin.from('recipe_steps').insert(rows);
	if (error) throw new Error(`Insert steps failed: ${error.message}`);
}

async function insertIngredients(
	admin: SupabaseClient,
	recipeId: string,
	parsed: RecipeImport,
	measurementTypes: MeasurementType[]
): Promise<number> {
	if (!parsed.ingredients?.length) return 0;

	let newCount = 0;
	const rows: Array<{
		recipe_id: string;
		ingredient_id: string;
		measurement_type_id: string | null;
		quantity: number | null;
		notes: string | null;
		display_order: number;
	}> = [];

	for (let i = 0; i < parsed.ingredients.length; i++) {
		const ing = parsed.ingredients[i];
		const ingredientId = await resolveIngredient(admin, ing, () => newCount++);
		if (!ingredientId) continue;

		const unit = measurementTypes.find(
			(m) => m.name_en.toLowerCase() === ing.measurement_type.toLowerCase()
		);

		rows.push({
			recipe_id: recipeId,
			ingredient_id: ingredientId,
			measurement_type_id: unit?.id ?? null,
			quantity: ing.quantity,
			notes: ing.notes,
			display_order: i
		});
	}

	if (rows.length === 0) return newCount;
	const { error } = await admin.from('recipe_ingredients').insert(rows);
	if (error) throw new Error(`Insert ingredients failed: ${error.message}`);
	return newCount;
}

async function resolveIngredient(
	admin: SupabaseClient,
	ing: NonNullable<RecipeImport['ingredients']>[number],
	onCreated: () => void
): Promise<string | null> {
	if (!ing.is_new && ing.existing_ingredient_id) return ing.existing_ingredient_id;

	const { data: existing } = await admin
		.from('ingredients')
		.select('id')
		.or(`name_en.ilike.${ing.name_en},name_de.ilike.${ing.name_de}`)
		.limit(1)
		.maybeSingle();
	if (existing) return existing.id;

	const { data: created, error } = await admin
		.from('ingredients')
		.insert({ name_en: ing.name_en, name_de: ing.name_de })
		.select('id')
		.single();
	if (error || !created) return null;

	onCreated();
	return created.id;
}
