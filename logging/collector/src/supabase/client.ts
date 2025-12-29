import axios, { AxiosInstance } from 'axios';
import { Config } from '../config';
import { LOG_QUERIES } from './queries';

export interface SupabaseLog {
  id: string;
  timestamp: string;
  event_message: string;
  metadata?: Record<string, unknown>;
  error_severity?: string;
  user_name?: string;
  database_name?: string;
  command_tag?: string;
}

export class SupabaseLogClient {
  private client: AxiosInstance;
  private projectRef: string;

  constructor(config: Config) {
    this.projectRef = config.supabaseProjectRef;
    this.client = axios.create({
      baseURL: 'https://api.supabase.com',
      headers: {
        Authorization: `Bearer ${config.supabaseAccessToken}`,
        'Content-Type': 'application/json',
      },
    });
  }

  async fetchLogs(
    logTable: string,
    startTime: Date,
    endTime: Date
  ): Promise<SupabaseLog[]> {
    // Supabase API limits queries to 24-hour windows
    const maxWindowMs = 24 * 60 * 60 * 1000;
    const windowMs = endTime.getTime() - startTime.getTime();

    if (windowMs > maxWindowMs) {
      throw new Error('Time window exceeds 24 hours');
    }

    const sql = LOG_QUERIES[logTable];
    if (!sql) {
      throw new Error(`Unknown log table: ${logTable}`);
    }

    try {
      const response = await this.client.get(
        `/v1/projects/${this.projectRef}/analytics/endpoints/logs.all`,
        {
          params: {
            sql: sql.trim(),
            iso_timestamp_start: startTime.toISOString(),
            iso_timestamp_end: endTime.toISOString(),
          },
        }
      );

      if (response.data.error) {
        throw new Error(response.data.error.message || 'Supabase API error');
      }

      return response.data.result || [];
    } catch (error) {
      if (axios.isAxiosError(error)) {
        const status = error.response?.status;
        const message = error.response?.data?.message || error.message;
        throw new Error(`Supabase API error (${status}): ${message}`);
      }
      throw error;
    }
  }
}
