# Task: Add Android App to RecipeJoe

## Context
RecipeJoe is an existing iOS app (SwiftUI) with a complete backend (Supabase). You need to add a native Android app.

**IMPORTANT**:
- Read `CLAUDE.md` first - it contains the project guidelines
- The project already has backend, auth, billing - use them!
- You have **full write access** to the entire project
- Everything is in Git - feel free to restructure if needed

## Existing Project Structure

```
RecipeJoe/                          # Project root
├── RecipeJoe/                      # iOS app source code
│   ├── Models/                     # Data models
│   ├── Views/                      # SwiftUI views
│   ├── ViewModels/                 # MVVM view models
│   ├── Services/                   # API services (Supabase, etc.)
│   ├── Components/                 # Reusable UI components
│   ├── Extensions/                 # Swift extensions
│   ├── Utilities/                  # Helper utilities
│   └── DESIGN_GUIDELINES.md        # Design system reference
├── RecipeJoeTests/                 # Unit tests
├── RecipeJoeIntegrationTests/      # Supabase integration tests
├── supabase/                       # Backend
│   ├── functions/                  # Edge functions
│   └── migrations/                 # Database migrations
├── docs/                           # Documentation
├── scripts/                        # Build/test scripts
├── CLAUDE.md                       # Main project guidelines
└── android/                        # <-- NEW: Android app goes here
```

## Your Job

### 1. Analyze the Project
- Read `CLAUDE.md` completely
- Check the iOS app structure in `RecipeJoe/`
- Understand the Supabase backend in `supabase/`
- Look at models in `RecipeJoe/Models/`
- Identify core features from the iOS views

### 2. Update CLAUDE.md
Add a new section for Android:

```markdown
## Android App

### Development Philosophy
- iOS is the primary development platform
- Android is a downstream project
- New features are developed and tested in iOS first
- Android receives features after they're stable in iOS

### Tech Stack
- Language: Kotlin
- UI: Jetpack Compose
- Architecture: MVVM + Clean Architecture
- Database: Room (local cache)
- DI: Hilt
- Async: Coroutines + Flow
- HTTP: Ktor/Retrofit2
- Image Loading: Coil

### Platform Adaptations

#### Authentication
- iOS: Sign in with Apple
- Android: Google Sign-In (Firebase Auth)
- Backend: Both use Supabase Auth

**Manual Setup Required:**
1. Google Cloud Console: Create OAuth 2.0 credentials
2. Firebase project setup
3. Configure SHA-1 fingerprint
4. Details: see `docs/android/GOOGLE_SIGNIN_SETUP.md`

#### In-App Purchases
- iOS: StoreKit 2
- Android: Google Play Billing Library v6
- Backend: Both use Supabase for subscription management

**Manual Setup Required:**
1. Google Play Console: Create products
2. Testing with License Testers
3. Details: see `docs/android/BILLING_SETUP.md`

#### Push Notifications
- iOS: APNs
- Android: FCM
- Backend: Supabase Edge Functions for both

**Manual Setup Required:**
1. Firebase Cloud Messaging setup
2. Configure server key
3. Details: see `docs/android/FCM_SETUP.md`
```

### 3. Create Android Project Structure

Create the Android app in the `android/` folder at project root:

```
android/
├── app/
│   ├── src/
│   │   ├── main/
│   │   │   ├── java/com/recipejoe/
│   │   │   │   ├── data/           # Repositories, data sources
│   │   │   │   ├── domain/         # Use cases, business logic
│   │   │   │   ├── presentation/   # UI, ViewModels
│   │   │   │   └── di/             # Hilt modules
│   │   │   ├── res/                # Resources
│   │   │   └── AndroidManifest.xml
│   │   └── test/                   # Unit tests
│   ├── build.gradle.kts
│   └── proguard-rules.pro
├── build.gradle.kts
├── settings.gradle.kts
├── gradle.properties
├── gradlew
└── README.md                       # Android-specific docs
```

### 4. Implement Core Features

**Features to port from iOS** (check `RecipeJoe/Views/`):
1. AI-Powered Recipe Import (YouTube, TikTok, Websites, Docs/OCR)
2. Recipe CRUD Operations
3. Authentication (Google Sign-In instead of Apple)
4. In-App Purchases (Google Billing instead of StoreKit)
5. Push Notifications (FCM instead of APNs)
6. Image Handling
7. Search & Filter
8. Favorites/Tags

**Supabase Integration**:
- Use the **same** tables as iOS
- Use the **same** Row Level Security policies
- Use the **same** Edge Functions
- API calls via Supabase Kotlin Client

**Design System**:
- Read `RecipeJoe/DESIGN_GUIDELINES.md`
- Terracotta accent color: `#C65D00`
- Follow Material Design 3 with RecipeJoe branding

### 5. Create Setup Documentation

Create these docs for manual steps (the user must do these):

**`docs/android/GOOGLE_SIGNIN_SETUP.md`**:
- Google Cloud Console OAuth setup
- Firebase project creation
- SHA-1 fingerprint generation
- google-services.json placement

**`docs/android/BILLING_SETUP.md`**:
- Google Play Console product creation
- Subscription configuration
- Testing with license testers
- Webhook URL for Supabase

**`docs/android/FCM_SETUP.md`**:
- Firebase Cloud Messaging activation
- Server key configuration
- Notification channels implementation

### 6. Testing

- Write unit tests for ViewModels
- Write unit tests for Repositories
- Ensure Gradle build works
- Document test instructions

## Important Notes

### DO NOT:
- Create a new backend (Supabase is already running!)
- Rewrite API endpoints (use Supabase client!)
- Build auth from scratch (use Supabase Auth + Google Sign-In!)

### USE what exists:
- Supabase tables & RLS policies
- Supabase Edge Functions
- Existing backend logic
- Same Claude AI prompts (for recipe import)

### Git Commits:
Use conventional commits:
- `feat(android): add project structure`
- `feat(android): implement Google Sign-In`
- `feat(android): add Room database schema`
- `docs(android): add setup guides`

## Success Criteria

- [ ] Android app builds successfully (`./gradlew build`)
- [ ] CLAUDE.md updated with Android section
- [ ] Project structure created in `android/`
- [ ] Core features implemented
- [ ] Supabase integration working
- [ ] Setup docs created in `docs/android/`
- [ ] Unit tests written
- [ ] Clean git commit history
- [ ] README in android/ folder

## Getting Started

**Your first step**: Read `CLAUDE.md` and explore the iOS code in `RecipeJoe/`. Understand the data models and services before starting Android implementation.

Good luck!
