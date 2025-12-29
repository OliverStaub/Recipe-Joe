// TypeScript interfaces for recipe-ocr-import Edge Function

export interface MediaImportRequest {
  storage_paths: string[];
  media_type: 'image' | 'pdf';
  language?: 'en' | 'de';
  reword?: boolean;
}

export interface MediaImportResponse {
  success: boolean;
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
