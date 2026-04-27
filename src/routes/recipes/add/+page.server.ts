/**
 * Fire-and-forget recipe import.
 *
 *   1. Insert a `recipe_imports` row (status='queued') so the home page can
 *      render an "importing…" placeholder via realtime subscription.
 *   2. Kick off the edge function — we don't await its background work; it
 *      returns 202 once it's stored the import id and scheduled the work.
 *   3. If the recipe already exists (someone else imported the same URL +
 *      language), shortcut: link the user via `user_recipes` and skip the
 *      edge function entirely.
 *   4. Redirect back to /recipes so the user lands on the home screen.
 */
import { fail, redirect } from '@sveltejs/kit';
import { z } from 'zod';
import { createImport, findExistingRecipe, saveRecipeToLibrary } from '$lib/server/recipes';
import type { Actions, PageServerLoad } from './$types';

const ImportSchema = z.object({
	url: z.string().url('Enter a valid URL'),
	language: z.enum(['en', 'de']).default('en'),
	reword: z.preprocess((v) => v === 'true' || v === 'on' || v === true, z.boolean()).default(true)
});

export const load: PageServerLoad = async ({ locals }) => {
	if (!locals.user) redirect(303, '/login?redirectTo=/recipes/add');
	return {};
};

export const actions: Actions = {
	default: async ({ locals, request }) => {
		if (!locals.user) return fail(401);

		const formData = await request.formData();
		const parsed = ImportSchema.safeParse(Object.fromEntries(formData));
		if (!parsed.success) {
			return fail(400, {
				url: formData.get('url'),
				errors: parsed.error.flatten().fieldErrors
			});
		}
		const { url, language, reword } = parsed.data;

		// Shortcut: recipe already known — just save it to the user's library.
		const existing = await findExistingRecipe(locals.supabase, url, language);
		if (existing) {
			await saveRecipeToLibrary(locals.supabase, locals.user.id, existing.id);
			redirect(303, `/recipes/${existing.id}`);
		}

		// Otherwise queue an import row first so the home screen has something
		// to show, then kick the edge function — fire-and-forget.
		const importRow = await createImport(locals.supabase, locals.user.id, url, language);

		void locals.supabase.functions
			.invoke('recipe-import', {
				body: { import_id: importRow.id, url, language, reword }
			})
			.catch((err) => console.warn('edge invoke failed (will be retried by user):', err));

		redirect(303, '/recipes');
	}
};
