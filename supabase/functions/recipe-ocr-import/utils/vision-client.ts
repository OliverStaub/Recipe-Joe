// Claude Vision API client for OCR and recipe extraction

import { RecipeImportSchema, type RecipeImport } from "../../recipe-import/schemas.ts";
import type { ExistingIngredient, MeasurementType } from "../../recipe-import/types.ts";

interface VisionOCRResult {
  text: string;
  usage: {
    input_tokens: number;
    output_tokens: number;
  };
}

interface RecipeExtractionOptions {
  extractedText: string;
  existingIngredients: ExistingIngredient[];
  measurementTypes: MeasurementType[];
  targetLanguage: 'en' | 'de';
  reword: boolean;
}

interface ClaudeResponse {
  data: RecipeImport;
  usage: {
    input_tokens: number;
    output_tokens: number;
  };
}

/**
 * Extract text from image using Claude Vision API
 * Handles both printed and handwritten text
 */
export async function extractTextFromImage(
  base64Image: string,
  mediaType: string
): Promise<VisionOCRResult> {
  const anthropicApiKey = Deno.env.get('ANTHROPIC_API_KEY');
  if (!anthropicApiKey) {
    throw new Error('ANTHROPIC_API_KEY not configured');
  }

  const response = await fetch('https://api.anthropic.com/v1/messages', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'x-api-key': anthropicApiKey,
      'anthropic-version': '2023-06-01',
    },
    body: JSON.stringify({
      model: 'claude-sonnet-4-20250514',
      max_tokens: 4096,
      messages: [{
        role: 'user',
        content: [
          {
            type: 'image',
            source: {
              type: 'base64',
              media_type: mediaType,
              data: base64Image,
            },
          },
          {
            type: 'text',
            text: `Extract ALL text from this recipe image. This may be:
- A printed recipe from a cookbook or magazine
- A handwritten recipe card
- A screenshot of a recipe

IMPORTANT:
- Transcribe EVERYTHING exactly as written
- Preserve the structure (title, ingredients list, instructions)
- Include quantities, measurements, and cooking times
- If handwriting is unclear, make your best interpretation and note [unclear]
- Separate ingredients from instructions clearly

Output the complete recipe text, maintaining the original formatting where possible.`,
          },
        ],
      }],
    }),
  });

  if (!response.ok) {
    const errorText = await response.text();
    throw new Error(`Claude Vision API error: ${response.status} - ${errorText}`);
  }

  const result = await response.json();
  return {
    text: result.content[0].text,
    usage: {
      input_tokens: result.usage?.input_tokens || 0,
      output_tokens: result.usage?.output_tokens || 0,
    },
  };
}

/**
 * Extract text from multiple images using Claude Vision API
 * Combines text from all images, removing duplicates
 */
export async function extractTextFromImages(
  images: Array<{ base64: string; mediaType: string }>
): Promise<VisionOCRResult> {
  const anthropicApiKey = Deno.env.get('ANTHROPIC_API_KEY');
  if (!anthropicApiKey) {
    throw new Error('ANTHROPIC_API_KEY not configured');
  }

  // Build content array with all images
  const content: Array<{ type: string; source?: { type: string; media_type: string; data: string }; text?: string }> = [];

  for (let i = 0; i < images.length; i++) {
    content.push({
      type: 'image',
      source: {
        type: 'base64',
        media_type: images[i].mediaType,
        data: images[i].base64,
      },
    });
  }

  content.push({
    type: 'text',
    text: `You are looking at ${images.length} images that together contain ONE recipe.
These might be:
- Multiple pages of the same recipe
- Different photos of the same recipe card (front/back)
- Screenshots that continue from one to the next

IMPORTANT:
- Extract ALL text from ALL images
- Combine the content into ONE unified recipe
- REMOVE any duplicate text that appears in multiple images
- Preserve the structure (title, ingredients list, instructions)
- Include quantities, measurements, and cooking times
- If handwriting is unclear, make your best interpretation and note [unclear]
- Separate ingredients from instructions clearly

Output the complete recipe text as ONE unified recipe, with duplicates removed.`,
  });

  const response = await fetch('https://api.anthropic.com/v1/messages', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'x-api-key': anthropicApiKey,
      'anthropic-version': '2023-06-01',
    },
    body: JSON.stringify({
      model: 'claude-sonnet-4-20250514',
      max_tokens: 4096,
      messages: [{
        role: 'user',
        content,
      }],
    }),
  });

  if (!response.ok) {
    const errorText = await response.text();
    throw new Error(`Claude Vision API error: ${response.status} - ${errorText}`);
  }

  const result = await response.json();
  return {
    text: result.content[0].text,
    usage: {
      input_tokens: result.usage?.input_tokens || 0,
      output_tokens: result.usage?.output_tokens || 0,
    },
  };
}

