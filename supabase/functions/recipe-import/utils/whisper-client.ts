// OpenAI Whisper API client for audio transcription fallback

import { VideoPlatform } from '../types.ts';

const OPENAI_API_URL = 'https://api.openai.com/v1/audio/transcriptions';

// Services that provide audio extraction from video URLs
const AUDIO_EXTRACTION_SERVICES = {
  // Using cobalt.tools API for video audio extraction
  cobalt: 'https://api.cobalt.tools/api/json',
};

export class WhisperTranscriptionError extends Error {
  constructor(message: string) {
    super(message);
    this.name = 'WhisperTranscriptionError';
  }
}

export class AudioExtractionError extends Error {
  constructor(message: string) {
    super(message);
    this.name = 'AudioExtractionError';
  }
}

/**
 * Extract audio URL from a video using cobalt.tools API
 * This is a free service that extracts audio from various video platforms
 */
async function extractAudioUrl(
  videoUrl: string,
  _platform: VideoPlatform
): Promise<string> {
  try {
    const response = await fetch(AUDIO_EXTRACTION_SERVICES.cobalt, {
      method: 'POST',
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        url: videoUrl,
        vCodec: 'h264',
        vQuality: '720',
        aFormat: 'mp3',
        isAudioOnly: true,
        disableMetadata: true,
      }),
    });

    if (!response.ok) {
      throw new AudioExtractionError(
        `Failed to extract audio: ${response.status}`
      );
    }

    const data = await response.json();

    if (data.status === 'error') {
      throw new AudioExtractionError(data.text || 'Audio extraction failed');
    }

    if (data.status === 'stream' || data.status === 'redirect') {
      return data.url;
    }

    throw new AudioExtractionError('Unexpected response from audio extraction service');
  } catch (error) {
    if (error instanceof AudioExtractionError) {
      throw error;
    }
    throw new AudioExtractionError(
      `Audio extraction failed: ${error instanceof Error ? error.message : 'Unknown error'}`
    );
  }
}

/**
 * Download audio file from URL and return as Blob
 */
async function downloadAudio(audioUrl: string): Promise<Blob> {
  const response = await fetch(audioUrl, {
    headers: {
      'User-Agent': 'RecipeJoe/1.0',
    },
  });

  if (!response.ok) {
    throw new AudioExtractionError(`Failed to download audio: ${response.status}`);
  }

  return await response.blob();
}

/**
 * Transcribe audio using OpenAI Whisper API
 */
export async function transcribeWithWhisper(
  videoUrl: string,
  platform: VideoPlatform,
  options?: {
    language?: string;
  }
): Promise<{ text: string; language: string }> {
  const openaiApiKey = Deno.env.get('OPENAI_API_KEY');
  if (!openaiApiKey) {
    throw new WhisperTranscriptionError(
      'OPENAI_API_KEY environment variable not set. Audio transcription is not available.'
    );
  }

  // Step 1: Extract audio URL from video
  console.log(`Extracting audio from ${platform} video...`);
  const audioUrl = await extractAudioUrl(videoUrl, platform);

  // Step 2: Download audio file
  console.log('Downloading audio file...');
  const audioBlob = await downloadAudio(audioUrl);

  // Check audio size (Whisper has a 25MB limit)
  const maxSizeBytes = 25 * 1024 * 1024;
  if (audioBlob.size > maxSizeBytes) {
    throw new WhisperTranscriptionError(
      'Audio file too large for transcription (max 25MB). Try a shorter video.'
    );
  }

  // Step 3: Send to Whisper API
  console.log('Transcribing audio with Whisper...');
  const formData = new FormData();
  formData.append('file', audioBlob, 'audio.mp3');
  formData.append('model', 'whisper-1');
  formData.append('response_format', 'json');

  if (options?.language) {
    // Whisper uses ISO 639-1 language codes
    formData.append('language', options.language);
  }

  const response = await fetch(OPENAI_API_URL, {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${openaiApiKey}`,
    },
    body: formData,
  });

  if (!response.ok) {
    const errorText = await response.text();
    throw new WhisperTranscriptionError(
      `Whisper API error (${response.status}): ${errorText}`
    );
  }

  const result = await response.json();

  if (!result.text || result.text.trim() === '') {
    throw new WhisperTranscriptionError(
      'No speech detected in the video audio'
    );
  }

  return {
    text: result.text,
    language: options?.language || 'auto',
  };
}
