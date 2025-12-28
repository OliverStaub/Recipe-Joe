# Recipe Sharing Feature

> **Status:** Planned
> **Priority:** Medium
> **Complexity:** Medium-High

## Overview

Add a share button to recipes that lets users share via WhatsApp, Messages, etc. Recipients can open the link to get a copy of the recipe in their own account.

**Share URL format:** `https://oliverstaub.github.io/Recipe-Joe/r/{share_token}`

## User Flow

1. User taps share button (top-right, standard iOS share icon) in recipe detail view
2. iOS share sheet appears with WhatsApp, Messages, Mail, etc.
3. Recipient clicks the shared link:
   - Landing page detects platform (iOS/Android)
   - Attempts to open app via deep link `recipejoe://share/{token}`
   - If app not installed → redirects to App Store / Play Store
   - Before app is published → shows "Coming Soon" message
4. If recipient has the app:
   - App opens and prompts login (if not logged in)
   - Recipe is COPIED to recipient's account
   - Recipient can edit their copy without affecting the original

## Technical Architecture

### Database Changes

**New columns in `recipes` table:**
- `share_token TEXT UNIQUE` - URL-safe token for sharing (12 chars, ~72 bits entropy)
- `shared_from_recipe_id UUID` - References original recipe if this was received via share

**New SQL migration:** `supabase/migrations/007_recipe_sharing.sql`

```sql
ALTER TABLE recipes ADD COLUMN share_token TEXT UNIQUE;
ALTER TABLE recipes ADD COLUMN shared_from_recipe_id UUID REFERENCES recipes(id);
CREATE INDEX idx_recipes_share_token ON recipes(share_token) WHERE share_token IS NOT NULL;
```

### Backend (Edge Functions)

**1. `get-share-token`**
- Input: `recipeId`
- Returns existing share token or generates a new one
- Only recipe owner can request their token
- Uses service role for token generation

**2. `accept-shared-recipe`**
- Input: `shareToken`
- Validates the token exists
- Fetches original recipe (service role bypasses RLS)
- Creates a copy for the authenticated recipient
- Copies all steps and ingredients
- Returns new recipe ID
- Prevents duplicates (if user already has this recipe, returns existing copy)

### iOS Implementation

**New files:**
- `RecipeJoe/Services/ShareService.swift` - Client for share APIs
- `RecipeJoe/Components/ShareSheet.swift` - UIActivityViewController wrapper

**Modified files:**
- `RecipeJoe/Views/RecipeDetailView.swift` - Add toolbar with share button
- `RecipeJoe/RecipeJoeApp.swift` - Handle `recipejoe://share/{token}` deep links
- `RecipeJoe/Shared/Constants.swift` - Add share base URL constant

**Share button implementation:**
```swift
.toolbar {
    ToolbarItem(placement: .topBarTrailing) {
        Button {
            Task { await shareRecipe() }
        } label: {
            Image(systemName: "square.and.arrow.up")
        }
    }
}
```

### Landing Page (GitHub Pages)

**New files in `docs/`:**
- `share.html` - Main landing page with smart redirect logic
- `404.html` - Routes `/r/{token}` to `share.html?token={token}`

**Landing page logic:**
1. Extract token from URL
2. Detect platform via user agent
3. Attempt deep link via hidden iframe
4. Wait 2 seconds, check if page is hidden (app opened)
5. If app didn't open → show fallback with store buttons

**Configuration flag:**
```javascript
const isPublished = false; // Set to true when app is in stores
```

## Files Summary

### New Files
| File | Purpose |
|------|---------|
| `supabase/migrations/007_recipe_sharing.sql` | Database schema changes |
| `supabase/functions/get-share-token/index.ts` | Get/generate share token |
| `supabase/functions/accept-shared-recipe/index.ts` | Copy recipe to recipient |
| `RecipeJoe/Services/ShareService.swift` | iOS client for share APIs |
| `RecipeJoe/Components/ShareSheet.swift` | Share sheet wrapper |
| `docs/share.html` | Landing page for share links |
| `docs/404.html` | URL routing for GitHub Pages |

### Modified Files
| File | Changes |
|------|---------|
| `RecipeJoe/Views/RecipeDetailView.swift` | Add toolbar with share button |
| `RecipeJoe/RecipeJoeApp.swift` | Handle `recipejoe://share/{token}` deep links |
| `RecipeJoe/Shared/Constants.swift` | Add `shareBaseURL` constant |

## Pre-Publishing vs Post-Publishing

| Feature | Before Publishing | After Publishing |
|---------|-------------------|------------------|
| Share button | Works | Works |
| Deep links | TestFlight only | All users |
| Landing page | Shows "Coming Soon" | Shows store buttons |
| Store redirect | N/A | App Store / Play Store |

**Post-publishing changes:**
1. Set `isPublished = true` in `share.html`
2. Update App Store URL: `https://apps.apple.com/app/recipejoe/id{APP_ID}`
3. Update Play Store URL: `https://play.google.com/store/apps/details?id=com.oliverstaub.recipejoe`

## Android Implementation (Future)

- Add share button to recipe detail screen (Jetpack Compose)
- Add intent filter in `AndroidManifest.xml`:
  ```xml
  <intent-filter>
      <action android:name="android.intent.action.VIEW" />
      <category android:name="android.intent.category.DEFAULT" />
      <category android:name="android.intent.category.BROWSABLE" />
      <data android:scheme="recipejoe" android:host="share" />
  </intent-filter>
  ```
- Implement ShareService using Ktor client

## Security Considerations

- Share tokens are URL-safe, 12 characters (~72 bits entropy)
- Tokens can be regenerated if needed (not in MVP)
- Original recipe remains private; only a copy is shared
- Recipients must be authenticated to accept shared recipes
- Duplicate detection prevents spam/abuse

## Testing Checklist

- [ ] Share button appears in recipe detail view
- [ ] Share sheet shows correct URL format
- [ ] Landing page opens on mobile browser
- [ ] Deep link opens app (if installed)
- [ ] Login required before accepting share
- [ ] Recipe is copied to recipient's account
- [ ] Steps and ingredients are copied correctly
- [ ] Duplicate shares return existing copy
- [ ] Original recipe unaffected by recipient's edits

## Dependencies

- Supabase Edge Functions runtime
- GitHub Pages for landing page hosting
- iOS 16+ for ShareLink (or UIActivityViewController fallback)
