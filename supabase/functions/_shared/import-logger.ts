// Structured logging for recipe imports
// Provides consistent logging for both successful and failed imports

export type ImportType = 'url' | 'video' | 'image' | 'pdf';
export type ImportStatus = 'started' | 'success' | 'failed';

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
  duration_ms?: number;
  metadata?: Record<string, unknown>;
}

/**
 * Log an import event with structured data to console
 * Logs appear in Supabase Edge Function logs dashboard
 */
export function logImport(entry: ImportLogEntry): void {
  const timestamp = new Date().toISOString();
  const logLevel = entry.status === 'failed' ? 'ERROR' : 'INFO';

  // Build structured log object
  const logData = {
    timestamp,
    level: logLevel,
    event: 'recipe_import',
    ...entry,
  };

  // Log to console in structured format
  const logMessage = formatLogMessage(logData);
  if (entry.status === 'failed') {
    console.error(logMessage);
  } else {
    console.log(logMessage);
  }
}

/**
 * Format log entry for console output
 */
function formatLogMessage(data: Record<string, unknown>): string {
  const { timestamp, level, event, user_id, import_type, source, status, recipe_id, recipe_name, error_message, tokens_used, duration_ms } = data;

  const parts = [
    `[${timestamp}]`,
    `[${level}]`,
    `[${event}]`,
    `user=${user_id}`,
    `type=${import_type}`,
    `status=${status}`,
  ];

  if (source) {
    // Truncate source for logging
    const truncatedSource = String(source).length > 100
      ? String(source).substring(0, 100) + '...'
      : source;
    parts.push(`source="${truncatedSource}"`);
  }

  if (recipe_id) parts.push(`recipe_id=${recipe_id}`);
  if (recipe_name) parts.push(`recipe="${recipe_name}"`);
  if (tokens_used !== undefined) parts.push(`tokens=${tokens_used}`);
  if (duration_ms !== undefined) parts.push(`duration=${duration_ms}ms`);
  if (error_message) parts.push(`error="${error_message}"`);

  return parts.join(' ');
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
 * Helper to log import start
 */
export function logImportStart(
  userId: string,
  importType: ImportType,
  source: string
): void {
  console.log(`[IMPORT_START] user=${userId} type=${importType} source="${source.substring(0, 100)}"`);
}

/**
 * Helper to log import success
 */
export function logImportSuccess(entry: Omit<ImportLogEntry, 'status'>): void {
  logImport({ ...entry, status: 'success' });
}

/**
 * Helper to log import failure
 */
export function logImportFailure(
  entry: Omit<ImportLogEntry, 'status'> & { error_message: string }
): void {
  logImport({ ...entry, status: 'failed' });
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
