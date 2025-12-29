FROM docker.elastic.co/elasticsearch/elasticsearch:8.11.0

# Install S3 repository plugin for snapshots to Infomaniak Swiss Backup
RUN bin/elasticsearch-plugin install --batch repository-s3
