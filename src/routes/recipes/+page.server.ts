import { error } from '@sveltejs/kit';
import { dismissImport, listPendingImports, listSavedRecipes } from '$lib/server/recipes';
import type { Actions, PageServerLoad } from './$types';

export const load: PageServerLoad = async ({ locals }) => {
	if (!locals.user) error(401, 'Not signed in');
	const [recipes, imports] = await Promise.all([
		listSavedRecipes(locals.supabase, locals.user.id),
		listPendingImports(locals.supabase, locals.user.id)
	]);
	return { recipes, imports };
};

export const actions: Actions = {
	dismissImport: async ({ locals, request }) => {
		if (!locals.user) error(401);
		const data = await request.formData();
		const id = data.get('id');
		if (typeof id === 'string') {
			await dismissImport(locals.supabase, locals.user.id, id);
		}
		return { success: true };
	}
};
