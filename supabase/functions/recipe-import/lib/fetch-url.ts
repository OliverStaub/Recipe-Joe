const FETCH_TIMEOUT_MS = 15_000;
const USER_AGENT = 'RecipeJoe/1.0 (+https://recipejoe.app)';

export async function fetchWebpage(url: string): Promise<string> {
	const parsed = new URL(url);
	if (!['http:', 'https:'].includes(parsed.protocol)) {
		throw new Error('Only http(s) URLs are supported');
	}

	const ctrl = AbortSignal.timeout(FETCH_TIMEOUT_MS);
	const res = await fetch(url, {
		signal: ctrl,
		headers: {
			'User-Agent': USER_AGENT,
			Accept: 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
			'Accept-Language': 'en-US,en;q=0.9,de;q=0.8'
		}
	});

	if (!res.ok) throw new Error(`Fetch failed: ${res.status} ${res.statusText}`);

	const contentType = res.headers.get('content-type') ?? '';
	if (!contentType.includes('text/html') && !contentType.includes('application/xhtml')) {
		throw new Error(`Unexpected content type: ${contentType}`);
	}

	return await res.text();
}
