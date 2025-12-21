# Supabase Edge Function Tests

This directory contains unit and integration tests for the RecipeJoe edge functions.

## Test Structure

```
tests/
├── README.md                    # This file
├── deno.json                    # Deno configuration
├── .env.example                 # Environment variables template
├── .env                         # Your local config (symlink to project root .env)
├── video-detector-test.ts       # Unit tests for video URL detection utilities
└── recipe-import-test.ts        # Integration tests for recipe-import function
```

## Prerequisites

1. **Deno** - Install from https://deno.land/#installation
   ```bash
   curl -fsSL https://deno.land/install.sh | sh
   ```

2. **Environment Variables** - Create `.env` from `.env.example` or symlink to project root:
   ```bash
   ln -s /path/to/RecipeJoe/.env /path/to/RecipeJoe/supabase/functions/tests/.env
   ```

## Running Tests

### Quick Start

Use the provided script from the project root:

```bash
# Run all edge function tests
./scripts/run-edge-tests.sh

# Run only unit tests (no network required)
./scripts/run-edge-tests.sh unit

# Run only integration tests (requires Supabase)
./scripts/run-edge-tests.sh integration
```

### Direct Deno Commands

```bash
cd supabase/functions/tests

# Run unit tests (no network, fast)
deno test --allow-read --allow-env video-detector-test.ts

# Run integration tests (requires network and Supabase)
deno test --allow-all recipe-import-test.ts

# Run all tests
deno test --allow-all .
```

## Test Types

### Unit Tests (`video-detector-test.ts`)

Pure function tests that don't require network or Supabase. Tests cover:
- `isVideoUrl()` - Video platform URL detection
- `getVideoPlatform()` - Platform identification (YouTube, TikTok, Instagram)
- `extractVideoId()` - Video ID extraction from URLs
- `parseTimestamp()` - Timestamp parsing (MM:SS, HH:MM:SS)
- `getNormalizedVideoUrl()` - URL normalization

### Integration Tests (`recipe-import-test.ts`)

End-to-end tests that call the deployed edge function. Tests cover:
- Configuration validation (env vars are set)
- Authentication flows (valid token, missing token, invalid token)
- Request validation (URL required, valid URL format, HTTP(S) only)
- Video URL detection (YouTube and TikTok trigger video import path)
- CORS handling

## Authentication Behavior

**Important**: Supabase edge functions have two layers of authentication:

1. **Infrastructure Layer (Supabase Gateway)**
   - Validates the `apikey` header
   - Returns `401 Unauthorized` if apikey is missing/invalid
   - This happens BEFORE the edge function code runs

2. **Application Layer (Edge Function Code)**
   - Validates the `Authorization: Bearer <token>` header
   - Returns `500` with `"Authentication required"` error if token is missing/invalid
   - This is our custom authentication logic

### How iOS App Auth Should Work

When the iOS app calls `client.functions.invoke()`:
1. Supabase Swift SDK includes `apikey` header (from client initialization)
2. SDK includes `Authorization: Bearer <token>` from current session
3. Edge function validates the token and extracts user ID

### Debugging Auth Issues

If you see "Authentication required" errors in production:

1. **Check Supabase Dashboard Logs**
   - View function logs at: Dashboard → Edge Functions → recipe-import → Logs
   - Look for our debug logs: "Auth header present", "Token length", etc.

2. **Common Causes**
   - Session not established before calling function
   - Token expired and not refreshed
   - iOS app not including Authorization header

3. **Verify with Deno tests**
   ```bash
   ./scripts/run-edge-tests.sh integration
   ```
   The test "auth - request with valid token accepts the request" should pass.

## Environment Variables

Required for integration tests:

| Variable | Description | Example |
|----------|-------------|---------|
| `SUPABASE_URL` | Your Supabase project URL | `https://xxx.supabase.co` |
| `SUPABASE_ANON_KEY` | Public/anon key | `sb_publishable_xxx` |
| `TEST_USER_EMAIL` | Test account email | `test@example.com` |
| `TEST_USER_PASSWORD` | Test account password | `password123` |

Optional:

| Variable | Description | Default |
|----------|-------------|---------|
| `EDGE_FUNCTION_URL` | Override function URL | `{SUPABASE_URL}/functions/v1/recipe-import` |

## Git Hook Integration

Edge function unit tests run automatically as part of the pre-commit hook on `main` and `develop` branches. See `scripts/pre-commit` for details.

## Troubleshooting

### "Deno is not installed"
Install Deno and ensure it's in your PATH:
```bash
export PATH="$HOME/.deno/bin:$PATH"
```

### Integration tests skip with "No .env file found"
Create or symlink the .env file:
```bash
ln -s ../../.env .env
```

### Tests fail with network errors
- Ensure you have internet connectivity
- Check that SUPABASE_URL is correct
- Verify the edge function is deployed

### Tests timeout on TikTok imports
TikTok video imports can take 1-3 minutes due to transcript fetching and AI processing. This is expected behavior.
