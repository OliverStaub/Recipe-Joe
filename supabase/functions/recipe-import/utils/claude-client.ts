// Claude API client for recipe extraction

import { RecipeImportSchema, type RecipeImport } from "../schemas.ts";
import type { ExistingIngredient, MeasurementType, JsonLdRecipe } from "../types.ts";

interface ClaudeCallOptions {
  html: string;
  jsonLd: JsonLdRecipe | null;
  existingIngredients: ExistingIngredient[];
  measurementTypes: MeasurementType[];
  targetLanguage: 'en' | 'de';
  reword: boolean; // If false, keep original text but add category prefixes
}

interface ClaudeResponse {
  data: RecipeImport;
  usage: {
    input_tokens: number;
    output_tokens: number;
  };
}

export async function callClaude(options: ClaudeCallOptions): Promise<ClaudeResponse> {
  const anthropicApiKey = Deno.env.get('ANTHROPIC_API_KEY');
  if (!anthropicApiKey) {
    throw new Error('ANTHROPIC_API_KEY not configured');
  }

  const systemPrompt = buildSystemPrompt(options);
  const userPrompt = buildUserPrompt(options);

  const response = await fetch('https://api.anthropic.com/v1/messages', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'x-api-key': anthropicApiKey,
      'anthropic-version': '2023-06-01',
    },
    body: JSON.stringify({
      model: 'claude-3-5-haiku-20241022',
      max_tokens: 8192,
      system: systemPrompt,
      messages: [
        { role: 'user', content: userPrompt },
      ],
    }),
  });

  if (!response.ok) {
    const errorText = await response.text();
    throw new Error(`Anthropic API error: ${response.status} - ${errorText}`);
  }

  const anthropicResponse = await response.json();
  const textContent = anthropicResponse.content?.[0]?.text || '';

  // Parse and validate the JSON response
  let jsonString = textContent;

  // Try to extract JSON from markdown code block if present
  const jsonMatch = textContent.match(/```(?:json)?\s*\n?([\s\S]*?)\n?```/);
  if (jsonMatch) {
    jsonString = jsonMatch[1].trim();
  }

  try {
    const parsedData = JSON.parse(jsonString);
    const validatedData = RecipeImportSchema.parse(parsedData);

    return {
      data: validatedData,
      usage: {
        input_tokens: anthropicResponse.usage?.input_tokens || 0,
        output_tokens: anthropicResponse.usage?.output_tokens || 0,
      },
    };
  } catch (parseError) {
    console.error('Failed to parse Claude response:', textContent);
    throw new Error(`Failed to parse recipe data: ${parseError instanceof Error ? parseError.message : 'Unknown error'}`);
  }
}

