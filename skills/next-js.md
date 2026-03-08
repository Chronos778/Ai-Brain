# Next.js

App Router only. Server-first architecture. Deploy to Vercel.

## How I Build
- Server Components by default. `'use client'` pushed to leaf components only.
- `generateMetadata` for dynamic SEO per page.
- Route groups `(marketing)/`, `(dashboard)/` for different layouts.
- `loading.tsx`, `error.tsx`, `not-found.tsx` per route segment.
- Server Actions for mutations — `<form action={createPost}>`.
- `next/image`, `next/font`, `next/link` on everything — non-negotiable.
- Custom fonts with zero CLS (Soria, Vercetti in portfolio).

## Expert Decisions

**Data fetching**: `async/await` in Server Components directly. `React.cache()` to deduplicate identical fetches across components. `Promise.all()` for parallel. Suspense boundaries for progressive streaming of slow data.

**Revalidation**: Time-based `{ next: { revalidate: 3600 } }` for content that updates occasionally. On-demand `revalidatePath()` or `revalidateTag()` inside Server Actions after mutations. Default to ISR.

**Client boundary**: Keep `'use client'` as deep and small as possible. A page should never be fully client — extract only the interactive widget.

**Routing**: `[slug]` for dynamic, `[...slug]` for catch-all, `@modal` for parallel routes, `(.)photo/[id]` for intercepting routes. `generateStaticParams()` for pre-rendering dynamic routes at build time.

**Route handlers**: `app/api/route.ts` only for webhooks and third-party integrations. Never for fetching data in your own app — that's what Server Components do.

**Middleware**: Edge-only, project root. Auth checks, redirects, geolocation. No DB calls — JWT verification and header manipulation only. `config.matcher` to skip static assets.

## Project Structure
```
app/
  (marketing)/       # Public pages
  (dashboard)/       # Auth-required pages
  api/webhooks/      # External integrations only
  layout.tsx         # Root: html, body, providers, fonts
components/
  ui/                # Shared primitives
  [feature]/         # Feature-specific
lib/
  actions/           # Server Actions
  db/                # Database layer
```

## Mistakes That Cost Hours
- `useEffect` for data fetching in App Router — use Server Components
- Entire page as `'use client'` — only the interactive parts need it
- API routes for internal data fetching — Server Components fetch directly
- Data fetching in `layout.tsx` for child-specific data — layouts are for layout
- `getServerSideProps`/`getStaticProps` — Pages Router legacy, doesn't exist in App Router
- `window`/`document` in Server Components — they don't exist on the server
- Heavy libraries in Server Components that are only useful client-side
