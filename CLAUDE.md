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
