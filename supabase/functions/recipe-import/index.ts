// Recipe Import Edge Function
// Fetches a recipe URL, extracts data using Claude, and stores in Supabase
// Supports both traditional recipe websites and video platforms (YouTube, Instagram, TikTok)

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import type { ImportRequest, ImportResponse } from "./types.ts";
import { fetchWebpage } from "./utils/fetch-url.ts";
import { extractJsonLd } from "./utils/extract-jsonld.ts";
import { callClaude, callClaudeWithTranscript } from "./utils/claude-client.ts";
import { downloadAndUploadImage } from "./utils/image-handler.ts";
import {
  getSupabaseClient,
  fetchExistingIngredients,
  fetchMeasurementTypes,
  insertRecipe,
} from "./utils/db-operations.ts";
import {
  isVideoUrl,
  getVideoPlatform,
  extractVideoId,
  parseTimestamp,
} from "./utils/video-detector.ts";
import {
  getVideoTranscript,
  TranscriptNotAvailableError,
} from "./utils/supadata-client.ts";
import { getVideoMetadata, getWorkingYouTubeThumbnail } from "./utils/video-thumbnail.ts";
import { getTokenBalance, deductTokens, checkRateLimit, TOKEN_COSTS } from "../_shared/token-client.ts";

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
    const { url, language = 'en', reword = true, startTimestamp, endTimestamp }: ImportRequest = body;

    if (!url) {
      throw new Error('URL is required');
    }

    // Extract user ID from auth header
    const authHeader = req.headers.get('Authorization');
    let userId: string | null = null;

    if (authHeader) {
      const supabaseForAuth = getSupabaseClient();
      const token = authHeader.replace('Bearer ', '');
      const { data: { user }, error: authError } = await supabaseForAuth.auth.getUser(token);

      if (user && !authError) {
        userId = user.id;
        console.log(`Authenticated user: ${userId}`);
      } else if (authError) {
        console.error(`Auth failed: ${authError.message}`);
      }
    }

    if (!userId) {
      throw new Error('Authentication required');
    }

    // Initialize Supabase client (needed for token operations)
    const supabase = getSupabaseClient();

    // Check if this is a video URL to determine token cost
    const isVideo = isVideoUrl(url);
    const tokenCost = isVideo ? TOKEN_COSTS.video : TOKEN_COSTS.website;

    // Check rate limit before processing (150 recipes per 24 hours)
    console.log(`Checking rate limit for user ${userId}...`);
    const rateLimit = await checkRateLimit(supabase, userId);
    if (!rateLimit.allowed) {
      console.log(`Rate limit exceeded: ${rateLimit.remaining} remaining`);
      const response: ImportResponse = {
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

    // Check token balance before processing
    console.log(`Checking token balance for user ${userId}...`);
    let currentBalance: number;
    try {
      currentBalance = await getTokenBalance(supabase, userId);
      console.log(`User has ${currentBalance} tokens, needs ${tokenCost}`);
    } catch (error) {
      console.error('Failed to check token balance:', error);
      const response: ImportResponse = {
        success: false,
        error: 'Could not verify token balance. Please try again.',
      };
      return new Response(JSON.stringify(response), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200,
      });
    }

    if (currentBalance < tokenCost) {
      const response: ImportResponse = {
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

    // Step 1: Fetch existing data for Claude context
    const [existingIngredients, measurementTypes] = await Promise.all([
      fetchExistingIngredients(supabase),
      fetchMeasurementTypes(supabase),
    ]);

    console.log(`Found ${existingIngredients.length} existing ingredients`);
    console.log(`Found ${measurementTypes.length} measurement types`);

    // isVideo already checked above for token cost
    let claudeResponse;
    let videoThumbnailUrl: string | null = null;

    if (isVideo) {
      // ===== VIDEO IMPORT PIPELINE =====
      const platform = getVideoPlatform(url)!;
      const videoId = extractVideoId(url, platform);

      if (!videoId) {
        throw new Error('Could not extract video ID from URL');
      }

      console.log(`Detected ${platform} video (ID: ${videoId})`);

      // Parse timestamps (null means use full video)
      const startMs = startTimestamp ? parseTimestamp(startTimestamp) : null;
      const endMs = endTimestamp ? parseTimestamp(endTimestamp) : null;

      console.log(`Timestamp range: ${startMs ?? 'start'} - ${endMs ?? 'end'} ms`);

      // Get video metadata
      console.log('Fetching video metadata...');
      const videoMetadata = await getVideoMetadata(url, platform, videoId);
      console.log(`Video: "${videoMetadata.title}" by ${videoMetadata.author}`);

      // Get video thumbnail for recipe image
      if (platform === 'youtube') {
        videoThumbnailUrl = await getWorkingYouTubeThumbnail(videoId);
      } else {
        videoThumbnailUrl = videoMetadata.thumbnailUrl;
      }

      // Fetch transcript (with Whisper fallback)
      let transcriptText: string;
      let transcriptLanguage: string;

      try {
        console.log('Fetching video transcript...');
        const transcript = await getVideoTranscript(url, platform, {
          startMs,
          endMs,
          preferredLang: language,
        });
        transcriptText = transcript.text;
        transcriptLanguage = transcript.language;
        console.log(`Got transcript: ${transcript.segmentCount} segments, language: ${transcriptLanguage}`);
      } catch (error) {
        if (error instanceof TranscriptNotAvailableError) {
          // Supadata handles AI transcription automatically for most videos
          // This error means even AI transcription failed
          console.log('Transcript extraction failed for this video');
          const response: ImportResponse = {
            success: false,
            error: 'Could not extract transcript from this video. The video may be private, age-restricted, or unavailable.',
          };
          return new Response(JSON.stringify(response), {
            headers: { ...corsHeaders, 'Content-Type': 'application/json' },
            status: 200,
          });
        } else {
          throw error;
        }
      }

      // Call Claude with transcript
      console.log(`Calling Claude for transcript extraction (reword=${reword}, language=${language})...`);
      claudeResponse = await callClaudeWithTranscript({
        transcript: transcriptText,
        videoMetadata,
        existingIngredients,
        measurementTypes,
        targetLanguage: language as 'en' | 'de',
        reword,
      });

      console.log(`Claude used ${claudeResponse.usage.input_tokens} input tokens, ${claudeResponse.usage.output_tokens} output tokens`);

    } else {
      // ===== HTML IMPORT PIPELINE (existing logic) =====
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
      claudeResponse = await callClaude({
        html,
        jsonLd,
        existingIngredients,
        measurementTypes,
        targetLanguage: language as 'en' | 'de',
        reword,
      });

      console.log(`Claude used ${claudeResponse.usage.input_tokens} input tokens, ${claudeResponse.usage.output_tokens} output tokens`);
    }

    // Step 5: Validate recipe
    if (!claudeResponse.data.is_valid_recipe) {
      const response: ImportResponse = {
        success: false,
        error: claudeResponse.data.error_message || 'URL does not contain a valid recipe',
      };

      return new Response(JSON.stringify(response), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200,
      });
    }

    // Step 6: Download and upload image if available
    let uploadedImageUrl: string | null = null;
    // For videos, prefer the video thumbnail; otherwise use the image from recipe extraction
    const sourceImageUrl = videoThumbnailUrl || claudeResponse.data.recipe?.image_url;

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
      uploadedImageUrl,
      userId
    );

    console.log(`Created recipe ${recipeId} with ${newIngredientsCount} new ingredients`);

    // Step 8: Deduct tokens after successful import
    const importReason = isVideo ? 'import_video' : 'import_website';
    console.log(`Deducting ${tokenCost} tokens for ${importReason}...`);
    const deductResult = await deductTokens(supabase, userId, tokenCost, importReason, recipeId);

    if (!deductResult.success) {
      // Import succeeded but token deduction failed - log for manual review
      // We don't fail the request since the recipe was already created
      console.error('Token deduction failed:', deductResult.error);
    } else {
      console.log(`Tokens deducted. New balance: ${deductResult.balance}`);
    }

    const response: ImportResponse = {
      success: true,
      recipe_id: recipeId,
      recipe_name: claudeResponse.data.recipe?.name,
      tokens_deducted: tokenCost,
      tokens_remaining: deductResult.balance,
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
      status: 200,
    });
  }
});
