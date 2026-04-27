import { z } from 'zod';

export const ImportRequestSchema = z.object({
	import_id: z.string().uuid(),
	url: z.string().url(),
	language: z.enum(['en', 'de']).default('en'),
	reword: z.boolean().default(true)
});
export type ImportRequest = z.infer<typeof ImportRequestSchema>;

export const IngredientSchema = z.object({
	name_en: z.string(),
	name_de: z.string(),
	quantity: z.number().nullable(),
	measurement_type: z.string(),
	notes: z.string().nullable(),
	is_new: z.boolean(),
	existing_ingredient_id: z.string().nullable()
});

export const StepSchema = z.object({
	step_number: z.number().int().positive(),
	instruction: z.string(),
	duration_minutes: z.number().int().nullable()
});

export const RecipeImportSchema = z.object({
	is_valid_recipe: z.boolean(),
	error_message: z.string().nullable(),
	recipe: z
		.object({
			name: z.string(),
			author: z.string().nullable(),
			description: z.string().nullable(),
			prep_time_minutes: z.number().int().nullable(),
			cook_time_minutes: z.number().int().nullable(),
			recipe_yield: z.string().nullable(),
			category: z.string().nullable(),
			cuisine: z.string().nullable(),
			keywords: z.array(z.string()),
			image_url: z.string().nullable()
		})
		.nullable(),
	steps: z.array(StepSchema).nullable(),
	ingredients: z.array(IngredientSchema).nullable()
});
export type RecipeImport = z.infer<typeof RecipeImportSchema>;
