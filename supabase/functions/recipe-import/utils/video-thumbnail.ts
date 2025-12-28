// Video thumbnail extraction utilities

import { VideoPlatform, VideoMetadata } from '../types.ts';

/**
 * Get YouTube video thumbnail URL
 * YouTube has predictable thumbnail URLs based on video ID
 */
export function getYouTubeThumbnail(videoId: string): string {
  // maxresdefault is highest quality, falls back to hqdefault if not available
  return `https://img.youtube.com/vi/${videoId}/maxresdefault.jpg`;
}

/**
 * Fetch YouTube video details including description via YouTube Data API
 * Requires YOUTUBE_API_KEY environment variable
 */
export async function getYouTubeVideoDetails(videoId: string): Promise<{
  title: string | null;
  author: string | null;
  description: string | null;
}> {
  const apiKey = Deno.env.get('YOUTUBE_API_KEY');

  if (!apiKey) {
    console.warn('YOUTUBE_API_KEY not set - video descriptions will not be available');
    return { title: null, author: null, description: null };
  }

  try {
    const url = `https://www.googleapis.com/youtube/v3/videos?id=${videoId}&part=snippet&key=${apiKey}`;
    const response = await fetch(url);

    if (!response.ok) {
      console.warn(`YouTube Data API failed: ${response.status}`);
      return { title: null, author: null, description: null };
    }

    const data = await response.json();

    if (!data.items || data.items.length === 0) {
      console.warn('YouTube video not found');
      return { title: null, author: null, description: null };
    }

    const snippet = data.items[0].snippet;
    return {
      title: snippet.title || null,
      author: snippet.channelTitle || null,
      description: snippet.description || null,
    };
  } catch (error) {
    console.warn('YouTube Data API error:', error);
    return { title: null, author: null, description: null };
  }
}

/**
 * Get YouTube thumbnail with fallback URLs
 */
export function getYouTubeThumbnailUrls(videoId: string): string[] {
  return [
    `https://img.youtube.com/vi/${videoId}/maxresdefault.jpg`,
    `https://img.youtube.com/vi/${videoId}/sddefault.jpg`,
    `https://img.youtube.com/vi/${videoId}/hqdefault.jpg`,
    `https://img.youtube.com/vi/${videoId}/mqdefault.jpg`,
  ];
}

/**
 * Get Instagram video metadata via oEmbed API
 */
export async function getInstagramMetadata(url: string): Promise<{
  thumbnailUrl: string | null;
  title: string | null;
  author: string | null;
}> {
  try {
    const oembedUrl = `https://www.instagram.com/api/v1/oembed/?url=${encodeURIComponent(url)}`;
    const response = await fetch(oembedUrl, {
      headers: {
        'User-Agent': 'RecipeJoe/1.0',
      },
    });

    if (!response.ok) {
      console.warn(`Instagram oEmbed failed: ${response.status}`);
      return { thumbnailUrl: null, title: null, author: null };
    }

    const data = await response.json();
    return {
      thumbnailUrl: data.thumbnail_url || null,
      title: data.title || null,
      author: data.author_name || null,
    };
  } catch (error) {
    console.warn('Instagram oEmbed error:', error);
    return { thumbnailUrl: null, title: null, author: null };
  }
}

/**
 * Get TikTok video metadata via oEmbed API
 */
export async function getTikTokMetadata(url: string): Promise<{
  thumbnailUrl: string | null;
  title: string | null;
  author: string | null;
}> {
  try {
    const oembedUrl = `https://www.tiktok.com/oembed?url=${encodeURIComponent(url)}`;
    const response = await fetch(oembedUrl, {
      headers: {
        'User-Agent': 'RecipeJoe/1.0',
      },
    });

    if (!response.ok) {
      console.warn(`TikTok oEmbed failed: ${response.status}`);
      return { thumbnailUrl: null, title: null, author: null };
    }

    const data = await response.json();
    return {
      thumbnailUrl: data.thumbnail_url || null,
      title: data.title || null,
      author: data.author_name || null,
    };
  } catch (error) {
    console.warn('TikTok oEmbed error:', error);
    return { thumbnailUrl: null, title: null, author: null };
  }
}

/**
 * Get video metadata including thumbnail for any supported platform
 */
export async function getVideoMetadata(
  url: string,
  platform: VideoPlatform,
  videoId: string
): Promise<VideoMetadata> {
  switch (platform) {
    case 'youtube': {
      // Try YouTube Data API first for full details including description
      const ytDetails = await getYouTubeVideoDetails(videoId);

      // Fallback to oEmbed if Data API fails (no API key)
      let title = ytDetails.title || 'YouTube Recipe Video';
      let author = ytDetails.author || 'Unknown';
      const description = ytDetails.description;

      if (!ytDetails.title) {
        try {
          const oembedUrl = `https://www.youtube.com/oembed?url=${encodeURIComponent(url)}&format=json`;
          const response = await fetch(oembedUrl);
          if (response.ok) {
            const data = await response.json();
            title = data.title || title;
            author = data.author_name || author;
          }
        } catch {
          // Use defaults
        }
      }

      return {
        title,
        author,
        description,
        thumbnailUrl: getYouTubeThumbnail(videoId),
        duration: 0,
        platform,
        videoId,
      };
    }

    case 'instagram': {
      const metadata = await getInstagramMetadata(url);
      return {
        title: metadata.title || 'Instagram Recipe Reel',
        author: metadata.author || 'Unknown',
        description: null, // Instagram oEmbed doesn't provide full caption
        thumbnailUrl: metadata.thumbnailUrl,
        duration: 0,
        platform,
        videoId,
      };
    }

    case 'tiktok': {
      const metadata = await getTikTokMetadata(url);
      return {
        title: metadata.title || 'TikTok Recipe Video',
        author: metadata.author || 'Unknown',
        description: null, // TikTok oEmbed doesn't provide full caption
        thumbnailUrl: metadata.thumbnailUrl,
        duration: 0,
        platform,
        videoId,
      };
    }

    default:
      return {
        title: 'Recipe Video',
        author: 'Unknown',
        description: null,
        thumbnailUrl: null,
        duration: 0,
        platform,
        videoId,
      };
  }
}

/**
 * Verify that a thumbnail URL is accessible
 */
export async function verifyThumbnailUrl(url: string): Promise<boolean> {
  try {
    const response = await fetch(url, { method: 'HEAD' });
    return response.ok;
  } catch {
    return false;
  }
}

/**
 * Get the first working YouTube thumbnail URL
 */
export async function getWorkingYouTubeThumbnail(videoId: string): Promise<string | null> {
  const urls = getYouTubeThumbnailUrls(videoId);

  for (const url of urls) {
    if (await verifyThumbnailUrl(url)) {
      return url;
    }
  }

  return null;
}