function buildSystemPrompt(options: ClaudeCallOptions): string {
  const { existingIngredients, measurementTypes, targetLanguage, reword } = options;

  const ingredientsList = existingIngredients.length > 0
    ? existingIngredients.map(i => `- ${i.id}: ${i.name_en} / ${i.name_de}`).join('\n')
    : 'No existing ingredients yet - all ingredients will be new.';

  const measurementsList = measurementTypes
    .map(m => `- ${m.name_en} (${m.name_de})`)
    .join('\n');

  const langName = targetLanguage === 'de' ? 'German' : 'English';

  // Build language instructions based on reword setting
  const languageInstructions = reword
    ? `## CRITICAL: Output Language = ${langName.toUpperCase()}
- Recipe name, description, category, cuisine: MUST be in ${langName}
- All step instructions: MUST be in ${langName}
- Ingredient notes: MUST be in ${langName}
- Category prefixes (prep, cook, etc.): Keep in English (they are keywords)`
    : `## CRITICAL: Keep Original Language
- Recipe name, description, category, cuisine: Keep in ORIGINAL language from source
- All step instructions: Keep in ORIGINAL language, only add category prefix
- Ingredient notes: Keep in ORIGINAL language
- Category prefixes (prep, cook, etc.): Always in English (they are keywords)
- DO NOT translate or reword anything except adding the category prefix`;

  // Build step instructions based on reword setting
  const stepInstructions = reword
    ? `## Step Formatting Rules:
- IMPORTANT: You MUST extract ALL cooking steps from the recipe. Do not skip any steps.
- Look for instructions in the HTML content if not in JSON-LD

### Core Principle: Each step = one action type with a clear outcome

### Rules:
1. **One Action Type Per Step** - Group same actions together: "Dice onions, carrots, celery into 1cm cubes"
2. **Separate Steps When:**
   - Timing differs (ingredients added at different moments)
   - Method changes (prep → cooking)
   - Waiting/checking required ("until golden brown")
   - Temperature/setting changes ("Reduce heat to low")
3. **Each Step Must Include:**
   - Action verb (imperative: dice, mix, heat, bake)
   - Quantities and ingredients
   - Success criteria: timing (5min), visual (golden), texture (soft), or temperature (180°C)
4. **Length:** Target 50-120 characters (exception: multiple ingredients may exceed)

### Category Prefixes (REQUIRED at start of each instruction):
- prep: Dice, chop, measure, prepare ingredients
- heat: Heat pan, preheat oven, temperature setup
- cook: Sauté, boil, simmer, roast - active cooking
- mix: Combine, whisk, stir, fold ingredients
- assemble: Layer, arrange, fill, shape
- bake: Oven cooking with time/temp
- rest: Cool, set, rest, chill periods
- finish: Garnish, serve, final touches

### Step Format:
category: Action verb + ingredients/quantities + success criteria

### Examples${targetLanguage === 'de' ? ' (in German)' : ''}:
${targetLanguage === 'de' ? `- "prep: Zwiebeln, Karotten, Sellerie in 1cm Würfel schneiden"
- "heat: 2 EL Öl in großem Topf bei mittlerer Hitze erhitzen"
- "cook: Gewürfeltes Gemüse hinzufügen, weich dünsten (8min)"
- "mix: Tomatenmark einrühren bis gleichmäßig verteilt (2min)"
- "bake: Bei 180°C goldbraun backen (25min)"
- "rest: Vor dem Servieren vollständig abkühlen lassen (10min)"` : `- "prep: Dice onions, carrots, celery into 1cm cubes"
- "heat: Heat 2 tbsp oil in large pot over medium heat"
- "cook: Add diced vegetables, sauté until soft (8min)"
- "mix: Stir in tomato paste until evenly distributed (2min)"
- "bake: Bake at 180°C until golden brown (25min)"
- "rest: Let cool completely before serving (10min)"`}`
    : `## Step Formatting Rules:
- IMPORTANT: You MUST extract ALL cooking steps from the recipe. Do not skip any steps.
- Keep the ORIGINAL text from the source - do NOT reword or simplify
- ONLY add a category prefix at the start of each step

### Category Prefixes (add to start of each original instruction):
- prep: Preparation steps (cutting, measuring, etc.)
- heat: Heating steps (preheat oven, heat pan, etc.)
- cook: Active cooking (sauté, boil, simmer, fry, etc.)
- mix: Mixing/combining steps
- assemble: Assembly steps
- bake: Oven cooking steps
- rest: Resting/cooling steps
- finish: Final touches, garnishing, serving

### Format:
category: [original step text unchanged]

### Example (keeping original German text):
Original: "Die Zwiebeln fein würfeln und in Butter anschwitzen"
Output: "prep: Die Zwiebeln fein würfeln und in Butter anschwitzen"`;

  return `You are a recipe extraction assistant. Extract structured recipe data from webpage content.

${languageInstructions}

## Your Task:
1. Validate the content contains a recipe. Set is_valid_recipe=false if not a recipe.
2. ${reword ? `Extract all recipe details and translate EVERYTHING to ${langName} (except category prefixes).` : 'Extract all recipe details, keeping original language (only add category prefixes to steps).'}
3. CRITICAL: For EVERY ingredient, you MUST provide BOTH:
   - name_en: The ingredient name in ENGLISH (e.g., "Garlic", "Onion", "Butter")
   - name_de: The ingredient name in GERMAN (e.g., "Knoblauch", "Zwiebel", "Butter")
   These MUST be actual translations, not duplicates of the same language!
4. ${reword ? 'Simplify cooking steps to single, clear actions. Split complex steps into multiple simpler ones.' : 'Keep original step text, only add category prefix.'}
5. Match ingredients to existing ones when possible. Set is_new=true only for unmatched ingredients.
6. Use ONLY the measurement types listed below. Map similar units to the closest match.
7. Extract the main recipe image URL from JSON-LD or HTML.

## Existing Ingredients (id: name_en / name_de):
${ingredientsList}

## Valid Measurement Types (use English name in output):
${measurementsList}

${stepInstructions}

## Image Extraction:
- Look for recipe image in JSON-LD "image" field
- If not found, look for og:image meta tag or main recipe image in HTML
- Return the full URL of the highest quality image available
- Set to null if no image found

## Output Format:
Respond with ONLY valid JSON (no markdown, no explanation). The JSON must match this schema:
{
  "is_valid_recipe": boolean,
  "error_message": string | null,
  "recipe": {
    "name": string,
    "author": string | null,
    "description": string | null,
    "prep_time_minutes": number | null,
    "cook_time_minutes": number | null,
    "recipe_yield": string | null,
    "category": string | null,
    "cuisine": string | null,
    "keywords": string[],
    "image_url": string | null
  } | null,
  "steps": [{ "step_number": number, "instruction": string, "duration_minutes": number | null }] | null,
  "ingredients": [{
    "name_en": string,
    "name_de": string,
    "quantity": number | null,
    "measurement_type": string,
    "notes": string | null,
    "is_new": boolean,
    "existing_ingredient_id": string | null
  }] | null
}`;
}

