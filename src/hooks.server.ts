import { createServerClient, type CookieMethodsServer } from '@supabase/ssr';
import { type Handle, redirect } from '@sveltejs/kit';
import { sequence } from '@sveltejs/kit/hooks';
import { PUBLIC_SUPABASE_PUBLISHABLE_KEY, PUBLIC_SUPABASE_URL } from '$env/static/public';

const PROTECTED_PATH_PREFIXES = ['/recipes', '/settings'];

const supabase: Handle = async ({ event, resolve }) => {
	event.locals.supabase = createServerClient(PUBLIC_SUPABASE_URL, PUBLIC_SUPABASE_PUBLISHABLE_KEY, {
		cookies: {
			getAll: () => event.cookies.getAll(),
			setAll: (cookiesToSet) => {
				for (const { name, value, options } of cookiesToSet) {
					event.cookies.set(name, value, { ...options, path: '/' });
				}
			}
		} satisfies CookieMethodsServer
	});

	/**
	 * Returns the current session paired with a verified user. `getSession()`
	 * alone reads the JWT without verifying signature; calling `getUser()`
	 * round-trips to the auth server, so we couple the two and return both.
	 */
	event.locals.safeGetSession = async () => {
		const {
			data: { session }
		} = await event.locals.supabase.auth.getSession();
		if (!session) return { session: null, user: null };

		const {
			data: { user },
			error
		} = await event.locals.supabase.auth.getUser();
		if (error) return { session: null, user: null };

		return { session, user };
	};

	return resolve(event, {
		filterSerializedResponseHeaders: (name) =>
			name === 'content-range' || name === 'x-supabase-api-version'
	});
};

const authGuard: Handle = async ({ event, resolve }) => {
	const { session, user } = await event.locals.safeGetSession();
	event.locals.session = session;
	event.locals.user = user;

	const requiresAuth = PROTECTED_PATH_PREFIXES.some((prefix) =>
		event.url.pathname.startsWith(prefix)
	);
	if (requiresAuth && !session) {
		const redirectTo = encodeURIComponent(event.url.pathname + event.url.search);
		redirect(303, `/login?redirectTo=${redirectTo}`);
	}

	if (event.url.pathname === '/login' && session) {
		redirect(303, '/recipes');
	}

	return resolve(event);
};

export const handle: Handle = sequence(supabase, authGuard);
