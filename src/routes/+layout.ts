import { createSupabase } from '$lib/supabase/client';
import type { LayoutLoad } from './$types';

export const load: LayoutLoad = async ({ data, depends, fetch }) => {
	depends('supabase:auth');

	const supabase = createSupabase(fetch);
	return {
		supabase,
		session: data.session,
		user: data.user
	};
};