function buildUserPrompt(options: ClaudeCallOptions): string {
  const { html, jsonLd } = options;

  let content = '';

  if (jsonLd) {
    content = `## Pre-extracted JSON-LD Recipe Data:
${JSON.stringify(jsonLd, null, 2)}

## Raw HTML (for additional context, especially for cooking instructions):
${truncateHtml(html, 15000)}`;
  } else {
    content = `## Raw HTML Content:
${truncateHtml(html, 25000)}`;
  }

  return `Extract the recipe from this webpage:

${content}

Return ONLY the JSON object, no other text.`;
}

function truncateHtml(html: string, maxLength: number): string {
  // Remove scripts, styles, comments, and excessive whitespace
  let cleaned = html
    .replace(/<script[^>]*>[\s\S]*?<\/script>/gi, '')
    .replace(/<style[^>]*>[\s\S]*?<\/style>/gi, '')
    .replace(/<!--[\s\S]*?-->/g, '')
    .replace(/<nav[^>]*>[\s\S]*?<\/nav>/gi, '')
    .replace(/<footer[^>]*>[\s\S]*?<\/footer>/gi, '')
    .replace(/<header[^>]*>[\s\S]*?<\/header>/gi, '')
    .replace(/\s+/g, ' ')
    .trim();

  if (cleaned.length > maxLength) {
    cleaned = cleaned.substring(0, maxLength) + '\n... [truncated]';
  }
  return cleaned;
}

// ============================================
// TRANSCRIPT-BASED RECIPE EXTRACTION (Video)
// ============================================

import type { VideoPlatform, VideoMetadata } from '../types.ts';

interface TranscriptCallOptions {
  transcript: string;
  videoMetadata: VideoMetadata;
  existingIngredients: ExistingIngredient[];
  measurementTypes: MeasurementType[];
  targetLanguage: 'en' | 'de';
  reword: boolean;
}

/**
 * Call Claude to extract recipe from video transcript
 */
