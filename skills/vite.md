---
name: vite
description: Vite configuration for React projects with TypeScript and manual chunks
---
# Vite

For all non-Next.js React projects. TypeScript config always.

## How I Build
- `vite.config.ts` — always TypeScript.
- Path aliases matching `tsconfig.json`: `@/` maps to `src/`.
- `VITE_` prefix for all client-exposed env vars.
- Dev proxy for backend API calls — no CORS issues in development.
- PostCSS + Tailwind pipeline.

## Expert Decisions

**Code splitting**: Dynamic `import()` creates chunks automatically. Manual chunks for vendor splitting: `manualChunks: { vendor: ['react', 'react-dom'] }`. Run `rollup-plugin-visualizer` after adding any dependency.

**Env vars**: `.env`, `.env.local`, `.env.production`. Only `VITE_` vars exposed to client — never put secrets there. Create `env.d.ts` with `ImportMetaEnv` for autocompletion. Parse with Zod at app init — fail fast on missing values.

**Dev server**: Proxy config forwards API calls to backend. HMR works automatically with `@vitejs/plugin-react`. Assets under 4KB auto-inlined as base64.

**Performance**: `import.meta.glob` for bulk imports. Worker imports handled natively. Conditional dev-only imports tree-shaken in production.

## Mistakes That Cost Hours
- `process.env` in Vite — use `import.meta.env`, `process` doesn't exist in browser
- `require()` — ES modules only, CommonJS breaks Vite
- Secrets with `VITE_` prefix — embedded in client bundle, exposed to everyone
- `resolve.alias` without matching tsconfig paths — IDE and bundler disagree on imports
- Missing `.env.local` in `.gitignore` — secrets committed to repo
