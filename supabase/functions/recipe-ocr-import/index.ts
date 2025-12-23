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
      storage_paths,
      media_type,
      language = 'en',
      reword = true,
    }: MediaImportRequest = body;

    if (!storage_paths || !Array.isArray(storage_paths) || storage_paths.length === 0) {
      throw new Error('storage_paths array is required and must not be empty');
    }

    if (!media_type || !['image', 'pdf'].includes(media_type)) {
      throw new Error('media_type must be "image" or "pdf"');
    }

    console.log(`Importing recipe from ${storage_paths.length} ${media_type}(s): ${storage_paths.join(', ')}`);

    // Initialize Supabase client
    const supabase = getSupabaseClient();

    // Extract user ID from auth header
    const authHeader = req.headers.get('Authorization');
    let userId: string | null = null;

    if (authHeader) {
      const token = authHeader.replace('Bearer ', '');
      const { data: { user }, error: authError } = await supabase.auth.getUser(token);
      if (user && !authError) {
        userId = user.id;
        console.log(`Authenticated user: ${userId}`);
      }
    }

    if (!userId) {
      throw new Error('Authentication required');
    }

    // Step 1: Download all files from storage
    console.log(`Downloading ${storage_paths.length} file(s) from storage...`);

    const filesData: { path: string; base64: string; mediaType: string }[] = [];

    for (const storage_path of storage_paths) {
      const { data: fileData, error: downloadError } = await supabase.storage
        .from('recipe-imports')
        .download(storage_path);

      if (downloadError || !fileData) {
        throw new Error(`Failed to download file ${storage_path}: ${downloadError?.message || 'Unknown error'}`);
      }

      // Convert to base64
      const arrayBuffer = await fileData.arrayBuffer();
      const base64Data = btoa(
        new Uint8Array(arrayBuffer).reduce((data, byte) => data + String.fromCharCode(byte), '')
      );

      // Determine image media type from file extension
      const extension = storage_path.split('.').pop()?.toLowerCase() || 'jpeg';
      const imageMediaType = extension === 'png' ? 'image/png' :
                            extension === 'gif' ? 'image/gif' :
                            extension === 'webp' ? 'image/webp' : 'image/jpeg';

      filesData.push({ path: storage_path, base64: base64Data, mediaType: imageMediaType });
      console.log(`File downloaded: ${storage_path} (${arrayBuffer.byteLength} bytes)`);
    }

    // Step 2: Fetch existing data for Claude context
    const [existingIngredients, measurementTypes] = await Promise.all([
      fetchExistingIngredients(supabase),
      fetchMeasurementTypes(supabase),
    ]);

    console.log(`Found ${existingIngredients.length} existing ingredients`);
    console.log(`Found ${measurementTypes.length} measurement types`);

    // Step 3: Extract text using Claude Vision from all files
    console.log('Extracting text with Claude Vision...');

    let combinedOcrText = '';
    let totalInputTokens = 0;
    let totalOutputTokens = 0;

    if (media_type === 'pdf') {
      // For PDF, we only support single file
      const ocrResult = await extractTextFromPDF(filesData[0].base64);
      combinedOcrText = ocrResult.text;
      totalInputTokens = ocrResult.usage.input_tokens;
      totalOutputTokens = ocrResult.usage.output_tokens;
    } else {
      // For images, process each and combine text
      for (let i = 0; i < filesData.length; i++) {
        const file = filesData[i];
        const ocrResult = await extractTextFromImage(file.base64, file.mediaType);

        // Add separator between multiple images
        if (i > 0) {
          combinedOcrText += '\n\n--- Page/Image ' + (i + 1) + ' ---\n\n';
        }
        combinedOcrText += ocrResult.text;

        totalInputTokens += ocrResult.usage.input_tokens;
        totalOutputTokens += ocrResult.usage.output_tokens;

        console.log(`OCR for image ${i + 1}: ${ocrResult.text.length} characters`);
      }
    }

    const ocrResult = {
      text: combinedOcrText,
      usage: { input_tokens: totalInputTokens, output_tokens: totalOutputTokens }
    };

    console.log(`Total OCR extracted ${ocrResult.text.length} characters from ${filesData.length} file(s)`);
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
      null, // No image URL (the source was an image, not a web page with an image)
      userId
    );

    console.log(`Created recipe ${recipeId} with ${newIngredientsCount} new ingredients`);

    // Step 7: Cleanup - delete all temp files from storage
    console.log(`Cleaning up ${storage_paths.length} temporary file(s)...`);
    const { error: deleteError } = await supabase.storage
      .from('recipe-imports')
      .remove(storage_paths);

    if (deleteError) {
      console.error('Failed to delete temp files:', deleteError);
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
