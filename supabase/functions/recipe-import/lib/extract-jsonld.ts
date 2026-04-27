/**
 * Extract a schema.org Recipe JSON-LD blob from raw HTML.
 *
 * Recipes are commonly embedded as `<script type="application/ld+json">`. We
 * walk every script tag and look for either a top-level Recipe, an array of
 * objects containing one, or a `@graph` (WordPress / Yoast convention).
 */
export interface JsonLdRecipe {
	'@type': string | string[];
	name?: string;
	author?: string | { name?: string; '@type'?: string };
	description?: string;
	prepTime?: string;
	cookTime?: string;
	totalTime?: string;
	recipeYield?: string | number;
	recipeCategory?: string | string[];
	recipeCuisine?: string | string[];
	recipeIngredient?: string[];
	recipeInstructions?: string[] | Array<{ '@type'?: string; text?: string; name?: string }>;
	keywords?: string | string[];
	image?: string | string[] | { url?: string };
}

const JSON_LD_RE = /<script[^>]*type=["']application\/ld\+json["'][^>]*>([\s\S]*?)<\/script>/gi;

export function extractJsonLd(html: string): JsonLdRecipe | null {
	for (const match of html.matchAll(JSON_LD_RE)) {
		const payload = match[1].trim();
		if (!payload) continue;

		let parsed: unknown;
		try {
			parsed = JSON.parse(payload);
		} catch {
			continue;
		}

		const found = findRecipe(parsed);
		if (found) return found;
	}
	return null;
}

function findRecipe(node: unknown): JsonLdRecipe | null {
	if (!node || typeof node !== 'object') return null;

	if (Array.isArray(node)) {
		for (const item of node) {
			const hit = findRecipe(item);
			if (hit) return hit;
		}
		return null;
	}

	const obj = node as Record<string, unknown>;
	if (isRecipeType(obj['@type'])) return obj as unknown as JsonLdRecipe;

	const graph = obj['@graph'];
	if (Array.isArray(graph)) return findRecipe(graph);

	return null;
}

function isRecipeType(value: unknown): boolean {
	if (value === 'Recipe') return true;
	return Array.isArray(value) && value.includes('Recipe');
}
