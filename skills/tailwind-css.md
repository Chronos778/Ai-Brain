# Tailwind CSS

Dark mode first. CSS variables for theming. CVA for component variants.

## How I Build
- `cn()` utility everywhere: `twMerge(clsx(...inputs))`.
- CVA for all component variants — typed, composable, predictable.
- CSS variables for all custom colors — enables runtime theme switching.
- Mobile-first: base styles = mobile, then `sm:`, `md:`, `lg:`.
- `tailwindcss-animate` for animation utilities. `@tailwindcss/typography` for prose.
- Never `@apply` except in global resets.

## My Palette
```css
:root {
  --dark-bg: #0A0E1A;
  --dark-card: #111827;
  --neon-blue: #00D9FF;
  --neon-purple: #B24BF3;
  --neon-green: #39FF14;
}
```

## Expert Decisions

**Spacing**: Use Tailwind's scale (4, 8, 12, 16, 20, 24). Never arbitrary `[13px]` — if you need it, the design system is broken.

**Animation**: Only `transform` and `opacity`. Never `transition-all` — list properties explicitly. `motion-safe:` prefix to respect `prefers-reduced-motion`.

**Dark mode**: CSS variables in `:root` and `.dark`. `color-scheme: dark` on `<html>` fixes native scrollbar/input/select colors. `<meta name="theme-color">` updates browser chrome.

**Layout**: `gap-4` over margin on children. `min-w-0` on flex children for text truncation. Container queries (`@container`) for component-level responsive.

**Accessibility**: `focus-visible:ring-2` on every interactive element. `sr-only` for screenreader text on icon-only buttons. `disabled:opacity-50 disabled:pointer-events-none`.

**Typography**: `text-wrap: balance` on headings. `font-variant-numeric: tabular-nums` for number columns. `truncate` for single-line, `line-clamp-3` for multi-line.

## Mistakes That Cost Hours
- `@apply` chains in CSS files — just write CSS at that point, you've defeated Tailwind
- Arbitrary values when tokens exist — `p-[17px]` means the design system is off
- `outline-none` without `focus-visible` replacement — keyboard users can't navigate
- `transition-all` — animates layout properties, causes jank
- Fighting Tailwind with custom CSS — work with the utility system
- `!important` via `!` prefix — if you need it, the specificity chain is broken
- Hardcoded color values in classes — always use theme tokens
