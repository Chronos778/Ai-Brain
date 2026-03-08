# React

My primary UI layer. React 19 + TypeScript on everything.

## How I Build
- Server Components by default (Next.js). `'use client'` only for interactivity.
- Zustand for global state, TanStack Query for server state — never mixed.
- Radix UI primitives for accessible components. Never build modals/dropdowns from scratch.
- Framer Motion for transitions and micro-interactions.
- React Hook Form + Zod for forms. Controlled inputs only when per-keystroke state matters.
- One component per file. Named exports: `export function Component()`.
- Props interface exported as `{Component}Props`.
- Custom hooks for reusable stateful logic — prefix with `use`.

## Libraries I Reach For
Zustand, TanStack Query, React Hook Form, Framer Motion, Radix UI, Lucide React, Recharts, Sonner, cmdk, Vaul, Embla Carousel, React Three Fiber.

## Expert Decisions

**Data fetching**: Fetch where data is used, not in parent wrappers. `Promise.all()` for independent fetches. Prefetch on hover with `queryClient.prefetchQuery()`. Never chain sequential fetches when they're independent.

**Re-renders**: Zustand selectors — `useStore(s => s.count)` not `useStore()`. Move state down to the component that needs it. Split contexts by concern. Never create components inside render — they remount every time.

**Bundle size**: Import from subpaths, not barrel files. `React.lazy()` + Suspense for below-fold. Dynamic imports for heavy libraries (`dynamic(() => import('./Chart'), { ssr: false })`). Never import an entire icon library.

**State**: URL as state for filters/pagination (`nuqs` or `useSearchParams`). `useTransition` for non-urgent updates. `useDeferredValue` for expensive derivations from fast-changing values.

**Composition**: Compound components (`<Select><Select.Trigger/></Select>`) sharing state via internal context. Polymorphic `as` prop with `React.ElementType`. `createPortal` for overlays that escape parent overflow/z-index.

## Mistakes That Cost Hours
- `useEffect` for data transformation — compute during render or `useMemo`
- Copying props into state — derive from props directly
- Objects as `useMemo`/`useCallback` deps — the reference changes every render, use primitives
- `index` as key in dynamic lists — items shift, state leaks between rows
- `forceUpdate` or mutating `ref.current` to trigger renders — you've lost the mental model
- `<div onClick>` for interactive elements — accessibility, keyboard nav, focus all broken
- Suppressing `exhaustive-deps` lint — the bug is in your code, not the linter
- Fetching in `useEffect` when Server Components or TanStack Query would work
