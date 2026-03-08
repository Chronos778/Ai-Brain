# Node.js

ES modules everywhere. Async/await only. Never block the event loop.

## How I Build
- `"type": "module"` in every package.json. No CommonJS for new projects.
- `const` by default, `let` only for reassignment, never `var`.
- Async/await always — never `.then()` chains or callbacks.
- `path.join()` / `path.resolve()` for all file paths. `fs/promises` for file ops.
- dotenv or Bun's native `.env` for environment variables.
- Lock files committed. Always. `dev`, `build`, `lint`, `test` scripts in every project.

## Expert Decisions

**Event loop**: Never `readFileSync` or CPU-heavy work in request handlers. `worker_threads` for computation. Streams for file serving — `createReadStream` pipe to response.

**Async**: `Promise.all()` for independent operations — never sequential awaits. `AbortController` for cancellable fetches and queries. Global `unhandledRejection` handler — log and exit gracefully.

**Security**: `crypto.randomUUID()` for IDs (not `Math.random()`). Never `eval()` or `new Function()`. `execFile`/`spawn` with argument arrays, never `exec` with string interpolation. Validate all input with Zod.

**Config**: Parse all env vars through Zod at startup — fail fast on missing values. `.env.example` committed as template. Never default secrets — crash loudly if they're missing.

**Errors**: Custom error classes with status codes. Structured JSON logs (pino or winston). Handle `SIGTERM` — close connections, flush logs, then `process.exit(0)`. Health check endpoint that pings DB.

## Mistakes That Cost Hours
- `require()` in an ES module project — confusing error that doesn't say what you think
- Per-request database connections — pool exhaustion under load
- `console.log` in production — use structured, leveled logging
- `process.env.SECRET ?? 'fallback'` for secrets — silent failures in production
- Ignoring `unhandledRejection` — process crashes with no useful error context
- `var` anywhere — hoisting bugs, scope leaks
