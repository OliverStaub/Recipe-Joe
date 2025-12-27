# RecipeJoe Android

Native Android app for RecipeJoe - AI-powered recipe import and management.

## Features

- **AI Recipe Import**: Import recipes from YouTube, TikTok, Instagram, websites, images, and PDFs
- **Google Sign-In**: Secure authentication via Google
- **Recipe Management**: View, edit, favorite, and delete recipes
- **Token-based Usage**: In-app purchases for AI import tokens
- **Offline Support**: Local caching with Room database
- **Material Design 3**: Modern UI with Terracotta (#C65D00) accent

## Tech Stack

- **Language**: Kotlin
- **UI**: Jetpack Compose
- **Architecture**: MVVM + Clean Architecture
- **DI**: Hilt
- **Database**: Room (local cache)
- **Network**: Supabase Kotlin Client + Ktor
- **Image Loading**: Coil
- **Async**: Coroutines + Flow

## Project Structure

```
app/src/main/java/com/recipejoe/
├── data/
│   ├── local/          # Room database, DAOs, entities
│   ├── remote/         # Supabase client, DTOs
│   └── repository/     # Repository implementations
├── domain/
│   └── model/          # Domain models
├── presentation/
│   ├── auth/           # Authentication screens
│   ├── home/           # Home/recipe list
│   ├── recipe/         # Recipe detail, add recipe
│   ├── settings/       # Settings screen
│   ├── navigation/     # Navigation graph
│   └── theme/          # Material 3 theme
└── di/                 # Hilt modules
```

## Setup

### Prerequisites

- Android Studio Hedgehog (2023.1.1) or later
- JDK 17
- Android SDK 35

### Configuration

1. **Clone the repository**
   ```bash
   git clone <repo-url>
   cd RecipeJoe/android
   ```

2. **Set up Google Sign-In**
   - Follow instructions in `docs/android/GOOGLE_SIGNIN_SETUP.md`
   - Place `google-services.json` in `app/`
   - Update `GOOGLE_WEB_CLIENT_ID` in `app/build.gradle.kts`

3. **Configure Supabase** (already done)
   - Supabase URL and anon key are preconfigured in `app/build.gradle.kts`
   - Uses the same backend as the iOS app

4. **Build the app**
   ```bash
   ./gradlew assembleDebug
   ```

## Development

### Building

```bash
# Debug build
./gradlew assembleDebug

# Release build
./gradlew assembleRelease

# Clean build
./gradlew clean assembleDebug
```

### Testing

```bash
# Unit tests
./gradlew test

# Instrumented tests (requires emulator/device)
./gradlew connectedAndroidTest
```

### Code Quality

```bash
# Lint check
./gradlew lint
```

## Manual Setup Required

The following require manual configuration in external services:

1. **Google Sign-In**: See `docs/android/GOOGLE_SIGNIN_SETUP.md`
2. **In-App Purchases**: See `docs/android/BILLING_SETUP.md`
3. **Push Notifications**: See `docs/android/FCM_SETUP.md`

## Architecture

### Data Flow

```
UI (Compose) → ViewModel → Repository → Supabase/Room
                    ↑
              StateFlow/Flow
```

### Key Patterns

- **Single Activity**: One MainActivity with Compose navigation
- **Unidirectional Data Flow**: State flows down, events flow up
- **Repository Pattern**: Abstracts data sources
- **Dependency Injection**: Hilt for all dependencies

## Backend

The Android app shares the backend with the iOS app:

- **Database**: Supabase PostgreSQL
- **Auth**: Supabase Auth (Google provider for Android, Apple for iOS)
- **Storage**: Supabase Storage for recipe images
- **Edge Functions**: Recipe import, OCR, purchase validation

## Design System

Based on iOS design guidelines adapted for Material Design 3:

- **Primary Color**: Terracotta #C65D00
- **Typography**: Material 3 type scale
- **Spacing**: 4dp → 8dp → 12dp → 16dp → 24dp → 40dp
- **Corner Radius**: 8dp → 10dp → 12dp → 16dp
- **Touch Targets**: 48dp minimum

## License

Proprietary - All rights reserved
