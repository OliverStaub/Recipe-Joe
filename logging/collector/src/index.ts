import cron from 'node-cron';
import { createLogger, format, transports, Logger } from 'winston';
import { SupabaseLogClient } from './supabase/client';
import { ElasticsearchClient } from './elasticsearch/client';
import { CheckpointManager } from './state/checkpoint';
import { loadConfig, Config } from './config';
import { LOG_PROVIDERS, PROVIDER_NAMES } from './supabase/queries';

function createAppLogger(config: Config): Logger {
  return createLogger({
    level: config.logLevel,
    format: format.combine(
      format.timestamp(),
      format.errors({ stack: true }),
      format.json()
    ),
    transports: [new transports.Console()],
  });
}

async function collectLogs(
  config: Config,
  supabase: SupabaseLogClient,
  elasticsearch: ElasticsearchClient,
  checkpoints: CheckpointManager,
  logger: Logger
): Promise<void> {
  const now = new Date();

  for (const provider of LOG_PROVIDERS) {
    try {
      const lastCheckpoint = await checkpoints.get(provider);

      // Start from last checkpoint or 24 hours ago (first run)
      const startTime = lastCheckpoint
        ? new Date(lastCheckpoint)
        : new Date(now.getTime() - 24 * 60 * 60 * 1000);

      // Don't query if less than 1 minute since last checkpoint
      if (now.getTime() - startTime.getTime() < 60000) {
        logger.debug(`Skipping ${provider}, less than 1 minute since last checkpoint`);
        continue;
      }

      logger.info(`Fetching ${provider} logs`, {
        from: startTime.toISOString(),
        to: now.toISOString(),
      });

      const logs = await supabase.fetchLogs(provider, startTime, now);

      if (logs.length > 0) {
        // Transform logs for Elasticsearch
        const documents = logs.map((log) => ({
          ...log,
          '@timestamp': log.timestamp,
          provider: PROVIDER_NAMES[provider],
          project_ref: config.supabaseProjectRef,
        }));

        const indexName = `recipejoe-logs-${provider}`;
        const indexed = await elasticsearch.bulkIndex(indexName, documents);
        logger.info(`Indexed ${indexed}/${logs.length} ${provider} logs`);

        // Update checkpoint to latest log timestamp
        const latestTimestamp = logs.reduce((max, log) => {
          const logTime = new Date(log.timestamp).getTime();
          return logTime > max ? logTime : max;
        }, 0);

        if (latestTimestamp > 0) {
          await checkpoints.set(provider, new Date(latestTimestamp).toISOString());
        }
      } else {
        logger.info(`No new ${provider} logs`);
        // Update checkpoint to now to avoid re-querying the same window
        await checkpoints.set(provider, now.toISOString());
      }
    } catch (error) {
      logger.error(`Error collecting ${provider} logs`, { error });
    }
  }
}

async function runSnapshot(
  elasticsearch: ElasticsearchClient,
  logger: Logger
): Promise<void> {
  const snapshotName = `snapshot-${new Date().toISOString().split('T')[0]}`;

  try {
    await elasticsearch.createSnapshot(snapshotName);
    await elasticsearch.cleanupOldSnapshots();
  } catch (error) {
    logger.error('Snapshot failed', { error });
  }
}

async function main(): Promise<void> {
  const config = loadConfig();
  const logger = createAppLogger(config);

  logger.info('RecipeJoe Log Collector starting...', {
    projectRef: config.supabaseProjectRef,
    pollInterval: config.pollIntervalMinutes,
    s3Snapshots: config.enableS3Snapshots,
  });

  const supabase = new SupabaseLogClient(config);
  const elasticsearch = new ElasticsearchClient(config, logger);
  const checkpoints = new CheckpointManager('/app/checkpoints');

  // Ensure checkpoint directory exists
  await checkpoints.ensureDir();

  // Initialize Elasticsearch indices
  logger.info('Initializing Elasticsearch indices...');
  await elasticsearch.ensureIndices();

  // Register S3 repository if enabled
  if (config.enableS3Snapshots) {
    logger.info('Registering S3 snapshot repository...');
    await elasticsearch.registerS3Repository();
  }

  // Run initial collection
  logger.info('Running initial log collection...');
  await collectLogs(config, supabase, elasticsearch, checkpoints, logger);

  // Schedule recurring log collection
  const logCron = `*/${config.pollIntervalMinutes} * * * *`;
  cron.schedule(logCron, async () => {
    logger.info('Running scheduled log collection...');
    await collectLogs(config, supabase, elasticsearch, checkpoints, logger);
  });
  logger.info(`Scheduled log collection every ${config.pollIntervalMinutes} minutes`);

  // Schedule S3 snapshots if enabled
  if (config.enableS3Snapshots) {
    cron.schedule(config.snapshotSchedule, async () => {
      logger.info('Running scheduled snapshot...');
      await runSnapshot(elasticsearch, logger);
    });
    logger.info(`Scheduled snapshots: ${config.snapshotSchedule}`);
  }

  // Keep the process running
  logger.info('Log collector is running. Press Ctrl+C to stop.');
}

main().catch((error) => {
  console.error('Fatal error:', error);
  process.exit(1);
});