export async function callClaudeWithTranscript(options: TranscriptCallOptions): Promise<ClaudeResponse> {
  const anthropicApiKey = Deno.env.get('ANTHROPIC_API_KEY');
  if (!anthropicApiKey) {
    throw new Error('ANTHROPIC_API_KEY not configured');
  }

  const systemPrompt = buildTranscriptSystemPrompt(options);
  const userPrompt = buildTranscriptUserPrompt(options);

  const response = await fetch('https://api.anthropic.com/v1/messages', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'x-api-key': anthropicApiKey,
      'anthropic-version': '2023-06-01',
    },
    body: JSON.stringify({
      model: 'claude-3-5-haiku-20241022',
      max_tokens: 8192,
      system: systemPrompt,
      messages: [
        { role: 'user', content: userPrompt },
      ],
    }),
  });

  if (!response.ok) {
    const errorText = await response.text();
    throw new Error(`Anthropic API error: ${response.status} - ${errorText}`);
  }

  const anthropicResponse = await response.json();
  const textContent = anthropicResponse.content?.[0]?.text || '';

  // Parse and validate the JSON response
  let jsonString = textContent;

  // Try to extract JSON from markdown code block if present
  const jsonMatch = textContent.match(/```(?:json)?\s*\n?([\s\S]*?)\n?```/);
  if (jsonMatch) {
    jsonString = jsonMatch[1].trim();
  }

  try {
    const parsedData = JSON.parse(jsonString);
    const validatedData = RecipeImportSchema.parse(parsedData);

    return {
      data: validatedData,
      usage: {
        input_tokens: anthropicResponse.usage?.input_tokens || 0,
        output_tokens: anthropicResponse.usage?.output_tokens || 0,
      },
    };
  } catch (parseError) {
    console.error('Failed to parse Claude response:', textContent);
    throw new Error(`Failed to parse recipe data: ${parseError instanceof Error ? parseError.message : 'Unknown error'}`);
  }
}

