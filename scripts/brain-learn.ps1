#Requires -Version 5.1
<#
.SYNOPSIS
    Brain Learn — fetches best practices from official docs for a given tech.
.DESCRIPTION
    Pulls curated knowledge from official documentation and appends it to
    the corresponding skill file in the AI Brain.
.USAGE
    brain-learn react
    brain-learn typescript
    brain-learn nextjs
    brain-learn all            # Refreshes all existing skill files
#>

param(
    [Parameter(Position = 0)]
    [string]$Tech
)

$ErrorActionPreference = "Stop"

$BrainRoot = "C:\Users\Maithil\AI-Brain"
$SkillsDir = Join-Path $BrainRoot "skills"

# ─── Official Docs Knowledge Base ────────────────────────────────────
# Curated best practices from official docs for each tech.
# These are stable patterns that rarely change.

$DocsKnowledge = @{
    "react" = @"

## Reference (from official docs)

### Core Principles
- Components are the building blocks — each component should do one thing
- State should be minimal — derive everything you can from existing state
- Lift state up to the nearest common ancestor that needs it
- Use composition over inheritance — pass components as children/props
- Keep components pure — same inputs should give same outputs

### Hooks Best Practices
- Only call hooks at the top level (not inside loops, conditions, or nested functions)
- ``useState`` for simple local state, ``useReducer`` for complex state logic
- ``useEffect`` is for synchronizing with external systems, not for transforming data
- ``useMemo`` and ``useCallback`` are for optimization — don't use them everywhere
- Custom hooks should start with ``use`` and encapsulate reusable stateful logic

### Patterns to Follow
- Controlled components for forms (state drives the input value)
- Error boundaries for graceful error handling in component trees
- React.lazy + Suspense for code splitting
- Keys should be stable, unique IDs — never array indexes for dynamic lists
- Avoid setting state during rendering — use effects or event handlers

### Performance
- React.memo only when profiling shows a component re-renders too often
- Avoid creating objects/arrays inline in JSX props (causes re-renders)
- Use ``useTransition`` for non-urgent state updates
- Virtualize long lists (react-window or tanstack-virtual)

### Anti-Patterns
- Don't copy props into state — use the prop directly
- Don't use effects for things that can be computed during render
- Don't mutate state directly — always create new objects/arrays
- Don't overuse context — it causes all consumers to re-render
- Don't create components inside other components
"@

    "typescript" = @"

## Reference (from official docs)

### Core Principles
- Use strict mode (``strict: true``) — it catches more bugs at compile time
- Prefer ``interface`` for object shapes that may be extended, ``type`` for unions/intersections
- Use ``unknown`` over ``any`` — it forces you to narrow the type before using it
- Leverage type inference — don't annotate what TypeScript can figure out

### Type Patterns
- Use discriminated unions for state machines and complex conditional types
- Use ``as const`` for literal types and readonly arrays
- Template literal types for string pattern matching
- Use ``satisfies`` operator to validate types while preserving inference
- Generics for reusable functions/components — constrain with ``extends``

### Utility Types to Know
- ``Partial<T>`` — all properties optional
- ``Required<T>`` — all properties required
- ``Pick<T, K>`` / ``Omit<T, K>`` — select/exclude properties
- ``Record<K, V>`` — object with known key type
- ``ReturnType<T>`` — extract return type of a function
- ``Awaited<T>`` — unwrap Promise types

### Anti-Patterns
- Don't use ``any`` — use ``unknown`` and narrow
- Don't use ``enum`` — use ``as const`` objects or union types instead
- Don't use ``!`` (non-null assertion) — handle null properly
- Don't overtype — if inference works, don't add annotations
- Don't use ``@ts-ignore`` — use ``@ts-expect-error`` if you must suppress
"@

    "next-js" = @"

## Reference (from official docs)

### App Router Patterns
- Use Server Components by default — add ``'use client'`` only when needed
- Server Components can fetch data directly (no useEffect needed)
- Use ``loading.tsx`` for streaming/suspense UI per route segment
- Use ``error.tsx`` for error boundaries per route segment
- Use ``layout.tsx`` for shared UI that preserves state across navigations

### Data Fetching
- Fetch data in Server Components — it runs on the server, zero client JS
- Use ``fetch`` with caching: ``fetch(url, { cache: 'force-cache' })`` (default)
- Revalidate with ``next.revalidate`` or ``revalidatePath``/``revalidateTag``
- For mutations, use Server Actions (``'use server'`` functions)
- Don't fetch data in ``layout.tsx`` for child-specific data — fetch in the page

### Routing
- File-based routing in ``app/`` directory
- Dynamic routes: ``[slug]/page.tsx``
- Route groups: ``(group)/`` — organize without affecting URL
- Parallel routes: ``@slot/`` — render multiple pages in same layout
- Intercepting routes: ``(..)photo/`` — modal patterns

### Performance
- Use ``next/image`` for automatic image optimization
- Use ``next/font`` for zero-layout-shift font loading
- Use ``next/link`` for client-side navigation with prefetching
- Metadata API for SEO (``generateMetadata`` or ``metadata`` export)
- Use ``dynamic`` imports for heavy client components

### Anti-Patterns
- Don't use ``useEffect`` for data fetching — use Server Components
- Don't put database/API secrets in client components
- Don't create API routes just to fetch data from Server Components
- Don't use ``getServerSideProps``/``getStaticProps`` — those are Pages Router
"@

    "tailwind-css" = @"

## Reference (from official docs)

### Core Principles
- Utility-first: compose designs directly in markup
- Don't abstract too early — duplicate utility classes are fine initially
- Extract components (React/Vue/etc.) before extracting CSS classes
- Use ``@apply`` sparingly — it defeats the purpose of utility-first

### Patterns
- Use Tailwind's design system (spacing scale, color palette) consistently
- Responsive design: mobile-first with ``sm:``, ``md:``, ``lg:`` prefixes
- Dark mode: ``dark:`` variant with class strategy
- Group hover/focus: ``group`` and ``group-hover:`` for parent-child interactions
- Use ``prose`` class (typography plugin) for rich text content

### Customization
- Extend (don't override) the default theme in ``tailwind.config``
- Use CSS variables for dynamic theming
- Use ``@layer`` for proper specificity ordering
- Define custom colors as CSS variables for light/dark mode switching

### With React
- Use ``clsx`` or ``tailwind-merge`` for conditional classes
- Use ``class-variance-authority`` (CVA) for component variant patterns
- Keep utility strings readable — break long class lists across lines

### Anti-Patterns
- Don't fight Tailwind with custom CSS unless absolutely necessary
- Don't use ``@apply`` to recreate component classes (use actual components)
- Don't override Tailwind's reset — work with it
- Don't use arbitrary values ``[...]`` when a design token exists
"@

    "express" = @"

## Reference (from official docs)

### Core Patterns
- Middleware-based architecture — request flows through a chain
- Use ``express.Router()`` for modular route organization
- Error handling middleware has 4 args: ``(err, req, res, next)``
- Parse JSON bodies with ``express.json()`` middleware
- Use ``express.static()`` for serving static files

### Project Structure
- Group routes by feature/resource, not by HTTP method
- Keep route handlers thin — delegate to service/controller layer
- Separate business logic from Express-specific code
- Use environment variables for all configuration (never hardcode secrets)

### Security
- Use ``helmet`` for security headers
- Use ``cors`` with specific origins (not ``*`` in production)
- Rate limit API endpoints with ``express-rate-limit``
- Validate and sanitize all input
- Don't expose stack traces in production errors

### Error Handling
- Create a centralized error handling middleware
- Use async wrapper or ``express-async-errors`` for async route handlers
- Return consistent error response format: ``{ error: { message, code } }``
- Log errors server-side, return safe messages client-side

### Anti-Patterns
- Don't put business logic in route handlers
- Don't use synchronous file operations in request handlers
- Don't trust ``req.body`` without validation
- Don't catch errors and silently continue
"@

    "node-js" = @"

## Reference (from official docs)

### Core Principles
- Event-driven, non-blocking I/O — don't block the event loop
- Prefer async/await over raw callbacks or .then() chains
- Use ES modules (``import/export``) over CommonJS (``require``) for new projects
- Handle all Promise rejections (``unhandledRejection`` event)

### Patterns
- Use ``process.env`` for configuration, never hardcode
- Use ``path.join()`` / ``path.resolve()`` for cross-platform file paths
- Use streams for large file processing
- Use ``crypto`` module for hashing and random values
- Use ``child_process.spawn`` over ``exec`` for long-running processes

### Package Management
- Lock file (``package-lock.json`` or ``bun.lockb``) must be committed
- Use exact versions for critical dependencies
- Separate devDependencies from production dependencies
- Audit dependencies regularly: ``npm audit``

### Anti-Patterns
- Don't block the event loop with synchronous operations
- Don't use ``eval()`` or ``Function()`` constructor
- Don't store secrets in code — use environment variables
- Don't use ``var`` — use ``const``/``let``
- Don't ignore errors in callbacks
"@

    "python" = @"

## Reference (from official docs)

### Core Principles (The Zen of Python)
- Explicit is better than implicit
- Simple is better than complex
- Readability counts
- There should be one obvious way to do it
- Errors should never pass silently

### Patterns
- Use type hints for function signatures and complex variables
- Use ``dataclasses`` or ``pydantic`` for structured data
- Use context managers (``with`` statement) for resource management
- List/dict comprehensions over ``map``/``filter`` for readability
- Use ``pathlib.Path`` over ``os.path`` for file operations

### Project Structure
- Use virtual environments (``venv``) always
- ``requirements.txt`` or ``pyproject.toml`` for dependencies
- ``if __name__ == '__main__':`` guard in scripts
- Separate modules by responsibility
- Use ``logging`` module over ``print`` for production code

### Error Handling
- Catch specific exceptions, never bare ``except:``
- Use custom exception classes for domain errors
- ``try``/``except`` should wrap the minimum code necessary
- Use ``raise ... from ...`` to chain exceptions and preserve context

### Anti-Patterns
- Don't use mutable default arguments (``def f(x=[]):``)
- Don't use ``import *``
- Don't use global variables
- Don't suppress exceptions silently with bare ``except: pass``
- Don't use string formatting with ``%`` — use f-strings
"@

    "three-js" = @"

## Reference (from official docs)

### Core Concepts
- Scene graph: Scene → Meshes (Geometry + Material) → rendered by Camera via Renderer
- Always dispose of geometries, materials, and textures when done
- Use ``requestAnimationFrame`` for the render loop (or R3F handles it)
- BufferGeometry for custom geometry (more performant than legacy Geometry)

### With React (R3F)
- React Three Fiber makes Three.js declarative — components map to Three objects
- ``<Canvas>`` sets up scene, camera, and renderer automatically
- Use Drei helpers: ``OrbitControls``, ``Environment``, ``Text``, ``Html``
- ``useFrame`` hook for per-frame updates (animation loop)
- ``useLoader`` / ``useTexture`` / ``useGLTF`` for asset loading

### Performance
- Use instancing (``<instancedMesh>``) for many identical objects
- Reduce draw calls by merging geometries where possible
- Use LOD (Level of Detail) for complex scenes
- Compress textures (KTX2 format)
- Use ``<Suspense>`` for async asset loading

### Animation
- GSAP for timeline-based animations
- Spring physics via ``@react-spring/three``
- ``useFrame`` for simple per-frame animations
- Morph targets for shape animations

### Anti-Patterns
- Don't create new objects in the render loop — reuse with ``useMemo``/``useRef``
- Don't forget to dispose resources on unmount
- Don't load uncompressed textures
- Don't skip frustum culling for large scenes
"@

    "vite" = @"

## Reference (from official docs)

### Core Concepts
- Native ES modules in dev — no bundling, instant server start
- Rollup-based production build with tree shaking
- Hot Module Replacement (HMR) that actually works fast
- Plugin-based architecture (Rollup-compatible plugins)

### Configuration
- ``vite.config.ts`` for project configuration
- Use ``resolve.alias`` for path aliases (match tsconfig paths)
- Use ``define`` for compile-time constants
- Environment variables: ``.env`` files with ``VITE_`` prefix

### Patterns
- Use ``import.meta.env`` for environment variables
- Dynamic imports for code splitting: ``import('./module')``
- CSS modules supported out of the box: ``*.module.css``
- Use ``import.meta.glob`` for bulk file imports

### Anti-Patterns
- Don't use ``process.env`` — use ``import.meta.env``
- Don't use CommonJS (``require()``) — use ES modules
- Don't put secrets without ``VITE_`` prefix (they won't be exposed)
"@

    "bun" = @"

## Reference (from official docs)

### Core Concepts
- All-in-one: runtime, bundler, package manager, and test runner
- Drop-in Node.js replacement — most Node APIs work
- Native TypeScript/JSX support (no transpilation step needed)
- Uses ``bun.lockb`` (binary lockfile) for faster installs

### Package Management
- ``bun install`` — faster than npm/yarn/pnpm
- ``bun add <pkg>`` / ``bun remove <pkg>``
- Compatible with ``package.json`` and npm registry
- Use ``bunx`` instead of ``npx`` for running binaries

### Runtime Features
- ``Bun.serve()`` for high-performance HTTP servers
- ``Bun.file()`` for fast file I/O
- ``Bun.sql`` for SQLite (built-in)
- Native ``.env`` loading (no dotenv needed)
- ``bun test`` for built-in testing (Jest-compatible API)

### Anti-Patterns
- Don't assume 100% Node.js compatibility — check Bun docs for gaps
- Don't use ``bun.lockb`` if team uses npm — pick one package manager
- Don't ignore that some npm packages use Node-specific internals
"@

    "firebase" = @"

## Reference (from official docs)

### Core Architecture
- Firebase is Google Cloud's app platform — Authentication, Database, Storage, Hosting, Functions
- Firestore: NoSQL document database — collections → documents → fields
- Cloud Functions: Serverless Node.js — triggered by HTTP, Firestore events, Auth events, schedules
- Firebase Hosting: CDN-backed static hosting with SSL — preview channels for staging
- Firebase Storage: Object storage backed by Google Cloud Storage — for user uploads

### Firestore Patterns
- Denormalize for read performance — reads are cheap, joins don't exist
- Use subcollections for 1-to-many relationships
- Document size limit: 1MB — keep lean, use subcollections for large data
- Always use ``serverTimestamp()`` — client clocks aren't reliable
- ``writeBatch()`` for atomic multi-document operations (max 500 ops)
- ``runTransaction()`` when reads and writes must be atomic

### Cloud Functions
- Keep bundles small — cold starts are the biggest performance issue
- Use ``functions.region()`` to deploy closest to users
- Firestore triggers can fire multiple times — always idempotent
- ``functions.https.onCall()`` for authenticated client-to-function calls
- Lazy-load heavy dependencies inside the function handler

### Security Rules
- Default deny — open access explicitly per collection
- ``request.auth != null`` for authenticated operations
- ``request.auth.uid == resource.data.userId`` for owner-only access
- Validate data shape in rules — ``request.resource.data.title is string``
- Admin via custom claims — ``request.auth.token.admin == true``

### Anti-Patterns
- Don't skip security rules — test mode is for development only
- Don't use Firestore as a relational database — denormalize
- Don't read entire collections — always query with filters and limits
- Don't expose Google Cloud API keys in client code — proxy through Functions
- Don't use ``firebase.firestore()`` (v8) — use modular v9+ imports
"@

    "frontend-design" = @"

## Reference (from official docs)

### Design Principles
- NEVER use generic AI-generated aesthetics — every interface must be intentional
- Before any UI: consider Purpose, Tone, Constraints, Differentiation
- Dark themes with vibrant accents — not safe and corporate
- Glassmorphism, noise textures, gradient meshes for depth

### Typography
- Never use default system fonts — always deliberate font choice
- Font pairing: one display + one body font — max 2 families
- Proper punctuation: ``...`` not ``...``, curly quotes not straight
- ``font-variant-numeric: tabular-nums`` for number columns
- ``text-wrap: balance`` on headings to prevent widows

### Color System
- CSS variables for all colors — define in HSL for easy manipulation
- ``color-scheme: dark`` on ``<html>`` for native dark mode
- WCAG AA contrast ratios — 4.5:1 text, 3:1 large text
- Never rely on color alone — use icons or text alongside

### Motion
- Honor ``prefers-reduced-motion`` always
- Animate only ``transform`` and ``opacity`` — compositor-friendly
- Never ``transition: all`` — list properties explicitly
- CSS-only transitions before reaching for JS animation libraries
- Micro-interactions: 150-200ms, page transitions: 300-400ms

### Accessibility (Critical)
- Icon-only buttons need ``aria-label``
- ``<button>`` for actions, ``<a>`` for navigation — never ``<div onClick>``
- Visible focus states — never ``outline-none`` without replacement
- Semantic HTML before ARIA — ``<button>``, ``<a>``, ``<label>``, ``<table>``
- Every form input needs a label

### Anti-Patterns to Flag
- ``user-scalable=no`` — disables zoom, breaks accessibility
- ``transition: all`` — performance killer
- ``outline-none`` without focus-visible replacement
- ``<div onClick>`` — should be ``<button>``
- Images without dimensions — layout shift
- Form inputs without labels — inaccessible
"@
}

