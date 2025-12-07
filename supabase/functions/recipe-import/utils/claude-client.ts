// Claude API client for recipe extraction

import { RecipeImportSchema, type RecipeImport } from "../schemas.ts";
import type { ExistingIngredient, MeasurementType, JsonLdRecipe } from "../types.ts";

interface ClaudeCallOptions {
  html: string;
  jsonLd: JsonLdRecipe | null;
  existingIngredients: ExistingIngredient[];
  measurementTypes: MeasurementType[];
  targetLanguage: 'en' | 'de';
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
  const { existingIngredients, measurementTypes, targetLanguage } = options;

  const ingredientsList = existingIngredients.length > 0
    ? existingIngredients.map(i => `- ${i.id}: ${i.name_en} / ${i.name_de}`).join('\n')
    : 'No existing ingredients yet - all ingredients will be new.';

  const measurementsList = measurementTypes
    .map(m => `- ${m.name_en} (${m.name_de})`)
    .join('\n');

  const langName = targetLanguage === 'de' ? 'German' : 'English';

  return `You are a recipe extraction assistant. Extract structured recipe data from webpage content.

## Your Task:
1. Validate the content contains a recipe. Set is_valid_recipe=false if not a recipe.
2. Extract all recipe details and translate to ${langName}.
3. ALWAYS provide BOTH English (name_en) AND German (name_de) for ingredients.
4. Simplify cooking steps to single, clear actions. Split complex steps into multiple simpler ones.
5. Match ingredients to existing ones when possible. Set is_new=true only for unmatched ingredients.
6. Use ONLY the measurement types listed below. Map similar units to the closest match.

## Existing Ingredients (id: name_en / name_de):
${ingredientsList}

## Valid Measurement Types (use English name in output):
${measurementsList}

## Step Formatting Rules:
- IMPORTANT: You MUST extract ALL cooking steps from the recipe. Do not skip any steps.
- Each step should contain only ONE action
- Use imperative mood ("Chop the onions" not "The onions should be chopped")
- Include specific times/temperatures when mentioned
- Keep steps concise but complete
- If steps are numbered in the original, preserve the order
- Look for instructions in the HTML content if not in JSON-LD

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
    "keywords": string[]
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
