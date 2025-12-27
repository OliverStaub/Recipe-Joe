# Google Sign-In Setup for RecipeJoe Android

This guide walks you through setting up Google Sign-In for the Android app.

## Prerequisites

- Google Cloud Console account
- Firebase project (recommended for easier setup)
- Android Studio

## Step 1: Create a Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Add project"
3. Enter project name: `RecipeJoe` (or your preferred name)
4. Enable/disable Google Analytics as needed
5. Click "Create project"

## Step 2: Add Android App to Firebase

1. In Firebase Console, click "Add app" and select Android
2. Enter package name: `com.recipejoe`
3. Enter app nickname: `RecipeJoe Android`
4. Get your SHA-1 fingerprint:

```bash
# For debug keystore
cd android
./gradlew signingReport
```

Or manually:

```bash
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
```

5. Enter the SHA-1 fingerprint
6. Click "Register app"
7. Download `google-services.json`
8. Place it in `android/app/google-services.json`

## Step 3: Enable Google Sign-In in Firebase

1. Go to Firebase Console > Authentication
2. Click "Sign-in method" tab
3. Click "Google" and enable it
4. Add your support email
5. Click "Save"

## Step 4: Get Web Client ID

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Select your Firebase project
3. Go to "APIs & Services" > "Credentials"
4. Find the "Web client" OAuth 2.0 Client ID
5. Copy the Client ID (it looks like: `xxxx.apps.googleusercontent.com`)

## Step 5: Configure Android App

1. Open `android/app/build.gradle.kts`
2. Replace `YOUR_WEB_CLIENT_ID` with your actual Web Client ID:

```kotlin
buildConfigField("String", "GOOGLE_WEB_CLIENT_ID", "\"your-client-id.apps.googleusercontent.com\"")
```

## Step 6: Link to Supabase

1. Go to Supabase Dashboard > Authentication > Providers
2. Enable Google provider
3. Enter your Google Client ID and Client Secret
4. Save changes

### Getting Client Secret

1. Go to Google Cloud Console > APIs & Services > Credentials
2. Click on your Web Client ID
3. Copy the Client Secret

## Step 7: Configure Authorized Redirect URIs

In Google Cloud Console, add these redirect URIs:

```
https://<your-supabase-project>.supabase.co/auth/v1/callback
```

## Troubleshooting

### Error: DEVELOPER_ERROR

- Make sure SHA-1 fingerprint is correctly added to Firebase
- Verify the package name matches exactly
- Ensure `google-services.json` is up to date

### Error: 10 (Developer Error)

- The Web Client ID might be incorrect
- Check that Google Sign-In is enabled in Firebase

### Error: Sign-in cancelled

- This is normal when user cancels the sign-in flow

## Testing

1. Build and run the app on a device/emulator with Google Play Services
2. Click "Sign in with Google"
3. Select a Google account
4. Verify successful authentication

## Production Checklist

- [ ] Add production SHA-1 fingerprint from release keystore
- [ ] Test on multiple devices
- [ ] Verify Supabase integration works
- [ ] Test sign-out and re-sign-in flows
