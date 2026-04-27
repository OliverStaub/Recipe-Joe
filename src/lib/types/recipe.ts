import type { Database, RecipeImportStatus } from './database';

export type Recipe = Database['public']['Tables']['recipes']['Row'];
export type RecipeStep = Database['public']['Tables']['recipe_steps']['Row'];
export type RecipeIngredient = Database['public']['Tables']['recipe_ingredients']['Row'];
export type Ingredient = Database['public']['Tables']['ingredients']['Row'];
export type MeasurementType = Database['public']['Tables']['measurement_types']['Row'];
export type UserRecipe = Database['public']['Tables']['user_recipes']['Row'];
export type RecipeImport = Database['public']['Tables']['recipe_imports']['Row'];
export type { RecipeImportStatus };

/**
 * What the home page shows: the shared recipe joined with the current user's
 * library state (favorite + saved_at).
 */
export interface RecipeWithUserState extends Recipe {
	is_favorite: boolean;
	saved_at: string;
}

/**
 * Recipe detail view — recipe + relations + per-user state.
 */
export interface RecipeWithRelations extends Recipe {
	is_favorite: boolean;
	recipe_steps: RecipeStep[];
	recipe_ingredients: Array<
		RecipeIngredient & {
			ingredients: Pick<Ingredient, 'id' | 'name_en' | 'name_de'> | null;
			measurement_types: Pick<
				MeasurementType,
				'id' | 'name_en' | 'name_de' | 'abbreviation_en' | 'abbreviation_de'
			> | null;
		}
	>;
}
