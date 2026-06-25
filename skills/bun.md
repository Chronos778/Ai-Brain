---
name: bun
description: Bun patterns for fast runtime and bundling
---

# Bun

My fast JavaScript runtime, package manager, and bundler.

## How I Build
- `bun install` as the default package manager for extreme speed.
- `bun run` for script execution.
- Use `bun.lockb` for deterministic, fast installs.
- Leverage Bun's native APIs (`Bun.serve`, `Bun.file`) for small backend scripts instead of Node.js polyfills when possible.

## Expert Decisions
- **Tooling**: Use Bun as a drop-in replacement for Node.js in CI/CD pipelines to drastically cut down build times.
- **Bundling**: Use Bun's native bundler for small projects or serverless functions to avoid complex Vite/Webpack configs.
- **Testing**: `bun test` is natively fast and Jest-compatible, making TDD actually enjoyable.

## Mistakes That Cost Hours
- Assuming 100% Node.js API compatibility. Always verify edge-case native modules (like C++ addons or specific cryptography functions) actually work in Bun.
- Using `npm` and `bun` interchangeably in the same project, causing lockfile conflicts and confusing CI failures.
- Not utilizing Bun's built-in SQLite when building simple local tools, reaching for external databases prematurely.
