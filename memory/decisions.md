# Decisions

Architecture choices, technology picks, and the reasoning behind them.
When future-you or an AI wonders "why was it done this way?" - the answer is here.

---

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
