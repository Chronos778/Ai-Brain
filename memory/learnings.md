# Learnings

Things I've figured out that are worth remembering. Not documentation - insights.
Each entry should save future-me at least 30 minutes.

---

### 2026-03-08 | R3F Performance
useFrame runs every frame (60fps). Creating objects inside it allocates memory 60 times per second. The GC pauses became visible as frame drops in the portfolio 3D scene.
Fix: Pre-allocate vectors with useMemo, mutate them in useFrame.

### 2026-03-08 | Firestore Cold Starts
Cloud Functions with heavy top-level imports (like @google-cloud/vision) add 2-3s to cold starts.
Fix: Lazy-import inside the function handler. Cold start dropped to ~400ms.
-->
