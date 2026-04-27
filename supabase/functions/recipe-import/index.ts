/**
 * recipe-import — Supabase Edge Function (fire-and-forget).
 *
 * Flow:
 *   1. Verify the caller's JWT and resolve their user id.
 *   2. Mark the `recipe_imports` row as 'running'.
 *   3. Use `EdgeRuntime.waitUntil` to do the actual extraction in the
 *      background; return 202 Accepted to the caller immediately.
 *   4. Background work: dedupe by (source_url, language), call Claude if
 *      needed, persist, link the user via `user_recipes`, mark import 'done'.
 *      Any failure flips the import row to 'error' with the message.
 *
 * Each concern lives in its own module under `lib/` for testability.
 */
import { createClient, type SupabaseClient } from '@supabase/supabase-js';
import { extractJsonLd } from './lib/extract-jsonld.ts';
import { fetchWebpage } from './lib/fetch-url.ts';
import { extractRecipe } from './lib/claude.ts';
import { persistRecipe } from './lib/persist.ts';
import { uploadImage } from './lib/image.ts';
import { ImportRequestSchema } from './lib/schemas.ts';
import { json, badRequest, unauthorized, serverError } from './lib/http.ts';

declare const EdgeRuntime: { waitUntil(promise: Promise<unknown>): void };

const REQUIRED_ENV = [
	'SUPABASE_URL',
	'SUPABASE_ANON_KEY',
	'SUPABASE_SERVICE_ROLE_KEY',
	'ANTHROPIC_API_KEY'
] as const;

Deno.serve(async (req) => {
	if (req.method === 'OPTIONS') return json({ ok: true }, 200);
	if (req.method !== 'POST') return badRequest('Method not allowed');

	for (const key of REQUIRED_ENV) {
		if (!Deno.env.get(key)) return serverError(`Missing env var: ${key}`);
	}

	const auth = req.headers.get('Authorization');
	if (!auth?.startsWith('Bearer ')) return unauthorized('Missing bearer token');

	const userClient = createClient(
		Deno.env.get('SUPABASE_URL')!,
		Deno.env.get('SUPABASE_ANON_KEY')!,
		{ global: { headers: { Authorization: auth } } }
	);
	const {
		data: { user },
		error: userError
	} = await userClient.auth.getUser();
	if (userError || !user) return unauthorized('Invalid session');

	let body: unknown;
	try {
		body = await req.json();
	} catch {
		return badRequest('Invalid JSON body');
	}
	const parsed = ImportRequestSchema.safeParse(body);
	if (!parsed.success) {
		return badRequest('Invalid request', parsed.error.flatten());
	}
	const { import_id, url, language, reword } = parsed.data;

	const admin = createClient(
		Deno.env.get('SUPABASE_URL')!,
		Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
		{ auth: { persistSession: false } }
	);

	// Verify the import row belongs to the caller before we touch anything.
	const { data: importRow, error: importErr } = await admin
		.from('recipe_imports')
		.select('id, user_id, status')
		.eq('id', import_id)
		.maybeSingle();

	if (importErr || !importRow) return badRequest('Import not found');
	if (importRow.user_id !== user.id) return unauthorized('Import does not belong to caller');
	if (importRow.status === 'done') return json({ ok: true, status: 'already_done' }, 200);

	await admin
		.from('recipe_imports')
		.update({ status: 'running', error_message: null })
		.eq('id', import_id);

	// Hand off to background — return 202 immediately.
	EdgeRuntime.waitUntil(
		runImport(admin, {
			importId: import_id,
			userId: user.id,
			url,
			language,
			reword
		}).catch(async (err) => {
			console.error('background import failed:', err);
			await markError(admin, import_id, err instanceof Error ? err.message : 'Unknown error');
		})
	);

	return json({ ok: true, status: 'accepted' }, 202);
});

interface RunImportArgs {
	importId: string;
	userId: string;
	url: string;
	language: 'en' | 'de';
	reword: boolean;
}

async function runImport(admin: SupabaseClient, args: RunImportArgs): Promise<void> {
	const { importId, userId, url, language, reword } = args;

	// Dedupe — another user may have imported this URL+language already.
	const { data: existing } = await admin
		.from('recipes')
		.select('id')
		.eq('source_url', url)
		.eq('language', language)
		.maybeSingle();

	if (existing) {
		await linkAndComplete(admin, userId, importId, existing.id);
		return;
	}

	const html = await fetchWebpage(url);
	const jsonLd = extractJsonLd(html);

	const [{ data: ingredients }, { data: measurements }] = await Promise.all([
		admin.from('ingredients').select('id, name_en, name_de'),
		admin.from('measurement_types').select('id, name_en, name_de, abbreviation_en, abbreviation_de')
	]);

	const claude = await extractRecipe({
		apiKey: Deno.env.get('ANTHROPIC_API_KEY')!,
		html,
		jsonLd,
		existingIngredients: ingredients ?? [],
		measurementTypes: measurements ?? [],
		language,
		reword
	});

	if (!claude.data.is_valid_recipe || !claude.data.recipe) {
		throw new Error(claude.data.error_message ?? 'URL does not contain a recipe');
	}

	const sourceImage = claude.data.recipe.image_url;
	const uploadedImage = sourceImage
		? await uploadImage(admin, sourceImage).catch((err) => {
				console.warn('image upload failed, continuing without:', err);
				return null;
			})
		: null;

	const { recipeId } = await persistRecipe({
		admin,
		parsed: claude.data,
		sourceUrl: url,
		language,
		imageUrl: uploadedImage,
		measurementTypes: measurements ?? []
	});

	await linkAndComplete(admin, userId, importId, recipeId);
}

async function linkAndComplete(
	admin: SupabaseClient,
	userId: string,
	importId: string,
	recipeId: string
): Promise<void> {
	await admin
		.from('user_recipes')
		.upsert(
			{ user_id: userId, recipe_id: recipeId },
			{ onConflict: 'user_id,recipe_id', ignoreDuplicates: true }
		);
	await admin
		.from('recipe_imports')
		.update({ status: 'done', recipe_id: recipeId, error_message: null })
		.eq('id', importId);
}

async function markError(admin: SupabaseClient, importId: string, message: string): Promise<void> {
	await admin
		.from('recipe_imports')
		.update({ status: 'error', error_message: message.slice(0, 1000) })
		.eq('id', importId);
}
