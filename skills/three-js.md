# Three.js / React Three Fiber

R3F always in React projects. GSAP for camera timelines. Drei for the boring parts.

## How I Build
- React Three Fiber for everything — never raw Three.js in React projects.
- Drei helpers first — OrbitControls, Environment, Text, useGLTF. Don't reinvent.
- GSAP for complex camera flythroughs and timeline sequences. Not spring physics.
- Custom 3D typography with Text3D and custom fonts (Soria, Vercetti).
- `useGLTF` + Draco compression for all models. `useGLTF.preload()` outside components.
- Responsive 3D — FOV recalculation based on viewport via `useThree`.

## My 3D Projects
- **Portfolio**: Full WebGL experience — rotating 3D text tunnel, timeline, arc carousel of 11 projects, GSAP camera panning between sections, custom models
- **AlgoLabX**: Algorithm visualization with 3D elements
- **myportfolio**: 3D components in terminal-themed portfolio

## Expert Decisions

**Performance**: `<instancedMesh>` for 100+ identical objects (single draw call). `<Canvas dpr={[1, 2]}>` — cap pixel ratio even on 3x screens. Dispose everything in useEffect cleanup. `<Preload all />` for smooth initial render.

**Animation**: Animate refs directly (`ref.current.position`) — never React state for 3D transforms. `gsap.timeline()` for section-by-section camera journeys. ScrollTrigger for scroll-pinned 3D. Kill timelines on unmount.

**Models**: GLTF/GLB with Draco compression (90% smaller). `npx gltfjsx model.glb` generates declarative React components from models. Always behind `<Suspense>`.

**Lighting**: `<Environment preset="city" />` for instant PBR. `<ContactShadows>` for cheap ground shadows. Enable `shadows` on Canvas selectively — disable on mobile.

**Mobile**: Simpler materials (`meshBasicMaterial` over PBR). Disable shadows. Lower geometry subdivision. Custom touch handlers — default OrbitControls isn't optimized for touch. Adaptive DPR: `dpr={[1, isMobile ? 1.5 : 2]}`.

## Mistakes That Cost Hours
- Creating objects in `useFrame` — allocates every frame at 60fps, GC pauses cause visible stutters
- Forgetting resource disposal — geometries, materials, textures leak GPU memory
- Animating React state for 3D — causes full re-render, destroys frame rate
- Uncompressed textures — use KTX2, at minimum WebP
- Heavy computation in `useFrame` without throttling — it runs 60 times per second
- Missing `<Preload all />` — jarring asset pop-in on first frame
- Raw Three.js imperatively when R3F provides a declarative equivalent
