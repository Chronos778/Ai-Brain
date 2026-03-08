# Frontend Design

> Elite design principles sourced from Anthropic Frontend Design guidelines + Vercel Web Interface Guidelines.
> Applied across all your frontend projects.

## Design Philosophy

**NEVER use generic AI-generated aesthetics.** Every interface should feel intentional, opinionated, and slightly dangerous — not safe and corporate. Design should evoke a specific mood, not just "look clean."

---

## Design Thinking (before writing code)

### Before Every UI Task, Consider:
1. **Purpose**: What is this interface trying to accomplish? What emotion should it evoke?
2. **Tone**: Is this playful? Serious? Minimal? Luxurious? Technical? (your default: technical + bold)
3. **Constraints**: What are the technical limitations? Mobile? Dark mode? Low bandwidth?
4. **Differentiation**: What makes this NOT look like every other AI-generated template?

### Your Design Identity
- Dark themes with neon/vibrant accents (neon-blue #00D9FF, neon-purple #B24BF3, neon-green #39FF14)
- Glassmorphism cards with backdrop-blur
- Cyberpunk-inspired aesthetic with technical precision
- Smooth Framer Motion animations — never static UIs
- WebGL/3D elements where they add value (not decoration)

---

## Typography

### Rules
- **Never use default system fonts or generic sans-serif** — always specify a deliberate font choice
- **Font pairing**: One display/heading font + one body font — max 2 families
- **Hierarchy through weight and size**: Not just size — use font-weight variations
- **Proper punctuation**: `…` not `...`, curly quotes `"` `"` not straight `"`
- **Tabular numbers**: `font-variant-numeric: tabular-nums` for data tables and counts
- **`text-wrap: balance`** on headings — prevents orphaned words
- **Loading states end with `…`**: "Loading…", "Saving…", "Processing…"
- **Non-breaking spaces**: `10&nbsp;MB`, `⌘&nbsp;K` — prevent awkward line breaks
- **Numerals for counts**: "8 deployments" not "eight deployments"

### Font Choices (your stack)
- **Brass Mono** as your editor font — use in terminal/code UI elements
- **Custom 3D fonts**: Soria, Vercetti for WebGL typography
- Use `next/font` or Fontsource for zero-CLS font loading

---

## Color & Theme System

### Rules
- **CSS variables for all colors**: `--primary`, `--background`, `--foreground`, `--accent`
- **Define in HSL**: `--primary: 220 90% 56%` — easy to manipulate programmatically
- **Light/dark via class strategy**: `.dark` class on `<html>`, theme tokens swap via CSS variables
- **Dominant + accent pattern**: One dominant color sets the mood, sharp accents for CTAs and highlights
- **`color-scheme: dark`** on `<html>` — fixes native scrollbar, input, select colors in dark mode
- **`<meta name="theme-color">`** — matches page background, updates browser chrome
- **Contrast ratios**: WCAG AA minimum — 4.5:1 for text, 3:1 for large text
- **Never rely on color alone**: Icons, patterns, or text alongside color indicators

### Your Palette
```css
:root {
  --dark-bg: #0A0E1A;
  --dark-card: #111827;
  --dark-border: #1F2937;
  --neon-blue: #00D9FF;
  --neon-purple: #B24BF3;
  --neon-green: #39FF14;
  --neon-cyan: #00FFFF;
}
```

---

## Motion & Animation

### Principles
- **Honor `prefers-reduced-motion`**: Always provide reduced variant — `motion-safe:` prefix in Tailwind
- **Animate only `transform` and `opacity`**: Compositor-friendly — smooth 60fps
- **Never `transition: all`**: List properties explicitly — `transition-colors`, `transition-transform`
- **Set correct `transform-origin`**: Scale from the right point — not always center
- **Animations are interruptible**: User actions mid-animation should be smooth, not janky
- **CSS-only when possible**: Use CSS transitions/keyframes before reaching for JS animation libs
- **Scroll-triggered animations**: Intersection Observer + CSS transitions — or Framer Motion viewport animations
- **Hover states on everything interactive**: Every button, link, card gets hover feedback

### Motion Library Hierarchy
1. CSS transitions/keyframes (simplest, most performant)
2. Framer Motion (React integration, gesture support, layout animations)
3. GSAP (complex timelines, ScrollTrigger, 3D camera animations)

### Timing
- **Micro-interactions**: 150-200ms — button hover, toggle switch
- **Page transitions**: 300-400ms — route changes, modal open/close
- **Complex animations**: 600-1000ms — hero sections, loading sequences
- **Easing**: `ease-out` for entrances, `ease-in` for exits, `ease-in-out` for symmetric transforms

---

## Spatial Composition & Layout

### Principles
- **Asymmetric layouts create energy**: Don't center everything — offset grids, varying column widths
- **Overlap elements intentionally**: Cards overlapping images, text over gradients with proper contrast
- **Grid-breaking elements**: Full-bleed images, elements that cross layout boundaries
- **White space is a design tool**: Don't fill every pixel — breathing room creates hierarchy
- **Visual rhythm**: Consistent spacing scale — don't randomize padding/margins

### Layout Patterns
- **Flex/Grid over JS measurement**: Layout with CSS — never JavaScript for positioning
- **`min-w-0` on flex children**: Required for text truncation inside flex containers
- **Safe areas**: `env(safe-area-inset-*)` for notch-aware mobile layouts
- **Overflow control**: `overflow-x-hidden` on scroll containers, not body
- **Gap over margin**: `gap-4` on flex/grid parents instead of margin on children

---

## Backgrounds & Textures

### Techniques
- **Gradient meshes**: Multi-point CSS gradients for depth — not flat solid colors
- **Noise/grain overlays**: Subtle SVG noise filter adds texture — `filter: url(#noise)` or CSS grain
- **Dot/grid patterns**: Subtle background patterns at low opacity for technical feel
- **Glassmorphism**: `backdrop-blur-xl bg-white/5 border border-white/10` for frosted glass cards
- **Never use generic stock photo backgrounds** — create visual interest with CSS gradients and patterns

---

## Accessibility (Vercel Web Interface Guidelines)

### Critical Rules
- **Icon-only buttons need `aria-label`**: `<button aria-label="Close"><X /></button>`
- **Form controls need `<label>` or `aria-label`**: Every input must be labelable
- **`<button>` for actions, `<a>`/`<Link>` for navigation**: Never `<div onClick>`
- **Keyboard handlers**: Interactive elements need `onKeyDown`/`onKeyUp`
- **Visible focus states**: `focus-visible:ring-2` — never `outline-none` without replacement
- **Use `:focus-visible` over `:focus`**: Avoid focus ring on mouse click
- **Semantic HTML first**: `<button>`, `<a>`, `<label>`, `<table>` — before ARIA
- **Heading hierarchy**: `<h1>` → `<h6>` in order — include skip link for main content
- **Images need `alt`**: Descriptive for content images, `alt=""` for decorative
- **`aria-live="polite"`** for async updates (toasts, validation messages)

### Forms
- **Inputs need `autocomplete` and meaningful `name`** attributes
- **Correct `type`**: `email`, `tel`, `url`, `number` — and proper `inputmode`
- **Never block paste**: No `onPaste` + `preventDefault`
- **Labels clickable**: `htmlFor` on label or wrap control with label
- **Disable spellcheck** on emails, codes, usernames: `spellCheck={false}`
- **Error messages inline next to fields**: Focus first error on submit
- **Placeholders end with `…`** and show example pattern
- **Warn before navigation with unsaved changes**: `beforeunload` or router guard

### Touch & Mobile
- **`touch-action: manipulation`**: Prevents double-tap zoom delay
- **Min touch target**: 44x44px minimum for all interactive elements
- **`overscroll-behavior: contain`**: In modals/drawers/sheets — prevents scroll bleed
- **`autoFocus` sparingly**: Desktop only, single primary input — avoid on mobile

---

## Images & Media

### Rules
- **Always `width` and `height`** on `<img>` — prevents CLS (Cumulative Layout Shift)
- **Below-fold images**: `loading="lazy"` — browser-native lazy loading
- **Above-fold critical images**: `priority` or `fetchpriority="high"` — load immediately
- **Use `next/image`** in Next.js — automatic WebP/AVIF, responsive sizes, lazy loading
- **SVG for icons**: Inline SVG or Lucide React — never raster images for icons

---

## Content & Copy

### Writing Rules
- **Active voice**: "Install the CLI" not "The CLI will be installed"
- **Title Case for headings/buttons**: Chicago style
- **Specific button labels**: "Save API Key" not "Continue" or "Submit"
- **Error messages include fix/next step**: Not just the problem
- **Second person**: "Your projects" not "My projects"
- **`&` over "and"** where space-constrained
- **Numerals for counts**: "8 deployments" not "eight deployments"

---

## Anti-Patterns to Flag

These are code smells in any UI codebase — fix immediately:
- `user-scalable=no` or `maximum-scale=1` — disabling zoom breaks accessibility
- `onPaste` with `preventDefault` — blocking paste is hostile UX
- `transition: all` — performance killer, animate specific properties
- `outline-none` without `focus-visible` replacement — keyboard users can't navigate
- `<div onClick>` — should be `<button>` or `<a>`
- Images without dimensions — causes layout shift
- Large arrays `.map()` without virtualization — above 50 items, use virtual list
- Form inputs without labels — inaccessible
- Icon buttons without `aria-label` — screenreader users get nothing
- Hardcoded date/number formats — use `Intl.DateTimeFormat` / `Intl.NumberFormat`
- `autoFocus` without justification — disorienting on mobile
