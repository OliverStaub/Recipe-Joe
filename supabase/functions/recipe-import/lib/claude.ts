import Anthropic from '@anthropic/sdk';
import { RecipeImportSchema, type RecipeImport } from './schemas.ts';
import type { JsonLdRecipe } from './extract-jsonld.ts';

const MODEL = 'claude-haiku-4-5-20251001';
const MAX_HTML_CHARS = 18_000;

export interface ExtractOptions {
	apiKey: string;
	html: string;
	jsonLd: JsonLdRecipe | null;
	existingIngredients: Array<{ id: string; name_en: string; name_de: string }>;
	measurementTypes: Array<{ name_en: string; name_de: string }>;
	language: 'en' | 'de';
	reword: boolean;
}

export interface ExtractResult {
	data: RecipeImport;
	usage: { input_tokens: number; output_tokens: number };
}

/**
 * Asks Claude to extract a normalised recipe from the page. We use the
 * structured-output `tool_choice` pattern so the model returns a strictly
 * shaped JSON payload — far more reliable than parsing free-form text.
 */
export async function extractRecipe(opts: ExtractOptions): Promise<ExtractResult> {
	const client = new Anthropic({ apiKey: opts.apiKey });

	const message = await client.messages.create({
		model: MODEL,
		max_tokens: 8192,
		system: buildSystemPrompt(opts),
		tools: [
			{
				name: 'submit_recipe',
				description: 'Return the structured recipe extracted from the webpage',
				input_schema: jsonSchema()
			}
		],
		tool_choice: { type: 'tool', name: 'submit_recipe' },
		messages: [{ role: 'user', content: buildUserPrompt(opts) }]
	});

	const toolUse = message.content.find((b) => b.type === 'tool_use');
	if (!toolUse || toolUse.type !== 'tool_use') {
		throw new Error('Claude did not return a tool_use block');
	}

	const validated = RecipeImportSchema.parse(toolUse.input);
	return {
		data: validated,
		usage: {
			input_tokens: message.usage.input_tokens,
			output_tokens: message.usage.output_tokens
		}
	};
}

function buildSystemPrompt(opts: ExtractOptions): string {
	const ingredientList = opts.existingIngredients.length
		? opts.existingIngredients.map((i) => `- ${i.id}: ${i.name_en} / ${i.name_de}`).join('\n')
		: '(none yet)';
	const unitList = opts.measurementTypes.map((m) => `- ${m.name_en} (${m.name_de})`).join('\n');
	const langName = opts.language === 'de' ? 'German' : 'English';

	return `You are a recipe extraction agent for the RecipeJoe app. Extract a structured recipe and call submit_recipe exactly once.

OUTPUT LANGUAGE: ${langName} for recipe.name, description, category, cuisine, step instructions, and ingredient notes. Category prefixes (prep/heat/cook/mix/assemble/bake/rest/finish) stay in English.
${
	opts.reword
		? '- Rewrite steps in clear imperative one-action lines. Each step starts with "<category>: ".'
		: '- Keep the original step text, only prepend the category prefix.'
}
- Ingredients: every ingredient MUST have BOTH name_en and name_de (real translations, never duplicates).
- Use one of the measurement units below; pick the closest match.
- Match ingredients to existing IDs when possible (set is_new=false, existing_ingredient_id=<uuid>).

Existing ingredients (id: name_en / name_de):
${ingredientList}

Valid measurement units:
${unitList}`;
}

function buildUserPrompt(opts: ExtractOptions): string {
	const html = stripHtml(opts.html).slice(0, MAX_HTML_CHARS);
	const jsonLd = opts.jsonLd
		? `\n\nJSON-LD (preferred source):\n${JSON.stringify(opts.jsonLd, null, 2)}`
		: '';
	return `Extract the recipe from this page.${jsonLd}\n\nHTML:\n${html}`;
}

function stripHtml(html: string): string {
	return html
		.replace(/<script[^>]*>[\s\S]*?<\/script>/gi, '')
		.replace(/<style[^>]*>[\s\S]*?<\/style>/gi, '')
		.replace(/<!--[\s\S]*?-->/g, '')
		.replace(/<(nav|footer|header)[^>]*>[\s\S]*?<\/\1>/gi, '')
		.replace(/\s+/g, ' ')
		.trim();
}

function jsonSchema() {
	return {
		type: 'object',
		properties: {
			is_valid_recipe: { type: 'boolean' },
			error_message: { type: ['string', 'null'] },
			recipe: {
				type: ['object', 'null'],
				properties: {
					name: { type: 'string' },
					author: { type: ['string', 'null'] },
					description: { type: ['string', 'null'] },
					prep_time_minutes: { type: ['integer', 'null'] },
					cook_time_minutes: { type: ['integer', 'null'] },
					recipe_yield: { type: ['string', 'null'] },
					category: { type: ['string', 'null'] },
					cuisine: { type: ['string', 'null'] },
					keywords: { type: 'array', items: { type: 'string' } },
					image_url: { type: ['string', 'null'] }
				},
				required: ['name', 'keywords']
			},
			steps: {
				type: ['array', 'null'],
				items: {
					type: 'object',
					properties: {
						step_number: { type: 'integer' },
						instruction: { type: 'string' },
						duration_minutes: { type: ['integer', 'null'] }
					},
					required: ['step_number', 'instruction']
				}
			},
			ingredients: {
				type: ['array', 'null'],
				items: {
					type: 'object',
					properties: {
						name_en: { type: 'string' },
						name_de: { type: 'string' },
						quantity: { type: ['number', 'null'] },
						measurement_type: { type: 'string' },
						notes: { type: ['string', 'null'] },
						is_new: { type: 'boolean' },
						existing_ingredient_id: { type: ['string', 'null'] }
					},
					required: ['name_en', 'name_de', 'measurement_type', 'is_new']
				}
			}
		},
		required: ['is_valid_recipe']
	} as const;
}
