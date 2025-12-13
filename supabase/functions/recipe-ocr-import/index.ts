// Recipe OCR Import Edge Function
// Extracts recipes from images and PDFs using Claude Vision API

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import type { MediaImportRequest, MediaImportResponse } from "./types.ts";
import {
  extractTextFromImage,
  extractTextFromPDF,
  extractRecipeFromText,
} from "./utils/vision-client.ts";
import {
  getSupabaseClient,
  fetchExistingIngredients,
  fetchMeasurementTypes,
  insertRecipe,
} from "../recipe-import/utils/db-operations.ts";

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    // Parse request
    const body = await req.json();
    const {
      storage_path,
      media_type,
      language = 'en',
      reword = true,
    }: MediaImportRequest = body;

    if (!storage_path) {
      throw new Error('storage_path is required');
    }

    if (!media_type || !['image', 'pdf'].includes(media_type)) {
      throw new Error('media_type must be "image" or "pdf"');
    }

    console.log(`Importing recipe from ${media_type}: ${storage_path}`);

    // Initialize Supabase client
    const supabase = getSupabaseClient();

    // Step 1: Download file from storage
    console.log('Downloading file from storage...');
    const { data: fileData, error: downloadError } = await supabase.storage
      .from('recipe-imports')
      .download(storage_path);

    if (downloadError || !fileData) {
      throw new Error(`Failed to download file: ${downloadError?.message || 'Unknown error'}`);
    }

    // Convert to base64
    const arrayBuffer = await fileData.arrayBuffer();
    const base64Data = btoa(
      new Uint8Array(arrayBuffer).reduce((data, byte) => data + String.fromCharCode(byte), '')
    );

    console.log(`File downloaded: ${arrayBuffer.byteLength} bytes`);

    // Step 2: Fetch existing data for Claude context
    const [existingIngredients, measurementTypes] = await Promise.all([
      fetchExistingIngredients(supabase),
      fetchMeasurementTypes(supabase),
    ]);

    console.log(`Found ${existingIngredients.length} existing ingredients`);
    console.log(`Found ${measurementTypes.length} measurement types`);

    // Step 3: Extract text using Claude Vision
    console.log('Extracting text with Claude Vision...');
    let ocrResult;

    if (media_type === 'pdf') {
      ocrResult = await extractTextFromPDF(base64Data);
    } else {
      // Determine image media type from file extension
      const extension = storage_path.split('.').pop()?.toLowerCase() || 'jpeg';
      const imageMediaType = extension === 'png' ? 'image/png' :
                            extension === 'gif' ? 'image/gif' :
                            extension === 'webp' ? 'image/webp' : 'image/jpeg';
      ocrResult = await extractTextFromImage(base64Data, imageMediaType);
    }

    console.log(`OCR extracted ${ocrResult.text.length} characters`);
    console.log(`OCR used ${ocrResult.usage.input_tokens} input, ${ocrResult.usage.output_tokens} output tokens`);

    // Check if we got meaningful text
    if (!ocrResult.text || ocrResult.text.trim().length < 50) {
      const response: MediaImportResponse = {
        success: false,
        error: 'Could not extract readable text from the image. Please try a clearer photo.',
      };
      return new Response(JSON.stringify(response), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 400,
      });
    }

    // Step 4: Extract structured recipe from text
    console.log(`Calling Claude for recipe extraction (reword=${reword}, language=${language})...`);
    const claudeResponse = await extractRecipeFromText({
      extractedText: ocrResult.text,
      existingIngredients,
      measurementTypes,
      targetLanguage: language as 'en' | 'de',
      reword,
    });

    console.log(`Recipe extraction used ${claudeResponse.usage.input_tokens} input, ${claudeResponse.usage.output_tokens} output tokens`);

    // Step 5: Validate recipe
    if (!claudeResponse.data.is_valid_recipe) {
      const response: MediaImportResponse = {
        success: false,
        error: claudeResponse.data.error_message || 'No valid recipe found in the image',
      };
      return new Response(JSON.stringify(response), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 400,
      });
    }

    // Step 6: Insert into database (no source URL for media imports)
    console.log('Inserting recipe into database...');
    const { recipeId, newIngredientsCount } = await insertRecipe(
      supabase,
      claudeResponse.data,
      '', // No source URL for media imports
      measurementTypes,
      language,
      null // No image URL (the source was an image, not a web page with an image)
    );

    console.log(`Created recipe ${recipeId} with ${newIngredientsCount} new ingredients`);

    // Step 7: Cleanup - delete temp file from storage
    console.log('Cleaning up temporary file...');
    const { error: deleteError } = await supabase.storage
      .from('recipe-imports')
      .remove([storage_path]);

    if (deleteError) {
      console.error('Failed to delete temp file:', deleteError);
      // Don't fail the request, just log the error
    }

    // Calculate total tokens used
    const totalTokens = {
      input_tokens: ocrResult.usage.input_tokens + claudeResponse.usage.input_tokens,
      output_tokens: ocrResult.usage.output_tokens + claudeResponse.usage.output_tokens,
    };

    const response: MediaImportResponse = {
      success: true,
      recipe_id: recipeId,
      recipe_name: claudeResponse.data.recipe?.name,
      stats: {
        steps_count: claudeResponse.data.steps?.length || 0,
        ingredients_count: claudeResponse.data.ingredients?.length || 0,
        new_ingredients_count: newIngredientsCount,
        tokens_used: totalTokens,
      },
    };

    return new Response(JSON.stringify(response), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 200,
    });

  } catch (error) {
    console.error('Error importing recipe from media:', error);

    const response: MediaImportResponse = {
      success: false,
      error: error instanceof Error ? error.message : 'Unknown error occurred',
    };

    return new Response(JSON.stringify(response), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 500,
    });
  }
});
