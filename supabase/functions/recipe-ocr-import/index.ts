// Recipe OCR Import Edge Function
// Extracts recipes from images and PDFs using Claude Vision API

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import type { MediaImportRequest, MediaImportResponse } from "./types.ts";
import {
  extractTextFromImage,
  extractTextFromImages,
  extractTextFromPDF,
  extractRecipeFromText,
} from "./utils/vision-client.ts";
import {
  getSupabaseClient,
  fetchExistingIngredients,
  fetchMeasurementTypes,
  insertRecipe,
} from "../recipe-import/utils/db-operations.ts";
import { getTokenBalance, deductTokens, checkRateLimit, TOKEN_COSTS } from "../_shared/token-client.ts";
import {
  logImportStart,
  logImportSuccess,
  logImportFailure,
  createImportTimer,
  extractErrorDetails,
  type ImportType,
} from "../_shared/import-logger.ts";

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

// Claude Vision API limit per image (5MB for base64)
// Base64 encoding adds ~33% overhead, so max raw size is ~3.75MB
const CLAUDE_MAX_IMAGE_BYTES = 3.75 * 1024 * 1024; // ~3.75MB raw = ~5MB base64

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  // Store request body for error logging (can't clone after reading)
  let requestBody: MediaImportRequest | null = null;

  try {
    // Parse request
    const body = await req.json();
    requestBody = body; // Save for error logging
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

    // Limit to max 3 images (PDFs must be single file)
    if (media_type === 'image' && storage_paths.length > 3) {
      throw new Error('Maximum 3 images allowed per import.');
    }

    if (media_type === 'pdf' && storage_paths.length > 1) {
      throw new Error('Only single PDF uploads are supported.');
    }

    // Start import timer and logging
    const importTimer = createImportTimer();
    const importType: ImportType = media_type === 'pdf' ? 'pdf' : 'image';
    const source = storage_paths.join(', ');
    console.log(`Importing recipe from ${storage_paths.length} ${media_type}(s): ${source}`);

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

    // Log import start
    logImportStart(userId, importType, source);

    // Check rate limit before processing (150 recipes per 24 hours)
    console.log(`Checking rate limit for user ${userId}...`);
    const rateLimit = await checkRateLimit(supabase, userId);
    if (!rateLimit.allowed) {
      console.log(`Rate limit exceeded: ${rateLimit.remaining} remaining`);
      const response: MediaImportResponse = {
        success: false,
        error: 'Rate limit exceeded. Maximum 150 recipes per 24 hours.',
        rate_limit_remaining: rateLimit.remaining,
        rate_limit_reset: rateLimit.resetAt.toISOString(),
      };
      return new Response(JSON.stringify(response), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200,
      });
    }

    // Check token balance before processing (media imports cost 3 tokens)
    const tokenCost = TOKEN_COSTS.media;
    console.log(`Checking token balance for user ${userId}...`);
    let currentBalance: number;
    try {
      currentBalance = await getTokenBalance(supabase, userId);
      console.log(`User has ${currentBalance} tokens, needs ${tokenCost}`);
    } catch (error) {
      console.error('Failed to check token balance:', error);
      const response: MediaImportResponse = {
        success: false,
        error: 'Could not verify token balance. Please try again.',
      };
      return new Response(JSON.stringify(response), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200,
      });
    }

    if (currentBalance < tokenCost) {
      const response: MediaImportResponse = {
        success: false,
        error: 'Insufficient tokens',
        tokens_required: tokenCost,
        tokens_available: currentBalance,
      };
      return new Response(JSON.stringify(response), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200,
      });
    }

    // Step 1: Download all files from storage
    interface ImageFile {
      path: string;
      base64: string;
      mediaType: string;
      sizeBytes: number;
    }

    const imageFiles: ImageFile[] = [];

    for (const storage_path of storage_paths) {
      console.log(`Downloading file from storage: ${storage_path}`);

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

      console.log(`File downloaded: ${storage_path} (${arrayBuffer.byteLength} bytes)`);

      imageFiles.push({
        path: storage_path,
        base64: base64Data,
        mediaType: imageMediaType,
        sizeBytes: arrayBuffer.byteLength,
      });
    }

    console.log(`Downloaded ${imageFiles.length} file(s), total size: ${imageFiles.reduce((sum, f) => sum + f.sizeBytes, 0)} bytes`);

    // Check if any image exceeds Claude's 5MB limit
    for (const file of imageFiles) {
      if (file.sizeBytes > CLAUDE_MAX_IMAGE_BYTES) {
        const sizeMB = (file.sizeBytes / (1024 * 1024)).toFixed(1);
        console.error(`Image ${file.path} exceeds Claude's 5MB limit: ${sizeMB}MB`);
        const response: MediaImportResponse = {
          success: false,
          error: 'Image too large. Please try with a smaller or lower quality image.',
        };
        return new Response(JSON.stringify(response), {
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          status: 200,
        });
      }
    }

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
      ocrResult = await extractTextFromPDF(imageFiles[0].base64);
    } else if (imageFiles.length === 1) {
      ocrResult = await extractTextFromImage(imageFiles[0].base64, imageFiles[0].mediaType);
    } else {
      // Multiple images - use the multi-image extraction
      ocrResult = await extractTextFromImages(
        imageFiles.map(f => ({ base64: f.base64, mediaType: f.mediaType }))
      );
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
        status: 200,
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
        status: 200,
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
    const allPaths = imageFiles.map(f => f.path);
    console.log(`Cleaning up ${allPaths.length} temporary file(s)`);
    const { error: deleteError } = await supabase.storage
      .from('recipe-imports')
      .remove(allPaths);

    if (deleteError) {
      console.error('Failed to delete temp files:', deleteError);
      // Don't fail the request, just log the error
    }

    // Step 8: Deduct tokens after successful import
    console.log(`Deducting ${tokenCost} tokens for import_media...`);
    const deductResult = await deductTokens(supabase, userId, tokenCost, 'import_media', recipeId);

    if (!deductResult.success) {
      // Import succeeded but token deduction failed - log for manual review
      // We don't fail the request since the recipe was already created
      console.error('Token deduction failed:', deductResult.error);
    } else {
      console.log(`Tokens deducted. New balance: ${deductResult.balance}`);
    }

    // Calculate total tokens used
    const totalTokens = {
      input_tokens: ocrResult.usage.input_tokens + claudeResponse.usage.input_tokens,
      output_tokens: ocrResult.usage.output_tokens + claudeResponse.usage.output_tokens,
    };

    // Log successful import
    const duration = importTimer.stop();
    logImportSuccess({
      user_id: userId,
      import_type: importType,
      source: source,
      recipe_id: recipeId,
      recipe_name: claudeResponse.data.recipe?.name,
      tokens_used: tokenCost,
      duration_ms: duration,
      metadata: {
        steps_count: claudeResponse.data.steps?.length || 0,
        ingredients_count: claudeResponse.data.ingredients?.length || 0,
        new_ingredients_count: newIngredientsCount,
        ocr_input_tokens: ocrResult.usage.input_tokens,
        ocr_output_tokens: ocrResult.usage.output_tokens,
        extraction_input_tokens: claudeResponse.usage.input_tokens,
        extraction_output_tokens: claudeResponse.usage.output_tokens,
        total_anthropic_input_tokens: totalTokens.input_tokens,
        total_anthropic_output_tokens: totalTokens.output_tokens,
      },
    });

    const response: MediaImportResponse = {
      success: true,
      recipe_id: recipeId,
      recipe_name: claudeResponse.data.recipe?.name,
      tokens_deducted: tokenCost,
      tokens_remaining: deductResult.balance,
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
    const { message: errorMessage, code: errorCode } = extractErrorDetails(error);
    console.error('Error importing recipe from media:', error);

    // Log failed import (use saved requestBody since we can't clone after reading)
    const storagePaths = requestBody?.storage_paths || [];
    const mediaType = requestBody?.media_type || 'image';

    // Try to get userId from auth header
    let failedUserId = 'unknown';
    const authHeader = req.headers.get('Authorization');
    if (authHeader) {
      try {
        const supabase = getSupabaseClient();
        const token = authHeader.replace('Bearer ', '');
        const { data: { user } } = await supabase.auth.getUser(token);
        if (user) failedUserId = user.id;
      } catch {
        // Ignore auth errors during error logging
      }
    }

    logImportFailure({
      user_id: failedUserId,
      import_type: mediaType === 'pdf' ? 'pdf' : 'image',
      source: storagePaths.join(', '),
      error_message: errorMessage,
      error_code: errorCode,
    });

    const response: MediaImportResponse = {
      success: false,
      error: errorMessage,
    };

    return new Response(JSON.stringify(response), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 200,
    });
  }
});
