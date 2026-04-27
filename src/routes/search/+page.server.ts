import { error } from '@sveltejs/kit';
import { listSavedRecipes, searchSavedRecipes } from '$lib/server/recipes';
import type { PageServerLoad } from './$types';

export const load: PageServerLoad = async ({ locals, url }) => {
	if (!locals.user) error(401, 'Not signed in');
	const q = url.searchParams.get('q')?.trim() ?? '';
	const recipes = q
		? await searchSavedRecipes(locals.supabase, locals.user.id, q)
		: await listSavedRecipes(locals.supabase, locals.user.id);
	return { q, recipes };
};