/**
 * Extract text from PDF using Claude Vision API
 * Claude can process PDFs directly as documents
 */
export async function extractTextFromPDF(base64PDF: string): Promise<VisionOCRResult> {
  const anthropicApiKey = Deno.env.get('ANTHROPIC_API_KEY');
  if (!anthropicApiKey) {
    throw new Error('ANTHROPIC_API_KEY not configured');
  }

  const response = await fetch('https://api.anthropic.com/v1/messages', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'x-api-key': anthropicApiKey,
      'anthropic-version': '2023-06-01',
      'anthropic-beta': 'pdfs-2024-09-25',
    },
    body: JSON.stringify({
      model: 'claude-sonnet-4-20250514',
      max_tokens: 8192,
      messages: [{
        role: 'user',
        content: [
          {
            type: 'document',
            source: {
              type: 'base64',
              media_type: 'application/pdf',
              data: base64PDF,
            },
          },
          {
            type: 'text',
            text: `Extract ALL recipe content from this PDF document.

IMPORTANT:
- Find and extract ALL recipes in the document
- Include recipe titles, ingredients with quantities, and full instructions
- Preserve cooking times, temperatures, and serving sizes
- If multiple recipes exist, separate them clearly
- If handwritten content is present, transcribe as accurately as possible
- Maintain the structure of each recipe

Output the complete recipe text.`,
          },
        ],
      }],
    }),
  });

  if (!response.ok) {
    const errorText = await response.text();
    throw new Error(`Claude Vision API error: ${response.status} - ${errorText}`);
  }

  const result = await response.json();
  return {
    text: result.content[0].text,
    usage: {
      input_tokens: result.usage?.input_tokens || 0,
      output_tokens: result.usage?.output_tokens || 0,
    },
  };
}

/**
 * Process extracted text through Claude to get structured recipe data
 */