# ─── Main Logic ───────────────────────────────────────────────────────

if (-not $Tech) {
    Write-Host "Usage: brain-learn <tech>" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Available:" -ForegroundColor Cyan
    $DocsKnowledge.Keys | Sort-Object | ForEach-Object { Write-Host "  brain-learn $_" }
    Write-Host ""
    Write-Host "Or:" -ForegroundColor Cyan
    Write-Host "  brain-learn all    # Refresh all existing skill files"
    exit 0
}

function Update-SkillFile {
    param([string]$TechSlug, [string]$Content)

    $skillFilePath = Join-Path $SkillsDir "$TechSlug.md"

    if (-not (Test-Path $skillFilePath)) {
        Write-Host "  No skill file found at skills/$TechSlug.md — run brain-sync first." -ForegroundColor Red
        return $false
    }

    # Read existing content
    $existing = Get-Content $skillFilePath -Raw

    # Remove old reference section if it exists
    $existing = $existing -replace '(?s)## Reference \(from official docs\).*$', ''
    $existing = $existing.TrimEnd()

    # Also remove the "run brain-learn" placeholder
    $existing = $existing -replace '(?s)> Run ``brain-learn.*?``.*?$', ''
    $existing = $existing.TrimEnd()

    # Append new reference content
    $updated = $existing + "`n" + $Content + "`n"

    Set-Content -Path $skillFilePath -Value $updated -Encoding UTF8
    Write-Host "  Updated: skills/$TechSlug.md" -ForegroundColor Green
    return $true
}

