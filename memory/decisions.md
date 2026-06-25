# Decisions

Architecture choices, technology picks, and the reasoning behind them.
When future-you or an AI wonders "why was it done this way?" - the answer is here.

---

### 2026-03-12 | orelli | Full-stack Next.js over headless CMS
**Problem**: Architecture firm site needed CMS, admin dashboard, featured projects, category galleries, enquiry forms.
**Options considered**:
- Headless CMS (Sanity/Contentful) + separate frontend
- Full-stack Next.js + Prisma + TypeScript
**Chosen approach**: Full-stack Next.js with Prisma
**Tradeoffs**: More upfront work building admin UI, but zero monthly CMS costs, full control over data schema, no vendor lock-in
**Revisit trigger**: If client needs non-technical editors (they don't, it's Matt building it)
**Why this won**: Direct Prisma access means custom queries, no API rate limits, and the admin dashboard is a portfolio piece itself

### 2026-03-20 | git-rewind | Rust for CLI tool
**Problem**: Needed a fast, distributable CLI with cryptographic update verification.
**Options considered**:
- Python (Click)
- Go (Cobra)
- Node.js (Commander)
- Rust (Clap)
**Chosen approach**: Rust with Clap
**Tradeoffs**: Steeper learning curve, slower iteration, but single static binary, zero runtime deps, and memory safety matters for file I/O
**Revisit trigger**: Never for this use case - Rust is correct here
**Why this won**: SHA256 checksum verification on self-update needs memory safety guarantees and fast execution.

### 2026-04-10 | SpotiFLAC | Go for API-heavy tool
**Problem**: Music tool needing Qobuz/Amazon API integration, robust retry/backoff logic, and concurrent downloads.
**Options considered**:
- Python (requests/asyncio)
- Node.js (axios/promises)
- Go (goroutines/net/http)
**Chosen approach**: Go
**Tradeoffs**: Verbose error handling, but extremely predictable concurrency model and easy cross-compilation.
**Revisit trigger**: If complex data science/ML parsing is needed later.
**Why this won**: Go's native concurrency (goroutines) makes handling multiple API streams and downloads trivial compared to async/await overhead.

### 2026-04-15 | SpotiFLAC | Exponential backoff pattern
**Problem**: Qobuz/Amazon APIs aggressively rate limit during bulk metadata fetches.
**Options considered**:
- Linear retries (e.g., retry 3 times with 1s delay)
- Exponential backoff with jitter
**Chosen approach**: Exponential backoff with jitter
**Tradeoffs**: Can slightly delay completion of large batches, but prevents IP blacklisting.
**Revisit trigger**: If API providers introduce official rate limit headers (Retry-After).
**Why this won**: Linear retries just hammered the API in waves; jitter prevents thundering herd on our own retry mechanism.

### 2026-05-02 | puff | Multi-provider TTS cascade
**Problem**: Video pipeline needed reliable text-to-speech, but providers often hit rate limits or fail.
**Options considered**:
- Single reliable provider (ElevenLabs)
- Round-robin load balancing
- Multi-provider cascade (ElevenLabs → Sarvam → Edge)
**Chosen approach**: Multi-provider cascade with fallback
**Tradeoffs**: More complex state management and error handling, but guarantees audio generation completes.
**Revisit trigger**: If ElevenLabs Enterprise removes quota concerns.
**Why this won**: Video rendering pipeline must not fail silently midway; falling back to lower-quality TTS is better than a broken video.

### 2026-05-18 | puff | V2 pipeline architecture
**Problem**: V1 video rendering had overlapping audio, misaligned captions, and no SFX.
**Options considered**:
- Patch V1 timeline logic
- Complete rewrite for V2 with hard cuts and dynamic captions
**Chosen approach**: V2 rewrite with hard cuts and SFX support
**Tradeoffs**: Paused feature development for 2 weeks, but resulted in frame-accurate rendering.
**Revisit trigger**: If moving to a visual node-based editor.
**Why this won**: V1 timeline math was fundamentally flawed for variable-framerate inputs; V2 hard cuts guarantee synchronization.

### 2026-06-01 | quote.web | PWA architecture with service worker
**Problem**: Quote app needed offline support and fast loading, plus light/dark theme persistence.
**Options considered**:
- Standard SPA with localStorage
- Full PWA with Service Worker caching
**Chosen approach**: PWA architecture with service worker caching
**Tradeoffs**: Cache invalidation complexity (stale CSS on theme updates), but native app feel.
**Revisit trigger**: If we port to React Native/Flutter.
**Why this won**: Instant loading is critical for a quotes app; service worker handles offline gracefully.

### 2026-06-10 | foodbook/recipe-book | Vanilla JS with no framework
**Problem**: Need an editorial-style CSS framework and modular components for recipe display.
**Options considered**:
- React/Next.js
- Vue/Nuxt
- Vanilla JS + Custom CSS Framework
**Chosen approach**: Vanilla JS with no framework
**Tradeoffs**: Manual DOM manipulation and state management, but zero build step and ultimate control over typography/layout.
**Revisit trigger**: If state becomes too complex (e.g., interactive meal planning).
**Why this won**: The project is heavily design-focused (editorial style); a framework would add unnecessary weight to static content.

### 2026-06-15 | myportfolio | Three.js/R3F over CSS animations
**Problem**: Portfolio needed immersive 3D WebGL camera flythroughs and custom 3D typography.
**Options considered**:
- Advanced CSS 3D transforms
- Spline exports
- Three.js + React Three Fiber (R3F)
**Chosen approach**: Three.js/R3F
**Tradeoffs**: Heavy initial payload (WebGL context), but infinite creative freedom.
**Revisit trigger**: If WebGPU becomes standard and R3F isn't keeping up.
**Why this won**: True 3D camera control (GSAP timelines) is impossible with CSS; R3F integrates 3D seamlessly into React state.