export async function extractRecipeFromText(options: RecipeExtractionOptions): Promise<ClaudeResponse> {
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

function buildSystemPrompt(options: RecipeExtractionOptions): string {
  const { existingIngredients, measurementTypes, targetLanguage, reword } = options;

  const ingredientsList = existingIngredients.length > 0
    ? existingIngredients.map(i => `- ${i.id}: ${i.name_en} / ${i.name_de}`).join('\n')
    : 'No existing ingredients yet - all ingredients will be new.';

  const measurementsList = measurementTypes
    .map(m => `- ${m.name_en} (${m.name_de})`)
    .join('\n');

  const langName = targetLanguage === 'de' ? 'German' : 'English';

  const languageInstructions = reword
    ? `## CRITICAL: Output Language = ${langName.toUpperCase()}
- Recipe name, description, category, cuisine: MUST be in ${langName}
- All step instructions: MUST be in ${langName}
- Ingredient notes: MUST be in ${langName}`
    : `## CRITICAL: Keep Original Language
- Recipe name, description, category, cuisine: Keep in ORIGINAL language from source
- All step instructions: Keep in ORIGINAL language, only add emoji prefix
- Ingredient notes: Keep in ORIGINAL language`;

  const stepInstructions = `## Step Formatting Rules:
- IMPORTANT: You MUST extract ALL cooking steps from the recipe. Do not skip any steps.
${reword ? '- Simplify cooking steps to single, clear actions.' : '- Keep the ORIGINAL text from the source - do NOT reword or simplify'}

### Emoji Prefix (REQUIRED at start of each instruction):
Choose a SINGLE fitting emoji that represents the step. Be creative and specific!

**Priority for choosing emoji:**
1. **Main ingredient** - If the step focuses on a specific ingredient, use its emoji:
   - 🧅 onion, 🥕 carrot, 🍅 tomato, 🥔 potato, 🍌 banana, 🍋 lemon, 🧄 garlic
   - 🥩 meat, 🍗 chicken, 🐟 fish, 🥚 egg, 🧀 cheese, 🥛 milk, 🧈 butter
   - 🍝 pasta, 🍚 rice, 🥖 bread, 🥬 greens, 🫑 pepper, 🍄 mushroom
2. **Cooking action** - If no specific ingredient stands out:
   - 🔪 cutting/chopping, 🔥 heating/sautéing, 💨 steaming
   - 🥄 stirring/mixing, 🫗 pouring, 🧂 seasoning
   - ♨️ baking/oven, ❄️ cooling/chilling, ⏲️ waiting/timing
3. **Tool or result** - As fallback:
   - 🍳 pan cooking, 🥘 pot cooking, 🥣 bowl mixing
   - 🍽️ plating/serving, ✨ finishing touches

### Format:
[emoji] [instruction text]

### Examples${targetLanguage === 'de' ? ' (in German)' : ''}:
${targetLanguage === 'de' ? `- "🧅 Zwiebeln in feine Würfel schneiden"
- "🔥 Öl in der Pfanne erhitzen"
- "🥕 Karotten und Sellerie hinzufügen"
- "🧀 Mit geriebenem Käse bestreuen"` : `- "🧅 Dice the onions into small cubes"
- "🔥 Heat oil in a large pan"
- "🥕 Add carrots and celery"
- "🧀 Top with grated cheese"`}`;

  return `You are a recipe extraction assistant. Extract structured recipe data from OCR-extracted text.

## Important Context: This text was extracted from an image or PDF
- The text may contain OCR errors or unclear sections
- The original may have been handwritten
- Use context to correct obvious OCR errors (e.g., "1/2" vs "1/z", "tbsp" vs "thsp")
- If quantities seem wrong, use cooking knowledge to estimate reasonable amounts

${languageInstructions}

## Your Task:
1. Validate the content contains a recipe. Set is_valid_recipe=false if not a recipe.
2. ${reword ? `Extract all recipe details and translate EVERYTHING to ${langName}.` : 'Extract all details, keeping original language (only add emoji prefix to steps).'}
3. CRITICAL: For EVERY ingredient, you MUST provide BOTH:
   - name_en: The ingredient name in ENGLISH
   - name_de: The ingredient name in GERMAN
   These MUST be actual translations, not duplicates!
4. ${reword ? 'Simplify cooking steps to single, clear actions with emoji prefix.' : 'Keep original step text, only add emoji prefix.'}
5. Match ingredients to existing ones when possible. Set is_new=true only for unmatched ingredients.
6. Use ONLY the measurement types listed below.

## Existing Ingredients (id: name_en / name_de):
${ingredientsList}

## Valid Measurement Types (use English name in output):
${measurementsList}

${stepInstructions}

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
    "image_url": null
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

function buildUserPrompt(options: RecipeExtractionOptions): string {
  const { extractedText } = options;

  // Truncate if too long
  const maxLength = 25000;
  const truncatedText = extractedText.length > maxLength
    ? extractedText.substring(0, maxLength) + '\n... [text truncated]'
    : extractedText;

  return `Extract the recipe from this OCR-extracted text:

## Extracted Text (from image/PDF):
${truncatedText}

NOTES:
- This text was extracted via OCR, so there may be minor errors
- The original may have been handwritten
- Use context to correct obvious OCR errors
- If quantities seem wrong, use cooking knowledge to estimate reasonable amounts

Return ONLY the JSON object, no other text.`;
}
