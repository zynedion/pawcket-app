# Design Guide

> This is the single source of truth for UI/UX. All screens and components follow these rules.
> Reference these CSS variables and patterns when building components.

## Color System

### Primary Brand Colors
```css
--color-primary: #6366F1;              /* Indigo: Main CTA, active states */
--color-primary-dark: #4F46E5;         /* Darker indigo for hover/pressed */
--color-primary-light: #818CF8;        /* Lighter indigo for backgrounds */

--color-secondary: #0EA5E9;            /* Cyan/Sky blue: Accent, Mr. Oyen theme */
--color-secondary-light: #06B6D4;      /* Darker cyan */

--color-accent-danger: #EF4444;        /* Red: Overspending alerts, Mr. Oyen angry */
--color-accent-success: #10B981;       /* Green: Budget achieved, savings goals */
--color-accent-warning: #F59E0B;       /* Amber: Warnings, approaching budget limit */
```

### Neutral Colors
```css
--color-neutral-0: #FFFFFF;            /* Pure white: cards, surfaces */
--color-neutral-50: #F9FAFB;           /* Almost white: app background */
--color-neutral-100: #F3F4F6;          /* Light gray: subtle backgrounds */
--color-neutral-200: #E5E7EB;          /* Divider gray */
--color-neutral-500: #6B7280;          /* Medium gray: secondary text */
--color-neutral-700: #374151;          /* Dark gray: primary text on light bg */
--color-neutral-900: #111827;          /* Almost black: primary text */
```

### Category Colors (for pie chart & expense tracking)
```css
--category-food: #F97316;              /* Orange */
--category-transport: #0284C7;         /* Blue */
--category-entertainment: #A855F7;     /* Purple */
--category-utilities: #EAB308;         /* Yellow */
--category-healthcare: #EC4899;        /* Pink */
--category-shopping: #14B8A6;          /* Teal */
--category-housing: #78716C;           /* Brown */
--category-other: #6B7280;             /* Gray (default) */
```

## Typography

### Font Family
- **Primary:** Segoe UI, Roboto, -apple-system, BlinkMacSystemFont (system font stack)
- **Monospace:** Courier New, monospace (for amounts, timestamps)

### Font Sizes & Weights
| Role | Size (px) | Weight | Line Height | Example |
|------|-----------|--------|-------------|---------|
| Display | 32-40 | 700 (bold) | 1.2 | Page titles, major headers |
| Headline 1 | 28 | 700 | 1.3 | Dashboard title, feature headers |
| Headline 2 | 24 | 700 | 1.35 | Section headers, card titles |
| Body Large | 16 | 400/500 | 1.5 | Main text, descriptions |
| Body Regular | 14 | 400 | 1.5 | Primary UI text, labels |
| Body Small | 12 | 400 | 1.4 | Secondary text, captions, timestamps |
| Caption | 11 | 400 | 1.3 | Very small labels, hints |

### Text Colors
- **Primary text (headings, main content):** `--color-neutral-900`
- **Secondary text (captions, disabled):** `--color-neutral-500`
- **Accent text (CTAs, links):** `--color-primary`
- **Error/warning text:** `--color-accent-danger`
- **Success text:** `--color-accent-success`

## Spacing System

All spacing values follow an 8px grid base:
```css
--space-0: 0px;
--space-1: 4px;
--space-2: 8px;
--space-3: 12px;
--space-4: 16px;
--space-5: 20px;
--space-6: 24px;
--space-7: 28px;
--space-8: 32px;
--space-10: 40px;
--space-12: 48px;
--space-16: 64px;
```

### Padding & Margins by Component
| Component | Padding | Margin | Example |
|-----------|---------|--------|---------|
| Button | 12px 20px (vertical, horizontal) | 0 | Standard Material button |
| Input Field | 12px 16px | 0 bottom: 12px | Text input, search box |
| Card | 16px | 0 bottom: 12px | Dashboard cards, transaction tiles |
| Screen padding | 16px (all sides) | — | Main screen content area |
| Bottom nav | — | 0 | Sticky at bottom |

## Components & Patterns

### Buttons
**Primary Button (CTA)**
- Background: `--color-primary`
- Text color: white
- Padding: 12px 20px
- Border radius: 8px
- Font weight: 600
- Font size: 14px
- State:
  - Enabled: primary color
  - Hovered: `--color-primary-dark`
  - Pressed: `--color-primary-dark` + slight opacity
  - Disabled: `--color-neutral-200` + `--color-neutral-500` text

**Secondary Button**
- Background: `--color-neutral-100`
- Text color: `--color-primary`
- Padding: 12px 20px
- Border radius: 8px
- Border: 1px solid `--color-primary-light`

**Danger Button (Delete, Confirm overspending)**
- Background: `--color-accent-danger`
- Text color: white
- State: Same hover/pressed as Primary

### Input Fields
- Border: 1px solid `--color-neutral-200`
- Border radius: 8px
- Padding: 12px 16px
- Font size: 14px
- Focus state:
  - Border color: `--color-primary`
  - Box shadow: 0 0 0 3px rgba(99, 102, 241, 0.1)
- Error state:
  - Border color: `--color-accent-danger`
  - Helper text: `--color-accent-danger`
  - Box shadow: 0 0 0 3px rgba(239, 68, 68, 0.1)
- Disabled state:
  - Background: `--color-neutral-100`
  - Border color: `--color-neutral-200`
  - Text color: `--color-neutral-500`

