// Supadata.ai API client for fetching video transcripts

import { TranscriptSegment, VideoPlatform } from '../types.ts';

const SUPADATA_BASE_URL = 'https://api.supadata.ai/v1';

interface SupadataTranscriptResponse {
  content: TranscriptSegment[];
  lang: string;
}

interface SupadataError {
  error: string;
  message?: string;
}

export class TranscriptNotAvailableError extends Error {
  constructor(message: string = 'No transcript available for this video') {
    super(message);
    this.name = 'TranscriptNotAvailableError';
  }
}

export class VideoNotFoundError extends Error {
  constructor(message: string = 'Video not found or unavailable') {
    super(message);
    this.name = 'VideoNotFoundError';
  }
}

/**
 * Get the Supadata API endpoint for a video platform
 */
function getEndpointForPlatform(platform: VideoPlatform): string {
  switch (platform) {
    case 'youtube':
      return `${SUPADATA_BASE_URL}/youtube/transcript`;
    case 'instagram':
      return `${SUPADATA_BASE_URL}/instagram/transcript`;
    case 'tiktok':
      return `${SUPADATA_BASE_URL}/tiktok/transcript`;
    default:
      throw new Error(`Unsupported platform: ${platform}`);
  }
}

/**
 * Fetch transcript from Supadata.ai API
 */
export async function fetchTranscript(
  url: string,
  platform: VideoPlatform,
  preferredLang?: string
): Promise<{ segments: TranscriptSegment[]; language: string }> {
  const endpoint = getEndpointForPlatform(platform);
  const apiKey = Deno.env.get('SUPADATA_API_KEY');

  const params = new URLSearchParams({ url });
  if (preferredLang) {
    params.append('lang', preferredLang);
  }

  const headers: Record<string, string> = {
    'Accept': 'application/json',
  };

  // Add API key if configured (for tracking usage and higher rate limits)
  if (apiKey) {
    headers['x-api-key'] = apiKey;
  }

  const response = await fetch(`${endpoint}?${params.toString()}`, {
    method: 'GET',
    headers,
  });

  if (!response.ok) {
    const errorText = await response.text();
    let errorData: SupadataError | null = null;

    try {
      errorData = JSON.parse(errorText);
    } catch {
      // Not JSON, use raw text
    }

    if (response.status === 404) {
      throw new VideoNotFoundError(errorData?.message || 'Video not found');
    }

    if (response.status === 400 || response.status === 422) {
      // Often indicates no captions available
      throw new TranscriptNotAvailableError(
        errorData?.message || 'No transcript available for this video'
      );
    }

    throw new Error(
      `Supadata API error (${response.status}): ${errorData?.message || errorText}`
    );
  }

  const data: SupadataTranscriptResponse = await response.json();

  if (!data.content || data.content.length === 0) {
    throw new TranscriptNotAvailableError();
  }

  return {
    segments: data.content,
    language: data.lang || 'unknown',
  };
}

/**
 * Filter transcript segments by timestamp range
 * If startMs is null, starts from beginning
 * If endMs is null, goes to end of video (covers whole video by default)
 */
export function filterByTimestamp(
  segments: TranscriptSegment[],
  startMs: number | null,
  endMs: number | null
): TranscriptSegment[] {
  return segments.filter((segment) => {
    // If no start timestamp, include from beginning
    if (startMs !== null && segment.offset < startMs) {
      return false;
    }
    // If no end timestamp, include to the end (whole video)
    if (endMs !== null && segment.offset > endMs) {
      return false;
    }
    return true;
  });
}

/**
 * Convert transcript segments to a single text string
 */
export function segmentsToText(segments: TranscriptSegment[]): string {
  return segments.map((s) => s.text.trim()).join(' ');
}

/**
 * Fetch and process transcript with optional timestamp filtering
 * Returns the full video transcript by default if no timestamps provided
 */
export async function getVideoTranscript(
  url: string,
  platform: VideoPlatform,
  options?: {
    startMs?: number | null;
    endMs?: number | null;
    preferredLang?: string;
  }
): Promise<{ text: string; language: string; segmentCount: number }> {
  const { segments, language } = await fetchTranscript(
    url,
    platform,
    options?.preferredLang
  );

  // Default: include all segments (whole video)
  const startMs = options?.startMs ?? null;
  const endMs = options?.endMs ?? null;

  const filteredSegments = filterByTimestamp(segments, startMs, endMs);

  if (filteredSegments.length === 0) {
    throw new Error(
      'No transcript content found in the specified time range. Try adjusting the timestamps or leave them empty to use the full video.'
    );
  }

  return {
    text: segmentsToText(filteredSegments),
    language,
    segmentCount: filteredSegments.length,
  };
}