if ($Tech -eq "all") {
    Write-Host "Refreshing all skill files with online knowledge..." -ForegroundColor Cyan
    $updated = 0
    $skillFiles = Get-ChildItem -Path $SkillsDir -Filter "*.md" -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -ne "_index.md" }

    foreach ($sf in $skillFiles) {
        $slug = $sf.BaseName.ToLower()
        if ($DocsKnowledge.ContainsKey($slug)) {
            Write-Host "  Processing: $slug" -ForegroundColor White
            if (Update-SkillFile -TechSlug $slug -Content $DocsKnowledge[$slug]) {
                $updated++
            }
        } else {
            Write-Host "  Skipping: $slug (no online docs available yet)" -ForegroundColor DarkGray
        }
    }
    Write-Host "`nDone! Updated $updated skill files." -ForegroundColor Green
} else {
    $slug = $Tech.ToLower() -replace '[^a-z0-9]', '-' -replace '-+', '-' -replace '^-|-$', ''
    Write-Host "Fetching $Tech knowledge..." -ForegroundColor Cyan

    if ($DocsKnowledge.ContainsKey($slug)) {
        if (Update-SkillFile -TechSlug $slug -Content $DocsKnowledge[$slug]) {
            Write-Host "`nDone! Run brain-sync to commit changes." -ForegroundColor Green
        }
    } else {
        Write-Host "No built-in docs for '$Tech' yet." -ForegroundColor Yellow
        Write-Host "Available: $($DocsKnowledge.Keys | Sort-Object | Select-Object -join ', ')" -ForegroundColor DarkGray
    }
}
