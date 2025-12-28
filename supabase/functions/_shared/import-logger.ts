// Structured logging for recipe imports
// Logs to both console and Supabase import_logs table

import { SupabaseClient } from 'https://esm.sh/@supabase/supabase-js@2';

export type ImportType = 'url' | 'video' | 'image' | 'pdf';
export type ImportStatus = 'success' | 'failed';
export type Platform = 'ios' | 'android' | 'web' | 'unknown';

export interface ImportLogEntry {
  user_id: string;
  import_type: ImportType;
  source: string; // URL or filename
  status: ImportStatus;
  recipe_id?: string;
  recipe_name?: string;
  error_message?: string;
  error_code?: string;
  tokens_used?: number;
  models_used?: string[];
  input_tokens?: number;
  output_tokens?: number;
  platform?: Platform;
  duration_ms?: number;
}

/**
 * Detect platform from User-Agent or X-Platform header
 */
export function detectPlatform(request: Request): Platform {
  // Check explicit platform header first
  const platformHeader = request.headers.get('X-Platform')?.toLowerCase();
  if (platformHeader === 'ios' || platformHeader === 'android' || platformHeader === 'web') {
    return platformHeader;
  }

  // Fall back to User-Agent detection
  const userAgent = request.headers.get('User-Agent')?.toLowerCase() || '';

  if (userAgent.includes('iphone') || userAgent.includes('ipad') || userAgent.includes('darwin')) {
    return 'ios';
  }
  if (userAgent.includes('android')) {
    return 'android';
  }
  if (userAgent.includes('mozilla') || userAgent.includes('chrome') || userAgent.includes('safari')) {
    return 'web';
  }

  return 'unknown';
}

/**
 * Log an import event to console and database
 */
export async function logImportToDb(
  supabase: SupabaseClient,
  entry: ImportLogEntry
): Promise<void> {
  // Always log to console
  logToConsole(entry);

  // Insert into database
  try {
    const { error } = await supabase.from('import_logs').insert({
      user_id: entry.user_id,
      import_type: entry.import_type,
      source: truncateSource(entry.source),
      status: entry.status,
      recipe_id: entry.recipe_id || null,
      recipe_name: entry.recipe_name || null,
      tokens_used: entry.tokens_used || null,
      models_used: entry.models_used || null,
      input_tokens: entry.input_tokens || null,
      output_tokens: entry.output_tokens || null,
      platform: entry.platform || 'unknown',
      error_message: entry.error_message || null,
      error_code: entry.error_code || null,
      duration_ms: entry.duration_ms || null,
    });

    if (error) {
      console.error('Failed to insert import log:', error);
    }
  } catch (err) {
    console.error('Error logging to database:', err);
  }
}

/**
 * Log import event to console
 */
function logToConsole(entry: ImportLogEntry): void {
  const timestamp = new Date().toISOString();
  const logLevel = entry.status === 'failed' ? 'ERROR' : 'INFO';

  const parts = [
    `[${timestamp}]`,
    `[${logLevel}]`,
    `[recipe_import]`,
    `user=${entry.user_id}`,
    `type=${entry.import_type}`,
    `status=${entry.status}`,
  ];

  if (entry.source) {
    parts.push(`source="${truncateSource(entry.source)}"`);
  }
  if (entry.recipe_id) parts.push(`recipe_id=${entry.recipe_id}`);
  if (entry.recipe_name) parts.push(`recipe="${entry.recipe_name}"`);
  if (entry.tokens_used !== undefined) parts.push(`tokens=${entry.tokens_used}`);
  if (entry.models_used?.length) parts.push(`models=[${entry.models_used.join(',')}]`);
  if (entry.platform) parts.push(`platform=${entry.platform}`);
  if (entry.duration_ms !== undefined) parts.push(`duration=${entry.duration_ms}ms`);
  if (entry.error_message) parts.push(`error="${entry.error_message}"`);

  const message = parts.join(' ');
  if (entry.status === 'failed') {
    console.error(message);
  } else {
    console.log(message);
  }
}

/**
 * Truncate source URL/filename for storage
 */
function truncateSource(source: string): string {
  return source.length > 500 ? source.substring(0, 500) + '...' : source;
}

/**
 * Create a timer for measuring import duration
 */
export function createImportTimer(): { stop: () => number } {
  const start = Date.now();
  return {
    stop: () => Date.now() - start,
  };
}

/**
 * Helper to log import start (console only)
 */
export function logImportStart(
  userId: string,
  importType: ImportType,
  source: string
): void {
  console.log(`[IMPORT_START] user=${userId} type=${importType} source="${source.substring(0, 100)}"`);
}

/**
 * Extract error details from various error types
 */
export function extractErrorDetails(error: unknown): { message: string; code?: string } {
  if (error instanceof Error) {
    return {
      message: error.message,
      code: (error as Error & { code?: string }).code,
    };
  }
  if (typeof error === 'string') {
    return { message: error };
  }
  if (error && typeof error === 'object') {
    const errObj = error as Record<string, unknown>;
    return {
      message: String(errObj.message || errObj.error || JSON.stringify(error)),
      code: String(errObj.code || errObj.error_code || ''),
    };
  }
  return { message: 'Unknown error' };
}
