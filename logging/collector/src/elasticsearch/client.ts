import { Client } from '@elastic/elasticsearch';
import { Config } from '../config';
import { indexTemplate, ilmPolicy } from './mapping';
import { Logger } from 'winston';

export class ElasticsearchClient {
  private client: Client;
  private config: Config;
  private logger: Logger;

  constructor(config: Config, logger: Logger) {
    this.config = config;
    this.logger = logger;
    this.client = new Client({
      node: config.elasticsearchUrl,
      auth: {
        username: config.elasticsearchUsername,
        password: config.elasticsearchPassword,
      },
    });
  }

  async ensureIndices(): Promise<void> {
    // Create ILM policy
    try {
      await this.client.ilm.putLifecycle({
        name: 'recipejoe-logs-policy',
        policy: ilmPolicy.policy,
      });
      this.logger.info('Created ILM policy: recipejoe-logs-policy');
    } catch (error) {
      // Policy may already exist
      this.logger.debug('ILM policy may already exist');
    }

    // Create index template
    try {
      await this.client.indices.putIndexTemplate({
        name: 'recipejoe-logs',
        ...indexTemplate,
      });
      this.logger.info('Created index template: recipejoe-logs');
    } catch (error) {
      this.logger.error('Failed to create index template', error);
      throw error;
    }
  }

  async bulkIndex(indexName: string, documents: unknown[]): Promise<number> {
    if (documents.length === 0) {
      return 0;
    }

    const operations = documents.flatMap((doc: unknown) => {
      const docWithId = doc as { id: string };
      return [{ index: { _index: indexName, _id: docWithId.id } }, doc];
    });

    const { errors, items } = await this.client.bulk({
      refresh: true,
      operations,
    });

    if (errors) {
      const errorItems = items.filter((item) => item.index?.error);
      this.logger.error('Bulk index errors:', { errors: errorItems.slice(0, 5) });
    }

    const successCount = items.filter((item) => !item.index?.error).length;
    return successCount;
  }

  // S3 Snapshot methods
  async registerS3Repository(): Promise<void> {
    if (!this.config.enableS3Snapshots) {
      this.logger.info('S3 snapshots disabled, skipping repository registration');
      return;
    }

    try {
      await this.client.snapshot.createRepository({
        name: 'infomaniak_s3',
        repository: {
          type: 's3',
          settings: {
            bucket: this.config.s3Bucket,
            endpoint: this.config.s3Endpoint,
            protocol: 'https',
          },
        },
      });
      this.logger.info('Registered S3 snapshot repository: infomaniak_s3');
    } catch (error) {
      this.logger.error('Failed to register S3 repository', error);
      throw error;
    }
  }

  async createSnapshot(name: string): Promise<void> {
    if (!this.config.enableS3Snapshots) {
      return;
    }

    try {
      await this.client.snapshot.create({
        repository: 'infomaniak_s3',
        snapshot: name,
        wait_for_completion: false,
        indices: 'recipejoe-logs-*',
      });
      this.logger.info(`Created snapshot: ${name}`);
    } catch (error) {
      this.logger.error(`Failed to create snapshot: ${name}`, error);
      throw error;
    }
  }

  async cleanupOldSnapshots(): Promise<void> {
    if (!this.config.enableS3Snapshots) {
      return;
    }

    try {
      const response = await this.client.snapshot.get({
        repository: 'infomaniak_s3',
        snapshot: '*',
      });

      const cutoffDate = new Date();
      cutoffDate.setDate(cutoffDate.getDate() - this.config.snapshotRetentionDays);

      for (const snapshot of response.snapshots || []) {
        const snapshotDate = new Date(snapshot.start_time || 0);
        if (snapshotDate < cutoffDate) {
          await this.client.snapshot.delete({
            repository: 'infomaniak_s3',
            snapshot: snapshot.snapshot,
          });
          this.logger.info(`Deleted old snapshot: ${snapshot.snapshot}`);
        }
      }
    } catch (error) {
      this.logger.error('Failed to cleanup old snapshots', error);
    }
  }
}
