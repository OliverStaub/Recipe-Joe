// Image handler utility for downloading and uploading recipe images

import { createClient, SupabaseClient } from "https://esm.sh/@supabase/supabase-js@2";

const MAX_IMAGE_SIZE = 5 * 1024 * 1024; // 5MB
const FETCH_TIMEOUT = 10000; // 10 seconds
const ALLOWED_TYPES = ['image/jpeg', 'image/png', 'image/webp'];

interface ImageUploadResult {
  success: boolean;
  publicUrl?: string;
  error?: string;
}

/**
 * Downloads an image from URL and uploads it to Supabase Storage
 * Returns the public URL of the uploaded image, or null if failed
 */
export async function downloadAndUploadImage(
  imageUrl: string,
  recipeId: string,
  supabase: SupabaseClient
): Promise<ImageUploadResult> {
  try {
    // Validate URL
    const url = new URL(imageUrl);
    if (!['http:', 'https:'].includes(url.protocol)) {
      return { success: false, error: 'Invalid image URL protocol' };
    }

    console.log(`Downloading image from: ${imageUrl}`);

    // Fetch image with timeout
    const controller = new AbortController();
    const timeoutId = setTimeout(() => controller.abort(), FETCH_TIMEOUT);

    const response = await fetch(imageUrl, {
      signal: controller.signal,
      headers: {
        'User-Agent': 'RecipeJoe/1.0 (Recipe Import Bot)',
        'Accept': 'image/*',
      },
    });

    clearTimeout(timeoutId);

    if (!response.ok) {
      return { success: false, error: `Failed to fetch image: ${response.status}` };
    }

    // Check content type
    const contentType = response.headers.get('content-type') || '';
    const mimeType = contentType.split(';')[0].trim().toLowerCase();

    if (!ALLOWED_TYPES.includes(mimeType)) {
      // Try to detect from URL extension as fallback
      const ext = url.pathname.split('.').pop()?.toLowerCase();
      const extMimeMap: Record<string, string> = {
        'jpg': 'image/jpeg',
        'jpeg': 'image/jpeg',
        'png': 'image/png',
        'webp': 'image/webp',
      };

      if (!ext || !extMimeMap[ext]) {
        return { success: false, error: `Unsupported image type: ${contentType}` };
      }
    }

    // Get image data
    const imageData = await response.arrayBuffer();

    // Check size
    if (imageData.byteLength > MAX_IMAGE_SIZE) {
      return { success: false, error: `Image too large: ${(imageData.byteLength / 1024 / 1024).toFixed(1)}MB` };
    }

    if (imageData.byteLength === 0) {
      return { success: false, error: 'Empty image data' };
    }

    console.log(`Downloaded ${(imageData.byteLength / 1024).toFixed(1)}KB image`);

    // Determine file extension
    let extension = 'jpg';
    if (mimeType === 'image/png') extension = 'png';
    else if (mimeType === 'image/webp') extension = 'webp';

    // Upload to Supabase Storage
    const filePath = `${recipeId}.${extension}`;

    const { error: uploadError } = await supabase.storage
      .from('recipe-images')
      .upload(filePath, imageData, {
        contentType: mimeType || 'image/jpeg',
        upsert: true,
      });

    if (uploadError) {
      console.error('Storage upload error:', uploadError);
      return { success: false, error: `Upload failed: ${uploadError.message}` };
    }

    // Get public URL
    const { data: { publicUrl } } = supabase.storage
      .from('recipe-images')
      .getPublicUrl(filePath);

    console.log(`Image uploaded successfully: ${publicUrl}`);

    return { success: true, publicUrl };

  } catch (error) {
    if (error instanceof Error) {
      if (error.name === 'AbortError') {
        return { success: false, error: 'Image download timed out' };
      }
      return { success: false, error: error.message };
    }
    return { success: false, error: 'Unknown error downloading image' };
  }
}
