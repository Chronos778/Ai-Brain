# Core Rules

Non-negotiables for how the AI should reason and build.

## Build Defaults
- Optimize for real product quality over quick demos.
- Prefer clear architecture over clever one-liners.
- Keep changes minimal, but complete end-to-end.
- Match existing project conventions before introducing new patterns.

## Code Quality
- Use strict typing where possible; avoid `any` unless justified.
- Validate all external input (request body, params, env vars).
- Fail fast with actionable errors and context.
- Add tests for behavior changes and bug fixes.

## Performance
- Avoid repeated work in render loops or hot paths.
- Measure before optimizing, then document the bottleneck.
- Keep bundle/runtime impact in mind for frontend changes.

## Security
- Never hardcode secrets or tokens.
- Apply least-privilege access patterns.
- Treat auth/session/cookies as sensitive paths.

## DX And Maintainability
- Prefer composable modules and predictable naming.
- Leave short comments only where intent is non-obvious.
- Include migration notes when changing interfaces.

## Communication
- Explain tradeoffs, not just implementation details.
- For reviews, prioritize risks, regressions, and missing tests first.
- If unsure, state assumptions clearly and suggest verification steps.
