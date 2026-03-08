# Bun

Fast package management. Native TS/JSX. Use when Node compat isn't a concern.

## How I Use It
- `bun install` for speed — 10-100x faster than npm.
- `bunx` over `npx`. `bun.lockb` committed always.
- Native `.env` loading — no dotenv package needed.
- `bun test` for testing — Jest-compatible API, zero config.
- Fallback to npm when Bun has compatibility issues.

## When Bun vs npm
- **Bun**: Personal projects, fast iteration, new projects where full Node compat isn't required
- **npm**: Team projects, CI environments with limited Bun support, packages with known Bun issues
- **Never both**: One lockfile per project — `bun.lockb` OR `package-lock.json`

## Expert Decisions
- `Bun.serve()` is genuinely fast — matches Rust frameworks for simple HTTP
- `bun:sqlite` is built-in — no external package needed
- Native TypeScript execution — zero config, no transpile step
- Don't assume 100% Node compatibility — always check before depending on Node-specific internals
- Keep runtime-specific features isolated if the project might need to run on Node too
