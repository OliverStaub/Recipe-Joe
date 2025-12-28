# Android App - Feature Parity TODO

This document tracks features and changes from the iOS app that need to be implemented in the Android app.

## Changes from December 28, 2025

### UI/UX Changes

- [ ] **Recipe Import Loading UI**
  - Replace progress bar with spinning logo animation (fork.knife icon)
  - Center the spinner vertically on the import screen
  - Show large green checkmark (80dp) with fade-in transition on success
  - Keep informational text below the spinner

- [ ] **Recipe Step Emojis**
  - Display emoji prefixes instead of text for recipe step types:
    - `prep:` → 🔪
    - `heat:` → 🔥
    - `cook:` → 🍳
    - `mix:` → 🥄
    - `assemble:` → 🍽️
    - `bake:` → ♨️
    - `rest:` → ⏸️
    - `finish:` → ✨
  - Implemented in iOS at `StepRow.swift` - create equivalent in Compose

- [ ] **Single Image Import**
  - Limit photo picker to single image selection (no multiple images)
  - Simplifies Claude Vision processing and avoids file size errors

### Localization

- [ ] **Token Purchase Screen**
  - Localize token count strings ("120 Tokens", etc.)
  - Localize "token" vs "tokens" (singular/plural) in pricing rows
  - Localize error messages

- [ ] **Import Progress Text**
  - Add German/Swiss German translations for "You can leave this screen - your recipe will appear when ready."

### Backend (Already Done - Shared)

These changes were made to the Supabase Edge Functions and apply to both iOS and Android:

- [x] **Structured Import Logging**
  - All imports now log to console with structured format
  - Includes: user_id, import_type, source, status, recipe_name, tokens_used, duration, Claude API token usage
  - Both success and failure cases are logged

- [x] **Single File Upload Enforcement**
  - Edge function now rejects multiple file uploads
  - Returns error: "Only single file uploads are supported"

## Existing Feature Parity Items

### Authentication
- [ ] Google Sign-In implementation
- [ ] Sign out flow
- [ ] Account deletion

### Recipe Management
- [ ] Recipe list view
- [ ] Recipe detail view
- [ ] Recipe editing
- [ ] Recipe deletion
- [ ] Recipe search

### Import Features
- [ ] URL import
- [ ] Video import (YouTube, TikTok, Instagram)
- [ ] Image import (single photo)
- [ ] PDF import
- [ ] Camera capture

### Tokens & Purchases
- [ ] Token balance display
- [ ] Token purchase flow (Google Play Billing)
- [ ] Insufficient tokens alert

### Settings
- [ ] Language selection
- [ ] Reword preference toggle
- [ ] About screen

## Notes

- iOS is the primary development platform
- Features should match iOS behavior and design (adapted for Material Design 3)
- See `CLAUDE.md` for Android-specific architecture guidelines
