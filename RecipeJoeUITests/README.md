# RecipeJoe UI Tests

This guide explains how to set up and run the UI tests for RecipeJoe.

## Overview

The UI tests use isolated test data management. Your personal recipes remain completely isolated via Supabase Row Level Security (RLS).

## Authentication Options for Testing

### Option 1: Use Your Personal Apple Account (Simplest)
- Just sign in with your Apple ID on the simulator
- Tests work immediately
- Test-created recipes will appear in your account (can be cleaned up)

### Option 2: Add Email/Password Auth (Recommended for Dedicated Testing)
Supabase supports email/password authentication. This allows creating a dedicated test user:

1. **Enable in Supabase Dashboard:**
   - Go to Authentication → Providers
   - Enable "Email" provider

2. **Create a Test User:**
   - Go to Authentication → Users → Add User
   - Create: `test@recipejoe.local` with a password
   - Copy the User UID

3. **Configure Tests:**
   - Set `TEST_USER_ID` environment variable in your test scheme
   - Set `SUPABASE_SERVICE_ROLE_KEY` for cleanup

> **Note:** To add email/password sign-in to the app itself (not just testing), additional UI work is needed in AuthenticationView.

### Option 3: Apple Sandbox Account
Apple Sandbox accounts are primarily for In-App Purchase testing, not Sign in with Apple. They won't help with authentication testing.

## Test Setup

### Environment Variables

In Xcode: **Product → Scheme → Edit Scheme → Test → Arguments → Environment Variables**

| Variable | Required | Description |
|----------|----------|-------------|
| `TEST_USER_ID` | For cleanup | UUID of the test user from Supabase |
| `SUPABASE_SERVICE_ROLE_KEY` | For cleanup | Service role key from Supabase project settings |

### Finding Your User UUID

1. Go to [Supabase Dashboard](https://supabase.com/dashboard)
2. Select your project → **Authentication** → **Users**
3. Find your user and copy the **User UID**

## Running Tests

### Quick Run
```bash
./scripts/run-tests.sh
```

### From Xcode
Press `Cmd+U` to run all tests.

### Command Line
```bash
xcodebuild test \
  -project RecipeJoe.xcodeproj \
  -scheme RecipeJoe \
  -destination 'platform=iOS Simulator,name=iPhone Air'
```

## Test Structure

### Test Files

| File | Description |
|------|-------------|
| `AuthenticationUITests.swift` | Sign-in, sign-out, account management |
| `RecipeJoeUITests.swift` | Main app navigation and UI |
| `RecipeImportUITests.swift` | Recipe import functionality |
| `RecipeJoeUITestsLaunchTests.swift` | Launch performance tests |

### Helper Files

| File | Description |
|------|-------------|
| `Helpers/BaseUITestCase.swift` | Base class with setup/teardown |
| `Helpers/TestConfig.swift` | Configuration constants |
| `Helpers/TestSupabaseClient.swift` | Supabase client for seeding/cleanup |

## Test Data Management

### Seeding Test Data

Tests that inherit from `BaseUITestCase` can seed test recipes:

```swift
func testSomething() throws {
    // Seed a recipe before the test
    let recipeId = seedRecipe(name: "My Test Recipe")

    app.launch()
    // ... run test ...

    // Cleanup happens automatically in tearDown
}
```

### Automatic Cleanup

- Test recipes are prefixed with `[TEST]` for easy identification
- Cleanup runs automatically in `tearDownWithError()`
- Requires `TEST_USER_ID` and `SUPABASE_SERVICE_ROLE_KEY` to be set

## Troubleshooting

### Tests Skip with "User is not authenticated"
- Sign into an Apple account on the simulator
- Or create a test user with email/password auth

### Confirmation Dialogs Not Found
- The app uses `.alert` for confirmations (not `.confirmationDialog`)
- Tests should look for `app.alerts` not `app.sheets`

### Test Data Not Cleaning Up
- Ensure `SUPABASE_SERVICE_ROLE_KEY` is set in test scheme
- Ensure `TEST_USER_ID` is set correctly

## Security Notes

- **Never commit** `SUPABASE_SERVICE_ROLE_KEY` to git
- Service role key is only used in UI tests for cleanup
- Store sensitive values in Xcode scheme environment variables