function buildTranscriptSystemPrompt(options: TranscriptCallOptions): string {
  const { existingIngredients, measurementTypes, targetLanguage, reword, videoMetadata } = options;

  const ingredientsList = existingIngredients.length > 0
    ? existingIngredients.map(i => `- ${i.id}: ${i.name_en} / ${i.name_de}`).join('\n')
    : 'No existing ingredients yet - all ingredients will be new.';

  const measurementsList = measurementTypes
    .map(m => `- ${m.name_en} (${m.name_de})`)
    .join('\n');

  const langName = targetLanguage === 'de' ? 'German' : 'English';
  const platformName = videoMetadata.platform.charAt(0).toUpperCase() + videoMetadata.platform.slice(1);

  // Build language instructions based on reword setting
  const languageInstructions = reword
    ? `## CRITICAL: Output Language = ${langName.toUpperCase()}
- Recipe name, description, category, cuisine: MUST be in ${langName}
- All step instructions: MUST be in ${langName}
- Ingredient notes: MUST be in ${langName}
- Category prefixes (prep, cook, etc.): Keep in English (they are keywords)`
    : `## CRITICAL: Keep Original Language
- Recipe name, description, category, cuisine: Keep in ORIGINAL language from transcript
- All step instructions: Keep in ORIGINAL language, only add category prefix
- Ingredient notes: Keep in ORIGINAL language
- Category prefixes (prep, cook, etc.): Always in English (they are keywords)`;

  // Build description section if available
  const descriptionSection = videoMetadata.description
    ? `
## Video Description (may contain recipe details):
${videoMetadata.description.substring(0, 3000)}${videoMetadata.description.length > 3000 ? '...(truncated)' : ''}
`
    : '';

  return `You are a recipe extraction assistant specialized in extracting recipes from VIDEO TRANSCRIPTS.

## Source: ${platformName} Video
- Title: ${videoMetadata.title}
- Creator: ${videoMetadata.author}
${descriptionSection}
## Important Context: This is SPOKEN content from a cooking video
- The text is a transcript of someone speaking while cooking
- Measurements may be imprecise (e.g., "a handful", "some", "a bit of", "about")
- Convert imprecise measurements to reasonable estimates:
  - "a handful" → approximately 50g or 1/4 cup
  - "some" or "a bit" → 1-2 tablespoons for liquids/sauces, 1/4 cup for solids
  - "a pinch" → approximately 1/4 teaspoon
  - "a splash" → approximately 1-2 tablespoons
  - "season to taste" → note as "to taste" in notes field
- The speaker may skip obvious steps or mention things out of order
- There may be filler words, corrections, or tangents - focus on the recipe content

${languageInstructions}

## Your Task:
1. Validate the transcript contains recipe content. Set is_valid_recipe=false if no recipe found.
2. Extract the recipe name from context (what they're making). If unclear, use the video title.
3. ${reword ? `Extract and translate all details to ${langName}.` : 'Extract all details, keeping original language.'}
4. If a video description is provided above, use it to fill in missing details (ingredients, quantities, steps) that may not be clear in the spoken transcript.
5. CRITICAL: For EVERY ingredient, you MUST provide BOTH:
   - name_en: The ingredient name in ENGLISH
   - name_de: The ingredient name in GERMAN
   These MUST be actual translations!
6. Infer reasonable quantities when not explicitly stated based on typical recipes.
7. Structure the spoken instructions into clear, sequential cooking steps.
8. Match ingredients to existing ones when possible.
9. Use ONLY the measurement types listed below.

## Existing Ingredients (id: name_en / name_de):
${ingredientsList}

## Valid Measurement Types (use English name in output):
${measurementsList}

## Step Formatting Rules:
- Convert casual spoken instructions into clear, actionable steps
- Each step should describe ONE main action
- Add appropriate category prefixes:
  - prep: Preparation (cutting, measuring, etc.)
  - heat: Heating steps (preheat, heat pan, etc.)
  - cook: Active cooking (sauté, boil, simmer, etc.)
  - mix: Mixing/combining
  - assemble: Assembly steps
  - bake: Oven cooking
  - rest: Resting/cooling
  - finish: Garnishing, serving

### Examples${targetLanguage === 'de' ? ' (in German)' : ''}:
${targetLanguage === 'de' ? `- "prep: Zwiebeln in feine Würfel schneiden"
- "heat: Olivenöl in einer großen Pfanne erhitzen"
- "cook: Zwiebeln glasig dünsten (ca. 5 Min)"
- "mix: Alle Gewürze gut unterrühren"` : `- "prep: Dice the onions into small cubes"
- "heat: Heat olive oil in a large pan"
- "cook: Sauté onions until translucent (about 5 min)"
- "mix: Stir in all the spices until combined"`}

## Handling Missing Information:
- If prep time isn't mentioned, estimate based on complexity
- If cook time isn't mentioned, estimate based on cooking method
- If servings aren't mentioned, assume 4 servings
- Always try to extract a complete recipe even if some details are implied

## Output Format:
Respond with ONLY valid JSON (no markdown, no explanation). The JSON must match this schema:
{
  "is_valid_recipe": boolean,
  "error_message": string | null,
  "recipe": {
    "name": string,
    "author": string | null,
    "description": string | null,
    "prep_time_minutes": number | null,
    "cook_time_minutes": number | null,
    "recipe_yield": string | null,
    "category": string | null,
    "cuisine": string | null,
    "keywords": string[],
    "image_url": string | null
  } | null,
  "steps": [{ "step_number": number, "instruction": string, "duration_minutes": number | null }] | null,
  "ingredients": [{
    "name_en": string,
    "name_de": string,
    "quantity": number | null,
    "measurement_type": string,
    "notes": string | null,
    "is_new": boolean,
    "existing_ingredient_id": string | null
  }] | null
}`;
}

function buildTranscriptUserPrompt(options: TranscriptCallOptions): string {
  const { transcript, videoMetadata } = options;

  // Truncate transcript if too long (keep more than HTML since it's cleaner)
  const maxLength = 30000;
  const truncatedTranscript = transcript.length > maxLength
    ? transcript.substring(0, maxLength) + '\n... [transcript truncated]'
    : transcript;

  return `Extract the recipe from this ${videoMetadata.platform} video transcript:

## Video Information:
- Title: ${videoMetadata.title}
- Creator: ${videoMetadata.author}
- Platform: ${videoMetadata.platform}

## Transcript:
${truncatedTranscript}

Return ONLY the JSON object, no other text.`;
}
