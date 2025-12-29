// SQL queries for each Supabase log table
export const LOG_QUERIES: Record<string, string> = {
  edge_logs: `
    SELECT
      id,
      timestamp,
      event_message,
      metadata
    FROM edge_logs
    ORDER BY timestamp DESC
    LIMIT 1000
  `,

  postgres_logs: `
    SELECT
      id,
      timestamp,
      event_message,
      parsed.error_severity as error_severity,
      parsed.user_name as user_name,
      parsed.database_name as database_name,
      parsed.command_tag as command_tag
    FROM postgres_logs
    ORDER BY timestamp DESC
    LIMIT 1000
  `,

  auth_logs: `
    SELECT
      id,
      timestamp,
      event_message,
      metadata
    FROM auth_logs
    ORDER BY timestamp DESC
    LIMIT 1000
  `,

  storage_logs: `
    SELECT
      id,
      timestamp,
      event_message,
      metadata
    FROM storage_logs
    ORDER BY timestamp DESC
    LIMIT 1000
  `,

  realtime_logs: `
    SELECT
      id,
      timestamp,
      event_message,
      metadata
    FROM realtime_logs
    ORDER BY timestamp DESC
    LIMIT 1000
  `,

  function_edge_logs: `
    SELECT
      id,
      timestamp,
      event_message,
      metadata
    FROM function_edge_logs
    ORDER BY timestamp DESC
    LIMIT 1000
  `,
};

// Map internal log table names to friendly provider names
export const PROVIDER_NAMES: Record<string, string> = {
  edge_logs: 'api_gateway',
  postgres_logs: 'postgres',
  auth_logs: 'auth',
  storage_logs: 'storage',
  realtime_logs: 'realtime',
  function_edge_logs: 'edge_functions',
};

export const LOG_PROVIDERS = Object.keys(LOG_QUERIES);
