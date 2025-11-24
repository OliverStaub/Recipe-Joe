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

## Testing

This project uses both unit tests and UI tests to ensure code quality.

### Test-Driven Development Requirements

**IMPORTANT:** When implementing any feature or creating implementation plans:

- ALWAYS include a step to write end-to-end tests for the new feature
- Tests should verify the feature works correctly from the user's perspective
- Every feature implementation plan must include test writing as a required step
- Tests should be written in `RecipeJoeUITests` for UI features
- - remember to run the test when you have built out a new feature

### Test Frameworks

- **Swift Testing** - Modern testing framework for unit tests
- **XCUITest** - Apple's UI testing framework for end-to-end tests

### Test Targets

- `RecipeJoeTests` - Unit tests
- `RecipeJoeUITests` - UI/end-to-end tests

### Running Tests

**Quick Test Script:**

```bash
./scripts/run-tests.sh
```

This runs the same tests as the pre-commit hook (unit + UI tests).

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

**Color Scheme**

- Accent: Terracotta `#C65D00` (for active states, CTAs, selected items)
- Backgrounds: iOS system colors (systemBackground, secondarySystemBackground)
- Text: iOS semantic labels (label, secondaryLabel, tertiaryLabel)
- Glass buttons: Neutral with accent text/icons only

**Typography**

- SF Pro Display/Text
- Sizes: 34pt (titles), 22pt (headers), 17pt (body), 12pt (captions)

**Principle**: Native iOS feel with minimal custom colors - only terracotta accent
