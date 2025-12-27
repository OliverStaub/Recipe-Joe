// Token management client for Supabase
// Replaces RevenueCat Virtual Currency with Supabase-managed balances

import { SupabaseClient } from 'https://esm.sh/@supabase/supabase-js@2';

export const TOKEN_COSTS = {
  website: 1,
  video: 2,
  media: 3,
} as const;

export interface TokenResult {
  success: boolean;
  balance?: number;
  error?: string;
}

export interface RateLimitResult {
  allowed: boolean;
  remaining: number;
  resetAt: Date;
}

/**
 * Get user's current token balance from Supabase
 */
export async function getTokenBalance(
  supabase: SupabaseClient,
  userId: string
): Promise<number> {
  const { data, error } = await supabase
    .from('user_tokens')
    .select('balance')
    .eq('user_id', userId)
    .single();

  if (error) {
    console.error('Failed to get token balance:', error);
    throw new Error('Could not retrieve token balance');
  }

  return data?.balance ?? 0;
}

/**
 * Deduct tokens from user's balance after successful import
 */
export async function deductTokens(
  supabase: SupabaseClient,
  userId: string,
  amount: number,
  reason: string,
  recipeId?: string
): Promise<TokenResult> {
  // Get current balance
  const { data: tokenData, error: fetchError } = await supabase
    .from('user_tokens')
    .select('balance')
    .eq('user_id', userId)
    .single();

  if (fetchError || !tokenData) {
    console.error('Failed to fetch token balance:', fetchError);
    return { success: false, error: 'Could not fetch balance' };
  }

  const currentBalance = tokenData.balance;
  if (currentBalance < amount) {
    return { success: false, error: 'Insufficient tokens', balance: currentBalance };
  }

  const newBalance = currentBalance - amount;

  // Update balance
  const { error: updateError } = await supabase
    .from('user_tokens')
    .update({ balance: newBalance, updated_at: new Date().toISOString() })
    .eq('user_id', userId);

  if (updateError) {
    console.error('Failed to update token balance:', updateError);
    return { success: false, error: 'Failed to update balance' };
  }

  // Record transaction for audit
  const { error: txnError } = await supabase.from('token_transactions').insert({
    user_id: userId,
    amount: -amount,
    type: 'debit',
    reason,
    related_recipe_id: recipeId,
    balance_after: newBalance,
  });

  if (txnError) {
    console.error('Failed to record token transaction:', txnError);
    // Don't fail - the balance was updated successfully
  }

  return { success: true, balance: newBalance };
}

/**
 * Credit tokens to user's balance after successful purchase
 */
export async function creditTokens(
  supabase: SupabaseClient,
  userId: string,
  amount: number,
  reason: string,
  transactionId?: string
): Promise<TokenResult> {
  // Check for duplicate transaction (replay attack prevention)
  if (transactionId) {
    const { data: existing } = await supabase
      .from('token_transactions')
      .select('id')
      .eq('transaction_id', transactionId)
      .maybeSingle();

    if (existing) {
      console.log(`Duplicate transaction detected: ${transactionId}`);
      return { success: false, error: 'Transaction already processed' };
    }
  }

  // Get current balance (may not exist yet for new users)
  const { data: tokenData } = await supabase
    .from('user_tokens')
    .select('balance')
    .eq('user_id', userId)
    .maybeSingle();

  const currentBalance = tokenData?.balance ?? 0;
  const newBalance = currentBalance + amount;

  // Upsert balance (creates record if not exists)
  const { error: upsertError } = await supabase
    .from('user_tokens')
    .upsert({
      user_id: userId,
      balance: newBalance,
      updated_at: new Date().toISOString(),
    });

  if (upsertError) {
    console.error('Failed to credit tokens:', upsertError);
    return { success: false, error: 'Failed to credit tokens' };
  }

  // Record transaction for audit
  const { error: txnError } = await supabase.from('token_transactions').insert({
    user_id: userId,
    amount,
    type: 'credit',
    reason,
    transaction_id: transactionId,
    balance_after: newBalance,
  });

  if (txnError) {
    console.error('Failed to record token transaction:', txnError);
    // Don't fail - the balance was updated successfully
  }

  return { success: true, balance: newBalance };
}

/**
 * Check rate limit: 150 recipes per 24 hours
 */
export async function checkRateLimit(
  supabase: SupabaseClient,
  userId: string
): Promise<RateLimitResult> {
  const LIMIT = 150;
  const WINDOW_HOURS = 24;

  const windowStart = new Date();
  windowStart.setHours(windowStart.getHours() - WINDOW_HOURS);

  // Count recipe imports in the last 24 hours
  const { count, error } = await supabase
    .from('token_transactions')
    .select('*', { count: 'exact', head: true })
    .eq('user_id', userId)
    .eq('type', 'debit')
    .in('reason', ['import_website', 'import_video', 'import_media'])
    .gte('created_at', windowStart.toISOString());

  if (error) {
    console.error('Rate limit check failed:', error);
    // Fail open on error but log for monitoring
    return { allowed: true, remaining: LIMIT, resetAt: new Date() };
  }

  const used = count ?? 0;
  const remaining = Math.max(0, LIMIT - used);

  // Reset time is 24h from now (rolling window)
  const resetAt = new Date();
  resetAt.setHours(resetAt.getHours() + WINDOW_HOURS);

  return {
    allowed: used < LIMIT,
    remaining,
    resetAt,
  };
}