### Cards
- Background: `--color-neutral-0` (white)
- Border radius: 12px
- Box shadow: 0 1px 3px rgba(0, 0, 0, 0.1) (subtle elevation)
- Padding: 16px
- Margin bottom: 12px
- Border: 1px solid `--color-neutral-100`

### Transaction Tile
- Type: Card variant
- Layout: Horizontal
  - Left: Category icon (48px × 48px, background color from category)
  - Center: description + date (line height 1.5)
  - Right: amount (bold, primary text color)
- Status indicator: Dot (green for pending sync, gray for synced)

### Chart Components (Pie Chart, Bar Chart)
- Use category colors defined above
- Label font size: 12px
- Legend below chart, 2-column layout on mobile
- Animations: Fade-in on load (200ms)

### Chat Bubble (Mr. Oyen conversations)
- User message: Indigo (`--color-primary`), right-aligned, rounded corners (20px)
- Assistant message (Mr. Oyen): Secondary color (`--color-secondary`), left-aligned, with cat icon
- Avatar: 40px × 40px circle, Mr. Oyen 3D asset
- Padding inside bubble: 12px 16px
- Max width: 85% of screen
- Spacing between bubbles: 8px

### Bottom Navigation Bar
- Height: 60px (safe area included)
- Background: `--color-neutral-0` with subtle shadow
- Icons: 24px × 24px, centered
- Label: 10px, below icon
- Active state: `--color-primary` (icon + label)
- Inactive state: `--color-neutral-500` (icon + label)
- Tap target: 48px × 48px (minimum accessibility)

## Responsive Design

### Breakpoints
```css
--breakpoint-mobile: 320px;            /* Small phones */
--breakpoint-tablet: 768px;            /* Tablets, landscape phones */
--breakpoint-desktop: 1024px;          /* Not applicable for mobile app (v1) */
```

### Mobile-First Approach (Primary: Android phones 360-480px width)
- Single-column layout on mobile
- Full-width cards and buttons
- Bottom navigation fixed
- Minimum touch target: 48px × 48px
- Maximum line length for readability: 50 characters (text-heavy screens)

### Landscape Mode (secondary support)
- Tab layout may convert to horizontal scroll
- Sidebar optional (if screen > 600px wide)
- Bottom nav may convert to top nav

## Accessibility

### WCAG 2.1 AA Compliance
- **Color contrast:** Minimum 4.5:1 for normal text, 3:1 for large text
- **Touch targets:** Minimum 48px × 48px (Android Material Design 3)
- **Text sizing:** Users can scale up to 200% without loss of functionality
- **Focus indicators:** Clear focus outlines (1px solid primary color) on interactive elements

### Text & Readability
- No text smaller than 11px (caption size)
- Line height minimum 1.4 for readability
- Avoid pure black text on pure white (use neutral-900 on neutral-0)
- Links must be underlined or otherwise visually distinct from body text

### Voice & Semantics
- All icons must have meaningful labels or aria-labels
- Buttons must have descriptive text (avoid "Click here")
- Form fields must have associated labels
- Headings must follow hierarchical order (h1 > h2 > h3)

### Dark Mode (Future Feature)
Future versions will support dark mode by inverting the neutral color palette:
```css
/* Dark mode overrides (future) */
--color-neutral-0-dark: #111827;       /* Dark background */
--color-neutral-900-dark: #F9FAFB;     /* Light text on dark bg */
```

## Animation & Transition Timing

### Transition Durations
- **Micro interactions (button hover):** 100ms ease-in-out
- **Page transitions:** 200ms ease-in-out
- **Loading indicators:** Continuous loop (500ms per rotation)
- **Chart animations:** 300ms ease-out (stagger if multiple elements)

### Easing Functions
- Standard: `cubic-bezier(0.4, 0, 0.2, 1)` (ease-in-out)
- Enter: `cubic-bezier(0, 0, 0.2, 1)` (ease-out)
- Exit: `cubic-bezier(0.4, 0, 1, 1)` (ease-in)

## Mr. Oyen Mascot Design

### Asset Requirements
- **3D render style:** Realistic, photorealistic orange cat
- **Size options:** 64px, 128px, 256px (for different screen contexts)
- **Expressions (key moods):**
  - `happy_budget_safe`: Smiling, relaxed (spending is good)
  - `neutral_normal`: Standard pose, peaceful
  - `shocked_overspending`: Wide eyes, mouth open (caught overspending)
  - `angry_boss`: Frowning, stern expression (dramatic scolding)
  - `sleepy_tired`: Half-closed eyes, laid-back (lazy assistant)
  - `thinking`: Paw on chin, contemplative (generating advice)

### Placement
- **Chat screen:** Top-left corner of chat bubble (40px × 40px avatar)
- **Dashboard header:** Floating element (optional, context-aware mood)
- **Onboarding:** Full-screen welcome (128px × 128px)
- **Alerts (overspending):** Overlay modal with angry expression (256px × 256px)

### Animation Rules
- Fade-in: 200ms when mood changes
- Bounce: Subtle scale animation (90% → 100%) when Mr. Oyen responds
- No animation for static displays (e.g., avatar in sidebar)

## Dark Mode Consideration (Future)

While v1 is light-mode only, the design system is color-token-based for easy future migration:
- All colors use CSS variables (not hardcoded hex)
- Component structure supports theme switching
- Typography and spacing remain constant between light and dark modes

