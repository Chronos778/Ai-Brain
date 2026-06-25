---
name: svelte
description: Svelte and SvelteKit patterns for reactive frontends
---

# Svelte / SvelteKit

My framework for highly reactive, low-overhead frontend applications.

## How I Build
- **SvelteKit** as the meta-framework for routing and SSR. Never just bare Svelte unless it's a micro-component embedded in another site.
- **Vite** for the build tool (built into SvelteKit).
- Tailwind CSS for styling, using standard `<style>` blocks only for hyper-specific component animations.
- TypeScript strictly enabled in all `<script lang="ts">` blocks.

## Expert Decisions
- **State**: Avoid complex external stores (like Redux or Zustand) unless absolutely necessary. Svelte's native `$store` and context API are more than enough for 99% of apps.
- **Reactivity**: Use `$:` reactive statements carefully. Group related reactive logic into a single statement to avoid waterfall updates.
- **Form Actions**: Always use SvelteKit's native `use:enhance` for progressive enhancement on forms instead of manually hijacking `onSubmit`.

## Mistakes That Cost Hours
- Mutating an array or object without reassigning it. Svelte reactivity triggers on assignment (`arr = arr`), not on mutation (`arr.push()`).
- Using `onMount` for data fetching. Always use SvelteKit's `+page.server.ts` or `+page.ts` `load` functions so the data is available during SSR.
- Forgetting that reactive statements `$:` run *after* the component mounts and the DOM updates, leading to layout shifts if you depend on them for initial styling.
