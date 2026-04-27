/** Minimal helpers for consistent JSON responses + permissive CORS. */
const corsHeaders = {
	'Access-Control-Allow-Origin': '*',
	'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
	'Access-Control-Allow-Methods': 'POST, OPTIONS',
	'Content-Type': 'application/json'
};

export function json(body: unknown, status: number): Response {
	return new Response(JSON.stringify(body), { status, headers: corsHeaders });
}

export function badRequest(error: string, details?: unknown) {
	return json({ success: false, error, details }, 400);
}

export function unauthorized(error: string) {
	return json({ success: false, error }, 401);
}

export function serverError(error: string) {
	return json({ success: false, error }, 500);
}
