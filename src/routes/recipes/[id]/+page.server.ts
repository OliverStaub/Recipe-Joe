import { error, fail, redirect } from '@sveltejs/kit';
import { getRecipe, setFavorite, unsaveRecipe } from '$lib/server/recipes';
import type { Actions, PageServerLoad } from './$types';

export const load: PageServerLoad = async ({ locals, params }) => {
	if (!locals.user) error(401, 'Not signed in');

	const recipe = await getRecipe(locals.supabase, locals.user.id, params.id);
	if (!recipe) error(404, 'Recipe not found');

	return { recipe };
};

export const actions: Actions = {
	favorite: async ({ locals, params, request }) => {
		if (!locals.user) return fail(401);
		const data = await request.formData();
		const isFavorite = data.get('value') === 'true';
		await setFavorite(locals.supabase, locals.user.id, params.id, isFavorite);
		return { success: true };
	},
	unsave: async ({ locals, params }) => {
		if (!locals.user) return fail(401);
		await unsaveRecipe(locals.supabase, locals.user.id, params.id);
		redirect(303, '/recipes');
	}
};
