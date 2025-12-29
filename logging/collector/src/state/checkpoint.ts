import * as fs from 'fs/promises';
import * as path from 'path';

export class CheckpointManager {
  private checkpointDir: string;

  constructor(checkpointDir: string) {
    this.checkpointDir = checkpointDir;
  }

  private getFilePath(provider: string): string {
    return path.join(this.checkpointDir, `${provider}.checkpoint`);
  }

  async get(provider: string): Promise<string | null> {
    const filePath = this.getFilePath(provider);
    try {
      const content = await fs.readFile(filePath, 'utf-8');
      return content.trim();
    } catch (error) {
      // File doesn't exist, return null
      if ((error as NodeJS.ErrnoException).code === 'ENOENT') {
        return null;
      }
      throw error;
    }
  }

  async set(provider: string, timestamp: string): Promise<void> {
    const filePath = this.getFilePath(provider);
    await fs.writeFile(filePath, timestamp, 'utf-8');
  }

  async ensureDir(): Promise<void> {
    try {
      await fs.mkdir(this.checkpointDir, { recursive: true });
    } catch (error) {
      if ((error as NodeJS.ErrnoException).code !== 'EEXIST') {
        throw error;
      }
    }
  }
}
