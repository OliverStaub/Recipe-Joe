-- Migration: Add 'pending' status to import_logs for job tracking
-- This allows iOS/Android to check import status when connection is lost

-- Add 'pending' as a valid status
ALTER TABLE import_logs
  DROP CONSTRAINT import_logs_status_check,
  ADD CONSTRAINT import_logs_status_check
    CHECK (status IN ('pending', 'success', 'failed'));

-- Add index for quick lookups by ID (for job status checks)
CREATE INDEX idx_import_logs_id ON import_logs(id);

-- Allow service role to update logs (for changing pending -> success/failed)
CREATE POLICY "Service role updates import logs" ON import_logs
    FOR UPDATE USING (auth.role() = 'service_role');

-- Comment for documentation
COMMENT ON COLUMN import_logs.status IS 'Import status: pending (in progress), success, or failed';
