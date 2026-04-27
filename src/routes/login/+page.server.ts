import { fail } from '@sveltejs/kit';
import { z } from 'zod';
import type { Actions, PageServerLoad } from './$types';

const LoginSchema = z.object({
	email: z.string().email('Enter a valid email')
});

export const load: PageServerLoad = async ({ url }) => {
	return { redirectTo: url.searchParams.get('redirectTo') ?? '/recipes' };
};

export const actions: Actions = {
	otp: async ({ request, locals, url }) => {
		const data = await request.formData();
		const parsed = LoginSchema.safeParse(Object.fromEntries(data));
		if (!parsed.success) {
			return fail(400, {
				email: data.get('email'),
				errors: parsed.error.flatten().fieldErrors
			});
		}

		const redirectTo = url.searchParams.get('redirectTo') ?? '/recipes';
		const { error } = await locals.supabase.auth.signInWithOtp({
			email: parsed.data.email,
			options: {
				emailRedirectTo: `${url.origin}/auth/callback?redirectTo=${encodeURIComponent(redirectTo)}`
			}
		});

		if (error) {
			return fail(400, { email: parsed.data.email, message: error.message });
		}

		return { sent: true, email: parsed.data.email };
	}
};
