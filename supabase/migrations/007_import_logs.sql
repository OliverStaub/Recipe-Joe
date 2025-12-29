-- Migration: Create import_logs table for detailed import analytics
-- Tracks tokens, models used, platform, and timing for each import

CREATE TABLE import_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,

    -- Import details
    import_type TEXT NOT NULL CHECK (import_type IN ('url', 'video', 'image', 'pdf')),
    source TEXT, -- URL or filename (truncated for privacy)
    status TEXT NOT NULL CHECK (status IN ('success', 'failed')),

    -- Recipe info (on success)
    recipe_id UUID REFERENCES recipes(id) ON DELETE SET NULL,
    recipe_name TEXT,

    -- Token usage
    tokens_used INT,

    -- Model usage (which Claude models were called)
    models_used TEXT[], -- e.g., ['claude-3-5-haiku-20241022', 'claude-sonnet-4-20250514']

    -- Token counts from Claude API
    input_tokens INT,
    output_tokens INT,

    -- Platform info
    platform TEXT CHECK (platform IN ('ios', 'android', 'web', 'unknown')),

    -- Error info (on failure)
    error_message TEXT,
    error_code TEXT,

    -- Timing
    duration_ms INT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for analytics queries
CREATE INDEX idx_import_logs_user ON import_logs(user_id);
CREATE INDEX idx_import_logs_created ON import_logs(created_at DESC);
CREATE INDEX idx_import_logs_status ON import_logs(status);
CREATE INDEX idx_import_logs_type ON import_logs(import_type);
CREATE INDEX idx_import_logs_platform ON import_logs(platform);

-- Enable Row Level Security
ALTER TABLE import_logs ENABLE ROW LEVEL SECURITY;

-- Users can read their own logs
CREATE POLICY "Users read own import logs" ON import_logs
    FOR SELECT USING ((SELECT auth.uid()) = user_id);

-- Service role can insert logs (Edge Functions use service role)
CREATE POLICY "Service role inserts import logs" ON import_logs
    FOR INSERT WITH CHECK (auth.role() = 'service_role');

-- Grant access to authenticated users (read-only)
GRANT SELECT ON import_logs TO authenticated;

-- Comments for documentation
COMMENT ON TABLE import_logs IS 'Detailed logs of all recipe imports for analytics';
COMMENT ON COLUMN import_logs.models_used IS 'Array of Claude model IDs used during import';
COMMENT ON COLUMN import_logs.platform IS 'Client platform: ios, android, web, or unknown';
COMMENT ON COLUMN import_logs.source IS 'URL or filename (may be truncated for long URLs)';
