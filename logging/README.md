# RecipeJoe Logging Infrastructure

Docker Compose setup to collect Supabase logs into Elasticsearch with Kibana visualization.

## Features

- Collects logs from all Supabase services (API Gateway, Postgres, Auth, Storage, Realtime, Edge Functions)
- Polls every 15 minutes to extend beyond Supabase's 3-day free tier retention
- Kibana dashboards for log visualization
- Optional S3 snapshots to Infomaniak Swiss Backup

## Prerequisites

- Docker and Docker Compose
- Supabase Access Token
- (Optional) Infomaniak Swiss Backup S3 credentials

## Quick Start

### 1. Get Supabase Access Token

1. Go to https://supabase.com/dashboard/account/tokens
2. Click "Generate new token"
3. Name it "RecipeJoe Log Collector"
4. Copy the token

### 2. Configure Environment

```bash
cd logging
cp .env.example .env
```

Edit `.env` with your values:

```bash
# Required
SUPABASE_ACCESS_TOKEN=sbp_your_token_here
ELASTIC_PASSWORD=YourSecurePassword123!
KIBANA_PASSWORD=YourSecurePassword123!

# Optional - S3 Snapshots
ENABLE_S3_SNAPSHOTS=true
S3_ACCESS_KEY=your_key
S3_SECRET_KEY=your_secret
S3_BUCKET=recipejoe-es-snapshots
```

### 3. Start Services

```bash
# Build and start all services
docker compose up -d --build

# View logs
docker compose logs -f

# View collector logs only
docker compose logs -f log-collector
```

### 4. Access Kibana

Open http://localhost:5601

Login with:
- Username: `elastic`
- Password: `<your ELASTIC_PASSWORD>`

### 5. Create Data Views

In Kibana:
1. Go to Stack Management > Data Views
2. Create data view for each index pattern:
   - `recipejoe-logs-edge_logs` (API Gateway)
   - `recipejoe-logs-postgres_logs` (Database)
   - `recipejoe-logs-auth_logs` (Authentication)
   - `recipejoe-logs-storage_logs` (Storage)
   - `recipejoe-logs-realtime_logs` (Realtime)
   - `recipejoe-logs-function_edge_logs` (Edge Functions)

## Log Providers

| Index | Provider | Description |
|-------|----------|-------------|
| `recipejoe-logs-edge_logs` | api_gateway | API request/response logs |
| `recipejoe-logs-postgres_logs` | postgres | Database query logs |
| `recipejoe-logs-auth_logs` | auth | Authentication events |
| `recipejoe-logs-storage_logs` | storage | File storage operations |
| `recipejoe-logs-realtime_logs` | realtime | Realtime subscription logs |
| `recipejoe-logs-function_edge_logs` | edge_functions | Edge function execution logs |

## S3 Snapshots (Optional)

To enable backups to Infomaniak Swiss Backup:

### 1. Create S3 Bucket in Infomaniak

1. Go to Infomaniak Manager
2. Create a Swiss Backup space with S3 protocol
3. Create a bucket named `recipejoe-es-snapshots`
4. Get your S3 credentials

### 2. Configure and Enable

In `.env`:

```bash
ENABLE_S3_SNAPSHOTS=true
S3_ENDPOINT=s3.swiss-backup02.infomaniak.com
S3_ACCESS_KEY=your_access_key
S3_SECRET_KEY=your_secret_key
S3_BUCKET=recipejoe-es-snapshots
SNAPSHOT_SCHEDULE=0 2 * * *  # 2 AM daily
SNAPSHOT_RETENTION_DAYS=30
```

### 3. Manual Snapshot

```bash
curl -X PUT "localhost:9200/_snapshot/infomaniak_s3/manual-$(date +%Y%m%d)" \
  -u elastic:$ELASTIC_PASSWORD
```

## Commands

```bash
# Start services
docker compose up -d

# Stop services
docker compose down

# View logs
docker compose logs -f log-collector

# Restart collector after config change
docker compose restart log-collector

# Full rebuild
docker compose down
docker compose up -d --build

# Reset everything (deletes all data!)
docker compose down -v
rm -rf data/
docker compose up -d --build
```

## Troubleshooting

### Elasticsearch won't start

Check memory limits:
```bash
docker compose logs elasticsearch
```

If you see memory errors, ensure Docker has at least 4GB RAM allocated.

### Collector can't connect to Supabase

1. Verify your access token is valid
2. Check the token has not expired
3. Verify project ref in `.env` matches your Supabase project

### Kibana shows no data

1. Wait 15 minutes for first log collection
2. Check collector logs: `docker compose logs log-collector`
3. Verify indices exist: `curl -u elastic:$ELASTIC_PASSWORD localhost:9200/_cat/indices`

### S3 snapshots failing

1. Verify S3 credentials are correct
2. Check bucket exists and is accessible
3. View snapshot status:
   ```bash
   curl -u elastic:$ELASTIC_PASSWORD \
     "localhost:9200/_snapshot/infomaniak_s3/_all"
   ```

## Architecture

```
┌─────────────────┐     ┌──────────────────┐     ┌─────────────────┐
│   Supabase      │────▶│  Log Collector   │────▶│  Elasticsearch  │
│   Management    │     │  (Node.js)       │     │  (8.11)         │
│   API           │     │  every 15 min    │     │                 │
└─────────────────┘     └──────────────────┘     └────────┬────────┘
                                                          │
                                                          ├──▶ Kibana (5601)
                                                          │
                                                          └──▶ S3 Snapshots
                                                               (Infomaniak)
```
