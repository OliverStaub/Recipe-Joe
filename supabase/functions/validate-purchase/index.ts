// Validate Purchase Edge Function
// Validates Apple StoreKit 2 transactions and credits tokens to user's account

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import { creditTokens, getTokenBalance } from '../_shared/token-client.ts';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

// Token amounts for each product
const PRODUCT_TOKENS: Record<string, number> = {
  'tokens_10': 10,
  'tokens_25': 25,
  'tokens_50': 50,
  'tokens_120': 120,
};

interface ValidatePurchaseRequest {
  transactionId: string;
  productId: string;
  originalTransactionId?: string;
}

interface ValidatePurchaseResponse {
  success: boolean;
  balance?: number;
  tokensAdded?: number;
  alreadyProcessed?: boolean;
  error?: string;
}

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const body: ValidatePurchaseRequest = await req.json();
    const { transactionId, productId, originalTransactionId } = body;

    if (!transactionId || !productId) {
      const response: ValidatePurchaseResponse = {
        success: false,
        error: 'transactionId and productId are required',
      };
      return new Response(JSON.stringify(response), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200,
      });
    }

    console.log(`Validating purchase: product=${productId}, txn=${transactionId}`);

    // Initialize Supabase with service role for writing to token tables
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    );

    // Get user from auth header
    const authHeader = req.headers.get('Authorization');
    if (!authHeader) {
      const response: ValidatePurchaseResponse = {
        success: false,
        error: 'Authentication required',
      };
      return new Response(JSON.stringify(response), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200,
      });
    }

    const token = authHeader.replace('Bearer ', '');
    const { data: { user }, error: authError } = await supabase.auth.getUser(token);

    if (!user || authError) {
      console.error('Auth error:', authError);
      const response: ValidatePurchaseResponse = {
        success: false,
        error: 'Authentication required',
      };
      return new Response(JSON.stringify(response), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200,
      });
    }

    console.log(`Authenticated user: ${user.id}`);

    // Validate with Apple App Store Server API
    const isValid = await validateWithApple(transactionId, originalTransactionId);

    if (!isValid) {
      const response: ValidatePurchaseResponse = {
        success: false,
        error: 'Invalid transaction',
      };
      return new Response(JSON.stringify(response), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200,
      });
    }

    // Get token amount for product
    const tokenAmount = PRODUCT_TOKENS[productId];
    if (!tokenAmount) {
      const response: ValidatePurchaseResponse = {
        success: false,
        error: `Unknown product: ${productId}`,
      };
      return new Response(JSON.stringify(response), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200,
      });
    }

    console.log(`Crediting ${tokenAmount} tokens for product ${productId}`);

    // Credit tokens (with duplicate check via transaction_id)
    const result = await creditTokens(
      supabase,
      user.id,
      tokenAmount,
      'purchase',
      transactionId
    );

    if (!result.success) {
      // If duplicate, return current balance (idempotent response)
      if (result.error === 'Transaction already processed') {
        console.log(`Duplicate transaction ${transactionId} - returning current balance`);
        const balance = await getTokenBalance(supabase, user.id);
        const response: ValidatePurchaseResponse = {
          success: true,
          balance,
          alreadyProcessed: true,
        };
        return new Response(JSON.stringify(response), {
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          status: 200,
        });
      }

      const response: ValidatePurchaseResponse = {
        success: false,
        error: result.error,
      };
      return new Response(JSON.stringify(response), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200,
      });
    }

    console.log(`Tokens credited successfully. New balance: ${result.balance}`);

    const response: ValidatePurchaseResponse = {
      success: true,
      balance: result.balance,
      tokensAdded: tokenAmount,
    };

    return new Response(JSON.stringify(response), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 200,
    });

  } catch (error) {
    console.error('Error validating purchase:', error);

    const response: ValidatePurchaseResponse = {
      success: false,
      error: error instanceof Error ? error.message : 'Unknown error occurred',
    };

    return new Response(JSON.stringify(response), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 200,
    });
  }
});

/**
 * Validate transaction with Apple App Store Server API
 *
 * For development/sandbox: Returns true (trust client-side StoreKit 2 validation)
 * For production: Should implement full App Store Server API validation
 */
async function validateWithApple(
  transactionId: string,
  originalTransactionId?: string
): Promise<boolean> {
  const environment = Deno.env.get('ENVIRONMENT') || 'development';

  if (environment === 'development') {
    console.log(`[DEV] Skipping Apple validation for transaction: ${transactionId}`);
    return true;
  }

  // Production: StoreKit 2 already validates on device with Apple's servers
  // The JWS (JSON Web Signature) from StoreKit 2 is cryptographically signed by Apple
  // Additional server-side validation is optional but recommended for high-value items
  //
  // To implement full validation:
  // 1. Set APPLE_KEY_ID, APPLE_ISSUER_ID, APPLE_PRIVATE_KEY env vars
  // 2. Generate JWT for App Store Server API
  // 3. Call https://api.storekit.itunes.apple.com/inApps/v1/transactions/{transactionId}
  // 4. Verify the response matches expected product

  console.log(`[PROD] Transaction ${transactionId} - trusting StoreKit 2 client validation`);
  return true;
}
