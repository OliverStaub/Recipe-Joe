# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## RecipeJoe

This is a Recipe App

## Core Principles

- Iterative development: Small incremental changes only
- Question-first approach: Ask before assuming features
- Minimal changes: Add minimum needed to make it work
- User interaction required: No complex automatic workflows
- NEVER add features without explicit agreement
- Only Change Code related to the task we are working on, no random changes in other places.
- Do not commit yourself. the user will.

## Testing

This project uses unit tests and integration tests.

### Test Strategy

1. **Unit Tests** (`RecipeJoeTests`) - PREFERRED
   - Fast (~30 sec), no network, no simulator
   - Use for: validation, parsing, calculations, error handling, model tests

2. **Integration Tests** (`RecipeJoeIntegrationTests`) - For API testing
   - Async tests directly against Supabase
   - Use for: auth flows, RLS policies, API responses

Note: UI tests were removed to improve test speed and reliability.
Client-side validation logic is covered by unit tests.

### Guidelines

- Prefer unit tests when testing logic
- Remember to run tests when building new features

### Test Frameworks

- **Swift Testing** - Modern testing framework for unit tests (`@Test`, `#expect`)
- **XCUITest** - Apple's UI testing framework for end-to-end tests

### Test Targets

- `RecipeJoeTests` - Unit tests (fast, no simulator)
- `RecipeJoeIntegrationTests` - Integration tests (API, Supabase)

### Running Tests

**Quick Test Script:**

```bash
./scripts/run-tests.sh
```

This runs the same tests as the pre-commit hook (unit + integration tests).

**Other options:**

- Xcode: Product > Test (Cmd+U)
- Command line: `xcodebuild test -project RecipeJoe.xcodeproj -scheme RecipeJoe -destination 'platform=iOS Simulator,name=iPhone Air'`

### Git Hook Setup

A pre-commit hook is available to automatically run all tests before each commit.

**Installation:**

```bash
make install-hooks
```

**Usage:**

- Tests run automatically before each commit
- If tests fail, the commit is blocked
- To bypass in emergencies: `git commit --no-verify`

**Location:**

- Hook template: `scripts/pre-commit`
- Installed hook: `.git/hooks/pre-commit` (not tracked in git)

## iOS Recipe App Design System

See **[DESIGN_GUIDELINES.md](RecipeJoe/DESIGN_GUIDELINES.md)** for detailed spacing, layout, forms, and button guidelines.

**Color Scheme**

- Accent: Terracotta `#C65D00` (for active states, CTAs, selected items)
- Backgrounds: iOS system colors (systemBackground, secondarySystemBackground)
- Text: iOS semantic labels (label, secondaryLabel, tertiaryLabel)
- Glass buttons: Neutral with accent text/icons only

**Typography**

- SF Pro Display/Text
- Sizes: 34pt (titles), 22pt (headers), 17pt (body), 12pt (captions)

**Principle**: Native iOS feel with minimal custom colors - only terracotta accent

## Android App

### Development Philosophy
- iOS is the primary development platform
- Android is a downstream project
- New features are developed and tested in iOS first
- Android receives features after they're stable in iOS

### Location
`android/` folder at project root

### Tech Stack
- Language: Kotlin
- UI: Jetpack Compose
- Architecture: MVVM + Clean Architecture
- Database: Room (local cache)
- DI: Hilt
- Async: Coroutines + Flow
- HTTP: Ktor Client
- Image Loading: Coil
- Auth: Supabase Kotlin Client + Google Sign-In

### Project Structure
```
android/
├── app/src/main/java/com/recipejoe/
│   ├── data/           # Repositories, data sources, Room
│   ├── domain/         # Use cases, business logic
│   ├── presentation/   # UI (Compose), ViewModels
│   └── di/             # Hilt modules
```

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
- Android: Google Play Billing Library v7
- Backend: Both use Supabase for subscription management

Products (same as iOS):
- `tokens_10` - 10 tokens
- `tokens_25` - 25 tokens
- `tokens_50` - 50 tokens
- `tokens_100x` - 100 tokens

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

### Running Tests
```bash
cd android
./gradlew test                 # Unit tests
./gradlew connectedAndroidTest # Instrumented tests
```

### Building
```bash
cd android
./gradlew assembleDebug   # Debug APK
./gradlew assembleRelease # Release APK (requires signing)
```

### Android Development Guidelines

**UI Framework:**
- ALWAYS use Jetpack Compose for all UI
- NEVER use XML layouts or Views
- Use Material 3 components from `androidx.compose.material3`
- Follow Material Design 3 guidelines with RecipeJoe branding

**Compose Best Practices:**
- Use `@Composable` functions for all UI components
- Use `ViewModel` with `StateFlow` for state management
- Use `hiltViewModel()` for ViewModel injection in Composables
- Prefer `remember` and `rememberSaveable` for local state
- Use `LaunchedEffect` and `DisposableEffect` for side effects

**Code Style:**
- Use Kotlin idioms (scope functions, extension functions, etc.)
- Prefer `sealed class`/`sealed interface` for UI states
- Use `data class` for immutable state objects
- Use `Flow` for reactive data streams

**Architecture:**
- Follow MVVM + Clean Architecture
- ViewModels handle business logic, not Composables
- Repositories abstract data sources
- Use Hilt for dependency injection

**Android Design System (Material 3 adaptation of iOS guidelines):**

| iOS | Android |
|-----|---------|
| SF Pro | Roboto (default) |
| systemBackground | MaterialTheme.colorScheme.background |
| secondarySystemBackground | MaterialTheme.colorScheme.surfaceVariant |
| label | MaterialTheme.colorScheme.onSurface |
| secondaryLabel | MaterialTheme.colorScheme.onSurfaceVariant |
| Terracotta #C65D00 | MaterialTheme.colorScheme.primary |

**Spacing (same as iOS):**
- xs = 4.dp, sm = 8.dp, md = 12.dp, lg = 16.dp, xl = 24.dp, xxl = 40.dp

**Example Screen Pattern:**
```kotlin
@Composable
fun ExampleScreen(
    viewModel: ExampleViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()

    Scaffold(
        topBar = { TopAppBar(title = { Text("Title") }) }
    ) { padding ->
        // Content
    }
}
```
