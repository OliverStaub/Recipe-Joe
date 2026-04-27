/**
 * Hand-curated Supabase database types.
 * Regenerate with `pnpm db:types` once the project is linked.
 */
export type Json = string | number | boolean | null | { [key: string]: Json | undefined } | Json[];

export type RecipeImportStatus = 'queued' | 'running' | 'done' | 'error';

export interface Database {
	public: {
		Tables: {
			recipes: {
				Row: {
					id: string;
					source_url: string;
					language: 'en' | 'de';
					name: string;
					author: string | null;
					description: string | null;
					prep_time_minutes: number | null;
					cook_time_minutes: number | null;
					total_time_minutes: number | null;
					recipe_yield: string | null;
					category: string | null;
					cuisine: string | null;
					image_url: string | null;
					keywords: string[];
					created_at: string;
					updated_at: string;
				};
				Insert: Partial<Database['public']['Tables']['recipes']['Row']> & {
					source_url: string;
					language: 'en' | 'de';
					name: string;
				};
				Update: Partial<Database['public']['Tables']['recipes']['Row']>;
				Relationships: [];
			};
			recipe_steps: {
				Row: {
					id: string;
					recipe_id: string;
					step_number: number;
					instruction: string;
					duration_minutes: number | null;
					created_at: string;
				};
				Insert: Omit<Database['public']['Tables']['recipe_steps']['Row'], 'id' | 'created_at'>;
				Update: Partial<Database['public']['Tables']['recipe_steps']['Row']>;
				Relationships: [];
			};
			recipe_ingredients: {
				Row: {
					id: string;
					recipe_id: string;
					ingredient_id: string;
					measurement_type_id: string | null;
					quantity: number | null;
					notes: string | null;
					display_order: number;
					created_at: string;
				};
				Insert: Omit<
					Database['public']['Tables']['recipe_ingredients']['Row'],
					'id' | 'created_at'
				>;
				Update: Partial<Database['public']['Tables']['recipe_ingredients']['Row']>;
				Relationships: [];
			};
			ingredients: {
				Row: {
					id: string;
					name_en: string;
					name_de: string;
					created_at: string;
				};
				Insert: Omit<Database['public']['Tables']['ingredients']['Row'], 'id' | 'created_at'>;
				Update: Partial<Database['public']['Tables']['ingredients']['Row']>;
				Relationships: [];
			};
			measurement_types: {
				Row: {
					id: string;
					name_en: string;
					name_de: string;
					abbreviation_en: string;
					abbreviation_de: string;
					created_at: string;
				};
				Insert: Omit<Database['public']['Tables']['measurement_types']['Row'], 'id' | 'created_at'>;
				Update: Partial<Database['public']['Tables']['measurement_types']['Row']>;
				Relationships: [];
			};
			user_recipes: {
				Row: {
					user_id: string;
					recipe_id: string;
					is_favorite: boolean;
					rating: number | null;
					saved_at: string;
				};
				Insert: Partial<Database['public']['Tables']['user_recipes']['Row']> & {
					user_id: string;
					recipe_id: string;
				};
				Update: Partial<Database['public']['Tables']['user_recipes']['Row']>;
				Relationships: [];
			};
			recipe_imports: {
				Row: {
					id: string;
					user_id: string;
					source_url: string;
					language: 'en' | 'de';
					status: RecipeImportStatus;
					error_message: string | null;
					recipe_id: string | null;
					created_at: string;
					updated_at: string;
				};
				Insert: Partial<Database['public']['Tables']['recipe_imports']['Row']> & {
					user_id: string;
					source_url: string;
					language: 'en' | 'de';
				};
				Update: Partial<Database['public']['Tables']['recipe_imports']['Row']>;
				Relationships: [];
			};
		};
		Views: Record<string, never>;
		Functions: Record<string, never>;
		Enums: { recipe_import_status: RecipeImportStatus };
		CompositeTypes: Record<string, never>;
	};
}
