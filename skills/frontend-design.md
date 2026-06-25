---
name: frontend-design
description: Dark aesthetic design system with glassmorphism, neon accents, and motion-first UI
---
# Frontend Design

Dark, intentional, slightly dangerous. Never generic. Never safe.

## My Design Identity
- Dark themes with neon accents: `#00D9FF`, `#B24BF3`, `#39FF14`
- Glassmorphism: `backdrop-blur-xl bg-white/5 border border-white/10`
- Gradient meshes, noise textures, dot patterns for depth
- Framer Motion on everything interactive. WebGL where it adds value.
- Custom typography — Brass Mono for code, Soria/Vercetti for 3D.

## Before Every UI
1. What mood should this evoke? (not just "clean" — that's the baseline)
2. What makes this NOT look like every other AI-generated template?
3. Mobile constraints? Dark mode? Performance budget?

## Expert Decisions

**Typography**: Never default system fonts. One display + one body font, max 2 families. `text-wrap: balance` on headings. `font-variant-numeric: tabular-nums` for data. Proper ellipsis, curly quotes.

**Color**: CSS variables in HSL for all colors. `color-scheme: dark` on `<html>`. WCAG AA contrast (4.5:1 text, 3:1 large). Never rely on color alone — use icons or text alongside.

**Motion**: `prefers-reduced-motion` always honored. Only animate `transform` and `opacity`. Never `transition: all`. Timings — micro: 150-200ms, page: 300-400ms, complex: 600-1000ms. CSS transitions first, then Framer Motion, then GSAP for complex timelines.

**Layout**: Asymmetric layouts create energy — don't center everything. White space creates hierarchy. Gap over margin. `min-w-0` on flex children. `env(safe-area-inset-*)` for mobile notches.

**Accessibility**: `<button>` for actions, `<a>` for navigation — never `<div onClick>`. `aria-label` on icon-only buttons. `focus-visible:ring-2` on all interactives. Every form input needs a `<label>`. `autocomplete` on form inputs. Never block paste.

**Content**: Active voice. Title Case for headings. Specific button labels ("Save API Key" not "Submit"). Error messages include the fix, not just the problem.

## Code Smells — Flag Immediately
- `user-scalable=no` — breaks zoom accessibility
- `<div onClick>` — should be `<button>`
- `outline-none` without `focus-visible` replacement — keyboard users locked out
- `transition: all` — performance killer
- Images without `width`/`height` — layout shift
- Form inputs without labels — inaccessible
- Icon buttons without `aria-label` — screenreaders get nothing
- Large arrays `.map()` without virtualization (50+ items)
- `autoFocus` without justification — disorienting on mobile
