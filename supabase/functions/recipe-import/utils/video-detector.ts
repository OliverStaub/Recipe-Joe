// Video platform detection and URL parsing utilities

import { VideoPlatform } from '../types.ts';

// URL patterns for supported video platforms
const VIDEO_PATTERNS: Record<VideoPlatform, RegExp[]> = {
  youtube: [
    /(?:youtube\.com\/watch\?.*v=|youtube\.com\/shorts\/|youtu\.be\/)([a-zA-Z0-9_-]{11})/i,
  ],
  instagram: [
    /instagram\.com\/(?:reel|p)\/([a-zA-Z0-9_-]+)/i,
  ],
  tiktok: [
    /tiktok\.com\/@[\w.-]+\/video\/(\d+)/i,
    /vm\.tiktok\.com\/([a-zA-Z0-9]+)/i,
  ],
};

/**
 * Check if a URL is from a supported video platform
 */
export function isVideoUrl(url: string): boolean {
  return getVideoPlatform(url) !== null;
}

/**
 * Determine which video platform a URL belongs to
 */
export function getVideoPlatform(url: string): VideoPlatform | null {
  for (const [platform, patterns] of Object.entries(VIDEO_PATTERNS)) {
    for (const pattern of patterns) {
      if (pattern.test(url)) {
        return platform as VideoPlatform;
      }
    }
  }
  return null;
}

/**
 * Extract video ID from a video platform URL
 */
export function extractVideoId(url: string, platform?: VideoPlatform): string | null {
  const detectedPlatform = platform || getVideoPlatform(url);
  if (!detectedPlatform) return null;

  const patterns = VIDEO_PATTERNS[detectedPlatform];
  for (const pattern of patterns) {
    const match = url.match(pattern);
    if (match && match[1]) {
      return match[1];
    }
  }
  return null;
}

/**
 * Parse timestamp string (MM:SS or HH:MM:SS) to milliseconds
 */
export function parseTimestamp(timestamp: string): number | null {
  if (!timestamp || timestamp.trim() === '') return null;

  const parts = timestamp.trim().split(':').map(Number);

  if (parts.some(isNaN)) return null;

  if (parts.length === 2) {
    // MM:SS format
    const [minutes, seconds] = parts;
    if (minutes < 0 || seconds < 0 || seconds >= 60) return null;
    return (minutes * 60 + seconds) * 1000;
  } else if (parts.length === 3) {
    // HH:MM:SS format
    const [hours, minutes, seconds] = parts;
    if (hours < 0 || minutes < 0 || minutes >= 60 || seconds < 0 || seconds >= 60) return null;
    return (hours * 3600 + minutes * 60 + seconds) * 1000;
  }

  return null;
}

/**
 * Get the full video URL for API calls (normalize shortened URLs)
 */
export function getNormalizedVideoUrl(url: string, platform: VideoPlatform, videoId: string): string {
  switch (platform) {
    case 'youtube':
      return `https://www.youtube.com/watch?v=${videoId}`;
    case 'instagram':
      return `https://www.instagram.com/reel/${videoId}/`;
    case 'tiktok':
      // For TikTok, we keep the original URL as it contains the username
      return url;
    default:
      return url;
  }
}
