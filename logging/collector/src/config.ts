export interface Config {
  // Supabase
  supabaseProjectRef: string;
  supabaseAccessToken: string;

  // Elasticsearch
  elasticsearchUrl: string;
  elasticsearchUsername: string;
  elasticsearchPassword: string;

  // Collector
  pollIntervalMinutes: number;
  logLevel: string;

  // S3 Snapshots
  enableS3Snapshots: boolean;
  s3Bucket: string;
  s3Endpoint: string;
  snapshotSchedule: string;
  snapshotRetentionDays: number;
}

export function loadConfig(): Config {
  const required = (name: string): string => {
    const value = process.env[name];
    if (!value) {
      throw new Error(`Missing required environment variable: ${name}`);
    }
    return value;
  };

  return {
    supabaseProjectRef: required('SUPABASE_PROJECT_REF'),
    supabaseAccessToken: required('SUPABASE_ACCESS_TOKEN'),
    elasticsearchUrl: process.env.ELASTICSEARCH_URL || 'http://localhost:9200',
    elasticsearchUsername: process.env.ELASTICSEARCH_USERNAME || 'elastic',
    elasticsearchPassword: required('ELASTICSEARCH_PASSWORD'),
    pollIntervalMinutes: parseInt(process.env.POLL_INTERVAL_MINUTES || '15', 10),
    logLevel: process.env.LOG_LEVEL || 'info',
    enableS3Snapshots: process.env.ENABLE_S3_SNAPSHOTS === 'true',
    s3Bucket: process.env.S3_BUCKET || 'recipejoe-es-snapshots',
    s3Endpoint: process.env.S3_ENDPOINT || 's3.swiss-backup02.infomaniak.com',
    snapshotSchedule: process.env.SNAPSHOT_SCHEDULE || '0 2 * * *', // 2 AM daily
    snapshotRetentionDays: parseInt(process.env.SNAPSHOT_RETENTION_DAYS || '30', 10),
  };
}
