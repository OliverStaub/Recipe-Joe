# RecipeJoe Design Guidelines

Design principles for consistent, accessible UI.

---

## Spacing Scale

Use consistent spacing values throughout the app:

| Size | Value | Usage                                    |
| ---- | ----- | ---------------------------------------- |
| xs   | 4pt   | Icon-text gaps, minimal spacing          |
| sm   | 8pt   | Badges, compact elements, button padding |
| md   | 12pt  | Section internals, row spacing           |
| lg   | 16pt  | Content padding, standard spacing        |
| xl   | 24pt  | Section spacing, major separations       |
| 2xl  | 40pt  | Form horizontal padding                  |

**Rule:** Space elements based on how related they are—closer = more related.

---

## Grouping Principles

Group related elements using these methods (can combine):

### 1. Containers

Use borders, shadows, or backgrounds to enclose related elements.

- Cards for grouped content
- Sections with background colors
- Strongest visual grouping method

### 2. Proximity

Place related elements close together, separate unrelated elements.

- Prefer proximity over containers when possible (cleaner design)
- Use spacing scale consistently

### 3. Similarity

Make related elements look alike (size, shape, color).

- Same styling = same function
- Different styling = different function

### 4. Continuity

Align related elements in a line (lists, rows).

- Break continuity to highlight or separate

---

## Visual Hierarchy

Create clear order of importance:

| Method   | More Important    | Less Important |
| -------- | ----------------- | -------------- |
| Size     | Larger            | Smaller        |
| Color    | Terracotta/bright | Gray/muted     |
| Contrast | High contrast     | Low contrast   |
| Weight   | Bold              | Regular        |
| Position | Top/first         | Bottom/last    |
| Depth    | Elevated (shadow) | Flat           |

**Test:** Squint at your design—important elements should still stand out.

---

## Buttons

### Three Button Weights

| Type      | Usage                          | Style                     |
| --------- | ------------------------------ | ------------------------- |
| Primary   | Main action (1 per screen max) | Terracotta bg, white text |
| Secondary | Less important actions         | Bordered or plain style   |
| Tertiary  | Least important                | Text-only                 |

### Button Rules

- Height: 50pt for full-width buttons
- Minimum tap target: 48x48pt
- Text describes action: "Save Recipe" not "Submit"
- Avoid disabled buttons when possible—explain why action isn't available
- Left-align buttons in forms
- Add friction to destructive actions (confirmation)

---

## Forms

### Layout

- Single column layout (never side-by-side fields on mobile)
- Horizontal padding: 40pt
- Field corner radius: 10pt

### Labels & Fields

- Labels above fields, close to them
- Field width matches expected input length
- Use `.roundedBorder` or custom with systemGray6 background
- Group related fields under headings

### Validation

- Validate on submit, not inline
- Clear error messages explaining how to fix
- Mark optional fields (not required)

---

## Touch Targets

- **Minimum size: 48x48pt** for all interactive elements
- Keep related actions close together (reduces interaction cost)
- Place primary actions within thumb reach on mobile

---

## Containers & Cards

### Corner Radius

| Size | Usage                           |
| ---- | ------------------------------- |
| 16pt | Large containers, header images |
| 12pt | Cards, section containers       |
| 10pt | Buttons                         |
| 8pt  | Small badges, thumbnails        |

### Backgrounds

- `.systemGray6` - Content containers
- `.systemGray5` - Secondary/disabled
- `.terracotta.opacity(0.15)` - Accent backgrounds
- `.secondarySystemBackground` - Sections

---

## Quick Reference

```
Spacing: 4 → 8 → 12 → 16 → 24 → 40
Corner radius: 8 → 10 → 12 → 16
Button height: 50pt
Tap target: 48pt minimum
Primary color: Terracotta #C65D00
```
