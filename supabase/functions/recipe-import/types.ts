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
  startTimestamp?: string; // Optional start time for video (MM:SS or HH:MM:SS)
  endTimestamp?: string; // Optional end time for video (MM:SS or HH:MM:SS)
  import_id?: string; // Optional client-generated UUID for job tracking
}

// Video-specific types
export type VideoPlatform = 'youtube' | 'instagram' | 'tiktok';

export interface TranscriptSegment {
  text: string;
  offset: number; // Start time in milliseconds
  duration: number; // Duration in milliseconds
}

export interface VideoMetadata {
  title: string;
  author: string;
  description: string | null; // Video description (may contain recipe details)
  thumbnailUrl: string | null;
  duration: number; // Duration in seconds
  platform: VideoPlatform;
  videoId: string;
}

export interface ImportResponse {
  success: boolean;
  import_id?: string; // Job ID for status tracking
  recipe_id?: string;
  recipe_name?: string;
  error?: string;
  // Token balance info
  tokens_deducted?: number;
  tokens_remaining?: number;
  tokens_required?: number;
  tokens_available?: number;
  // Rate limiting info
  rate_limit_remaining?: number;
  rate_limit_reset?: string;
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
