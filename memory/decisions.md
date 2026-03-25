# Decisions

Architecture choices, technology picks, and the reasoning behind them.
When future-you or an AI wonders "why was it done this way?" - the answer is here.

---

### 2026-03-08 | myportfolio | Switched from Framer Motion to GSAP for camera
**Why it came up**: Camera flythrough needed precise timeline control with ScrollTrigger.
**What I chose**: GSAP with timeline sequences — gsap.timeline() with scroll-pinned sections.
**What I rejected**: Framer Motion (great for UI, not for complex camera choreography), react-spring (physics-based, wrong mental model for scripted sequences).
**What would change my mind**: If Framer Motion adds timeline/ScrollTrigger-level features.
