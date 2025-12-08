// Recipe Import Edge Function
// Fetches a recipe URL, extracts data using Claude, and stores in Supabase

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import type { ImportRequest, ImportResponse } from "./types.ts";
import { fetchWebpage } from "./utils/fetch-url.ts";
import { extractJsonLd } from "./utils/extract-jsonld.ts";
import { callClaude } from "./utils/claude-client.ts";
import { downloadAndUploadImage } from "./utils/image-handler.ts";
import {
  getSupabaseClient,
  fetchExistingIngredients,
  fetchMeasurementTypes,
  insertRecipe,
} from "./utils/db-operations.ts";

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
    const { url, language = 'en', reword = true }: ImportRequest = body;

    if (!url) {
      throw new Error('URL is required');
    }

    // Validate URL format
    let parsedUrl: URL;
    try {
      parsedUrl = new URL(url);
      if (!['http:', 'https:'].includes(parsedUrl.protocol)) {
        throw new Error('Invalid URL protocol');
      }
    } catch {
      throw new Error('Invalid URL format');
    }

    console.log(`Importing recipe from: ${url}`);

    // Initialize Supabase client
    const supabase = getSupabaseClient();

    // Step 1: Fetch existing data for Claude context
    const [existingIngredients, measurementTypes] = await Promise.all([
      fetchExistingIngredients(supabase),
      fetchMeasurementTypes(supabase),
    ]);

    console.log(`Found ${existingIngredients.length} existing ingredients`);
    console.log(`Found ${measurementTypes.length} measurement types`);

    // Step 2: Fetch webpage
    console.log('Fetching webpage...');
    const html = await fetchWebpage(url);
    console.log(`Fetched ${html.length} characters of HTML`);

    // Step 3: Try to extract JSON-LD (optimization)
    const jsonLd = extractJsonLd(html);
    if (jsonLd) {
      console.log('Found JSON-LD recipe data');
    } else {
      console.log('No JSON-LD found, will parse HTML');
    }

    // Step 4: Call Claude for extraction
    console.log(`Calling Claude for recipe extraction (reword=${reword}, language=${language})...`);
    const claudeResponse = await callClaude({
      html,
      jsonLd,
      existingIngredients,
      measurementTypes,
      targetLanguage: language as 'en' | 'de',
      reword,
    });

    console.log(`Claude used ${claudeResponse.usage.input_tokens} input tokens, ${claudeResponse.usage.output_tokens} output tokens`);

    // Step 5: Validate recipe
    if (!claudeResponse.data.is_valid_recipe) {
      const response: ImportResponse = {
        success: false,
        error: claudeResponse.data.error_message || 'URL does not contain a valid recipe',
      };

      return new Response(JSON.stringify(response), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 400,
      });
    }

    // Step 6: Download and upload image if available
    let uploadedImageUrl: string | null = null;
    const sourceImageUrl = claudeResponse.data.recipe?.image_url;

    if (sourceImageUrl) {
      console.log(`Downloading recipe image from: ${sourceImageUrl}`);
      // Generate a temporary ID for the image upload (will be replaced with actual recipe ID)
      const tempId = crypto.randomUUID();
      const imageResult = await downloadAndUploadImage(sourceImageUrl, tempId, supabase);

      if (imageResult.success && imageResult.publicUrl) {
        uploadedImageUrl = imageResult.publicUrl;
        console.log(`Image uploaded successfully`);
      } else {
        console.log(`Image upload failed: ${imageResult.error} - continuing without image`);
      }
    }

    // Step 7: Insert into database
    console.log('Inserting recipe into database...');
    const { recipeId, newIngredientsCount } = await insertRecipe(
      supabase,
      claudeResponse.data,
      url,
      measurementTypes,
      language,
      uploadedImageUrl
    );

    console.log(`Created recipe ${recipeId} with ${newIngredientsCount} new ingredients`);

    const response: ImportResponse = {
      success: true,
      recipe_id: recipeId,
      recipe_name: claudeResponse.data.recipe?.name,
      stats: {
        steps_count: claudeResponse.data.steps?.length || 0,
        ingredients_count: claudeResponse.data.ingredients?.length || 0,
        new_ingredients_count: newIngredientsCount,
        tokens_used: claudeResponse.usage,
      },
    };

    return new Response(JSON.stringify(response), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 200,
    });

  } catch (error) {
    console.error('Error importing recipe:', error);

    const response: ImportResponse = {
      success: false,
      error: error instanceof Error ? error.message : 'Unknown error occurred',
    };

    return new Response(JSON.stringify(response), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 500,
    });
  }
});
