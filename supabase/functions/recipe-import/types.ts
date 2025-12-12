// TypeScript interfaces for recipe-import Edge Function

export interface ExistingIngredient {
  id: string;
  name_en: string;
  name_de: string;
}

export interface MeasurementType {
  id: string;
  name_en: string;
  name_de: string;
  abbreviation_en: string;
  abbreviation_de: string;
}

export interface ImportRequest {
  url: string;
  language?: 'en' | 'de'; // Target language for recipe translation
  reword?: boolean; // If false, keep original text but add category prefixes
}

export interface ImportResponse {
  success: boolean;
  recipe_id?: string;
  recipe_name?: string;
  error?: string;
  stats?: {
    steps_count: number;
    ingredients_count: number;
    new_ingredients_count: number;
    tokens_used: {
      input_tokens: number;
      output_tokens: number;
    };
  };
}

export interface JsonLdRecipe {
  "@type": string;
  name?: string;
  author?: string | { name?: string; "@type"?: string };
  description?: string;
  prepTime?: string;
  cookTime?: string;
  totalTime?: string;
  recipeYield?: string | number;
  recipeCategory?: string | string[];
  recipeCuisine?: string | string[];
  recipeIngredient?: string[];
  recipeInstructions?: string[] | Array<{ "@type"?: string; text?: string; name?: string }>;
  keywords?: string | string[];
  image?: string | string[] | { url?: string };
}
