# Task: Add Android App to RecipeJoe

## Context
RecipeJoe ist eine bestehende iOS App (SwiftUI) mit vollständigem Backend (Supabase). Du sollst eine native Android App hinzufügen.

**WICHTIG**: 
- Lies zuerst `CLAUDE.md` im Projekt - das ist die Haupt-Dokumentation
- Das Projekt hat bereits Backend, Auth, Billing - nutze das!
- Du hast **volle Schreibrechte** auf das ganze Projekt
- Alles ist in Git - feel free to restructure wenn nötig

## Dein Job

### 1. Analysiere das Projekt
- Lies `CLAUDE.md` komplett durch
- Check die iOS App Struktur
- Verstehe das Supabase Backend
- Identifiziere die Core Features

### 2. Ergänze CLAUDE.md
Füge einen neuen Abschnitt hinzu:

```markdown
## Android App

### Development Philosophy
- iOS ist die primäre Entwicklungs-Plattform
- Android ist ein downstream project
- Neue Features werden zuerst in iOS entwickelt und getestet
- Android erhält Features nachdem sie in iOS stabil sind

### Tech Stack
- Language: Kotlin
- UI: Jetpack Compose
- Architecture: MVVM + Clean Architecture
- Database: Room
- DI: Hilt
- Async: Coroutines + Flow
- HTTP: Retrofit2
- Image Loading: Coil

### Platform Adaptations

#### Authentication
- iOS: Sign in with Apple
- Android: Google Sign-In (Firebase Auth)
- Backend: Beide nutzen Supabase Auth

**Manual Setup Required:**
1. Google Cloud Console: OAuth 2.0 Credentials erstellen
2. Firebase Projekt setup
3. SHA-1 Fingerprint konfigurieren
4. Details: siehe `docs/android/GOOGLE_SIGNIN_SETUP.md`

#### In-App Purchases  
- iOS: StoreKit 2
- Android: Google Play Billing Library v6
- Backend: Beide nutzen Supabase für Subscription Management

**Manual Setup Required:**
1. Google Play Console: Produkte anlegen
2. Testing mit License Testers
3. Details: siehe `docs/android/BILLING_SETUP.md`

#### Push Notifications
- iOS: APNs
- Android: FCM
- Backend: Supabase Edge Functions für beide

**Manual Setup Required:**
1. Firebase Cloud Messaging setup
2. Server Key konfigurieren
3. Details: siehe `docs/android/FCM_SETUP.md`
```

### 3. Projekt Struktur erstellen

Empfohlene Struktur:
```
RecipeJoe/
├── ios/                    # Bestehende iOS App
├── android/                # Neue Android App
│   ├── app/
│   │   ├── src/
│   │   │   ├── main/
│   │   │   │   ├── java/com/recipejoe/
│   │   │   │   │   ├── data/
│   │   │   │   │   ├── domain/
│   │   │   │   │   ├── presentation/
│   │   │   │   │   └── di/
│   │   │   │   ├── res/
│   │   │   │   └── AndroidManifest.xml
│   │   │   └── test/
│   │   ├── build.gradle.kts
│   │   └── proguard-rules.pro
│   ├── build.gradle.kts
│   ├── settings.gradle.kts
│   ├── gradle.properties
│   └── gradlew
├── backend/                # Shared Supabase (wenn existiert)
├── docs/
│   └── android/           # Android-specific Docs
│       ├── GOOGLE_SIGNIN_SETUP.md
│       ├── BILLING_SETUP.md
│       └── FCM_SETUP.md
├── CLAUDE.md              # Main documentation
└── README.md
```

**Oder**: Wenn du eine bessere Struktur siehst - go for it! Du hast volle Rechte.

### 4. Android App entwickeln

**Core Features** (von iOS übernehmen):
1. ✅ AI-Powered Recipe Import (YouTube, TikTok, Websites, Docs/OCR)
2. ✅ Recipe CRUD Operations
3. ✅ Authentication (Google statt Apple)
4. ✅ In-App Purchases (Google Billing statt StoreKit)
5. ✅ Push Notifications (FCM statt APNs)
6. ✅ Image Handling
7. ✅ Search & Filter
8. ✅ Favorites/Tags

**Supabase Integration**:
- Nutze die **gleichen** Tables wie iOS
- Nutze die **gleichen** Row Level Security Policies  
- Nutze die **gleichen** Edge Functions
- API calls via Supabase Kotlin Client

**Claude AI Integration**:
- Gleicher API Key Management Pattern
- Gleiche Prompt Templates
- Speichere Keys in Android EncryptedSharedPreferences

### 5. Autonomie & Subagents

Du kannst:
- Subagents spawnen für parallele Arbeit
- Z.B. ein Agent für UI, einer für Data Layer, einer für Supabase Integration
- Dependencies selbst installieren
- Projekt-Struktur anpassen wenn sinnvoll
- Commits machen mit meaningful messages

Beispiel Subagent:
```bash
claude "Implement Room database schema based on Supabase tables" --max-turns 30
```

### 6. Documentation erstellen

Erstelle diese Docs (der User muss manuelle Steps machen):

**`docs/android/GOOGLE_SIGNIN_SETUP.md`**:
- Google Cloud Console OAuth Setup Schritte
- Firebase Projekt erstellen
- SHA-1 Fingerprint generieren und konfigurieren
- google-services.json herunterladen und platzieren

**`docs/android/BILLING_SETUP.md`**:
- Google Play Console Produkte anlegen (matching iOS products)
- Subscription Details konfigurieren
- Testing mit License Testers
- Webhook URL für Supabase

**`docs/android/FCM_SETUP.md`**:
- Firebase Cloud Messaging aktivieren
- Server Key für Backend konfigurieren
- Notification Channels implementieren

### 7. Testing & Validation

- Schreibe Unit Tests für ViewModels
- Schreibe Unit Tests für Repositories  
- Stelle sicher dass Gradle build funktioniert
- Dokumentiere Test-Anweisungen

## Wichtige Hinweise

### ❌ **NICHT** nötig:
- Neues Backend erstellen (Supabase läuft bereits!)
- API Endpoints neu schreiben (Supabase Client nutzen!)
- Authentifizierung von Grund auf (Supabase Auth + Google Sign-In!)

### ✅ **Nutze was da ist**:
- Supabase Tables & RLS Policies
- Supabase Edge Functions
- Existierende Backend Logik
- Gleiche Claude AI Prompts

### 🤔 **Frag den User wenn**:
- Package name preference (z.B. `com.recipejoe.android`)
- Min SDK Version (empfohlen: 26 / Android 8.0)
- Farbschema / Brand Colors
- Spezifische Android-Features die Priorität haben

### 📝 **Git Commits**:
Nutze conventional commits:
- `feat(android): add project structure`
- `feat(android): implement Google Sign-In`  
- `feat(android): add Room database schema`
- `docs(android): add setup guides`
- etc.

## Success Criteria

✅ Android app builds successfully (`./gradlew build`)  
✅ CLAUDE.md updated with Android section  
✅ Project structure created (oder angepasst)  
✅ Core features implemented (matching iOS)  
✅ Supabase integration working  
✅ All setup docs created in `docs/android/`  
✅ Unit tests written  
✅ Clean git commit history  
✅ README updated (wenn nötig)

## Los geht's!

**Dein erster Schritt**: Lies `CLAUDE.md` und analysiere das Projekt. Dann frag den User via `AskUserQuestion` für Package Name, SDK Version, etc.

Viel Erfolg! 🚀
