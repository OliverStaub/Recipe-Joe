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
