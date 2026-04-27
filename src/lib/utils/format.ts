/**
 * Formats minutes as a human-readable duration. Mirrors the behaviour of the
 * iOS app's TimeFormatter so labels stay consistent across platforms.
 */
export function formatDuration(minutes: number | null | undefined): string {
	if (minutes == null) return '—';
	if (minutes < 60) return `${minutes} min`;
	const h = Math.floor(minutes / 60);
	const m = minutes % 60;
	return m === 0 ? `${h} h` : `${h} h ${m} min`;
}

export function formatQuantity(quantity: number | null | undefined): string {
	if (quantity == null) return '';
	if (Number.isInteger(quantity)) return quantity.toString();
	return quantity.toFixed(quantity < 1 ? 2 : 1).replace(/\.?0+$/, '');
}
