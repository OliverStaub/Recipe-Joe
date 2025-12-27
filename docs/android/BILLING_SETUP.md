# Google Play Billing Setup for RecipeJoe Android

This guide explains how to set up in-app purchases for the Android app.

## Prerequisites

- Google Play Developer account ($25 one-time fee)
- App uploaded to Google Play Console (internal testing track minimum)

## Step 1: Create Products in Google Play Console

1. Go to [Google Play Console](https://play.google.com/console/)
2. Select your app
3. Go to "Monetize" > "Products" > "In-app products"
4. Create the following products:

### Product 1: tokens_10
- Product ID: `tokens_10`
- Name: 10 Tokens
- Description: Import 10 recipes with AI
- Price: Set your price (e.g., $0.99)

### Product 2: tokens_25
- Product ID: `tokens_25`
- Name: 25 Tokens
- Description: Import 25 recipes with AI
- Price: Set your price (e.g., $1.99)

### Product 3: tokens_50
- Product ID: `tokens_50`
- Name: 50 Tokens
- Description: Import 50 recipes with AI
- Price: Set your price (e.g., $3.99)

### Product 4: tokens_120
- Product ID: `tokens_120`
- Name: 120 Tokens
- Description: Import 120 recipes with AI (Best Value)
- Price: Set your price (e.g., $7.99)

5. Activate each product

## Step 2: Set Up License Testing

1. Go to "Settings" > "License testing"
2. Add your test email addresses
3. Set license response to "LICENSED"

This allows testers to make purchases without being charged.

## Step 3: Implement Billing in App

The billing implementation is already included in the app. Key files:

- `data/repository/TokenRepositoryImpl.kt` - Token management
- `presentation/settings/BuyTokensScreen.kt` - Purchase UI (TODO: implement)

## Step 4: Configure Server-Side Validation

### Update Supabase Edge Function

The `validate-purchase` Edge Function needs to verify Android purchases:

```typescript
// In supabase/functions/validate-purchase/index.ts

// Add Android verification
if (purchaseToken) {
  // Verify with Google Play Developer API
  const verified = await verifyAndroidPurchase(
    productId,
    purchaseToken
  );
  if (!verified) {
    throw new Error('Invalid Android purchase');
  }
}
```

### Set Up Google Play Developer API

1. Go to Google Cloud Console
2. Enable "Google Play Android Developer API"
3. Create a service account
4. Download the JSON key
5. In Google Play Console, grant the service account access:
   - Go to "Users and permissions"
   - Invite the service account email
   - Grant "View financial data" permission

## Step 5: Testing Purchases

### Using License Testers

1. Upload app to internal testing track
2. Add testers as license testers
3. Testers install via Play Store internal testing link
4. Purchases are free but recorded

### Test Cards

Google Play provides test cards for license testers:
- Always approves
- Always declines
- Slow response

## Step 6: Production Checklist

- [ ] All products created and activated
- [ ] Prices set in all countries
- [ ] Server-side validation working
- [ ] Test purchases verified
- [ ] Refund handling implemented
- [ ] Purchase restoration working

## Troubleshooting

### Error: Item not available

- Product might not be activated
- App version mismatch (must use signed APK from Play Store)
- User not a license tester

### Error: Service unavailable

- Google Play Services not available on device
- Network connectivity issues

### Error: Developer error

- Product IDs don't match
- App not published (even to internal track)

## Webhook for Real-time Updates (Optional)

Set up Real-time Developer Notifications:

1. Go to Play Console > Monetization setup
2. Enable Real-time developer notifications
3. Enter your endpoint URL (Supabase Edge Function)
4. Receive instant updates for:
   - New purchases
   - Refunds
   - Cancellations

## Revenue Reporting

Google Play takes a 15% fee (down from 30%) for the first $1M in annual revenue.

Track revenue in:
- Google Play Console > Financial reports
- Supabase dashboard (if you track purchases in database)
