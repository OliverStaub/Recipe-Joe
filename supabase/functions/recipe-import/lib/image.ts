import type { SupabaseClient } from '@supabase/supabase-js';

const MAX_BYTES = 5 * 1024 * 1024;
const ALLOWED = new Set(['image/jpeg', 'image/png', 'image/webp']);
const FETCH_TIMEOUT_MS = 10_000;
const BUCKET = 'recipe-images';

/**
 * Downloads `imageUrl` and uploads it to the public `recipe-images` bucket.
 * Returns the public URL on success — callers treat upload failures as
 * non-fatal and proceed without an image.
 */
export async function uploadImage(admin: SupabaseClient, imageUrl: string): Promise<string> {
	const parsed = new URL(imageUrl);
	if (!['http:', 'https:'].includes(parsed.protocol)) throw new Error('Invalid image URL');

	const res = await fetch(imageUrl, {
		signal: AbortSignal.timeout(FETCH_TIMEOUT_MS),
		headers: { 'User-Agent': 'RecipeJoe/1.0 (image fetcher)', Accept: 'image/*' }
	});
	if (!res.ok) throw new Error(`Image fetch failed: ${res.status}`);

	const mime = (res.headers.get('content-type') ?? '').split(';')[0].trim().toLowerCase();
	if (!ALLOWED.has(mime)) throw new Error(`Unsupported image type: ${mime}`);

	const buffer = await res.arrayBuffer();
	if (buffer.byteLength === 0) throw new Error('Empty image data');
	if (buffer.byteLength > MAX_BYTES)
		throw new Error(`Image too large: ${(buffer.byteLength / 1024 / 1024).toFixed(1)}MB`);

	const ext = mime === 'image/png' ? 'png' : mime === 'image/webp' ? 'webp' : 'jpg';
	const path = `${crypto.randomUUID()}.${ext}`;

	const { error } = await admin.storage.from(BUCKET).upload(path, buffer, {
		contentType: mime,
		upsert: false
	});
	if (error) throw new Error(`Storage upload failed: ${error.message}`);

	const { data } = admin.storage.from(BUCKET).getPublicUrl(path);
	return data.publicUrl;
}
