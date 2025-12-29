-- Migration: Create user tokens tables for server-side token management
-- Replaces RevenueCat Virtual Currency with Supabase-managed balances

-- User token balances
CREATE TABLE user_tokens (
    user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    balance INT NOT NULL DEFAULT 15,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Token transaction audit log
CREATE TABLE token_transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    amount INT NOT NULL,
    type TEXT NOT NULL CHECK (type IN ('credit', 'debit')),
    reason TEXT NOT NULL, -- 'purchase', 'import_website', 'import_video', 'import_media', 'bonus', 'refund'
    transaction_id TEXT, -- Apple transaction ID (for purchases)
    related_recipe_id UUID REFERENCES recipes(id) ON DELETE SET NULL,
    balance_after INT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX idx_token_transactions_user ON token_transactions(user_id);
CREATE INDEX idx_token_transactions_txn ON token_transactions(transaction_id);
CREATE INDEX idx_token_transactions_created ON token_transactions(created_at DESC);
CREATE INDEX idx_token_transactions_rate_limit ON token_transactions(user_id, type, reason, created_at);

-- Enable Row Level Security
ALTER TABLE user_tokens ENABLE ROW LEVEL SECURITY;
ALTER TABLE token_transactions ENABLE ROW LEVEL SECURITY;

-- Users can read their own balance
CREATE POLICY "Users read own tokens" ON user_tokens
    FOR SELECT USING ((SELECT auth.uid()) = user_id);

-- Service role can manage tokens (Edge Functions use service role)
CREATE POLICY "Service role manages tokens" ON user_tokens
    FOR ALL USING (auth.role() = 'service_role');

-- Users can read their own transactions
CREATE POLICY "Users read own transactions" ON token_transactions
    FOR SELECT USING ((SELECT auth.uid()) = user_id);

-- Service role can insert transactions
CREATE POLICY "Service role inserts transactions" ON token_transactions
    FOR INSERT WITH CHECK (auth.role() = 'service_role');

-- Function to create user_tokens record on first sign-in
CREATE OR REPLACE FUNCTION create_user_tokens()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    INSERT INTO user_tokens (user_id, balance)
    VALUES (NEW.id, 15)
    ON CONFLICT (user_id) DO NOTHING;
    RETURN NEW;
END;
$$;

-- Trigger on auth.users to auto-create token record
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION create_user_tokens();

-- Grant access to authenticated users
GRANT SELECT ON user_tokens TO authenticated;
GRANT SELECT ON token_transactions TO authenticated;

-- Comment for documentation
COMMENT ON TABLE user_tokens IS 'Stores user token balances for recipe imports';
COMMENT ON TABLE token_transactions IS 'Audit log of all token credits and debits';
COMMENT ON COLUMN token_transactions.transaction_id IS 'Apple StoreKit transaction ID for purchases (prevents replay attacks)';
COMMENT ON COLUMN token_transactions.reason IS 'Type of transaction: purchase, import_website, import_video, import_media, bonus, refund';
