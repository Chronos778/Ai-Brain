---
name: express
description: Express.js layered architecture with Zod validation and centralized error handling
---
# Express

Layered architecture. Thin routes, fat services. Consistent error format.

## How I Build
- Route -> Controller -> Service -> DB. Each layer has one job.
- Middleware composition per route: `[auth, validate(schema), rateLimit]`.
- Zod for all request validation — body, params, query.
- Consistent error response: `{ error: { message, code, status } }`.
- Centralized error handler: `(err, req, res, next)` at the end.
- Helmet + CORS whitelist + rate limiting on all public endpoints.
- Libraries: express, cors, helmet, express-rate-limit, zod, @libsql/client, dotenv.

## Expert Decisions

**Middleware order**: Security (helmet) -> CORS -> body parsing -> auth -> rate limit -> routes -> error handler. Order matters — get it wrong and auth runs before CORS rejects.

**Validation**: Validate at the boundary. Zod schema for every POST/PUT body. `z.coerce.number()` for query params. Never trust `req.body` without parsing it through a schema first.

**Error handling**: Custom classes — `BadRequestError`, `NotFoundError`, `UnauthorizedError`. Single centralized handler. Never expose stack traces in production. Log error + request context + user ID server-side.

**Security**: CORS with explicit origins in production. Rate limiting tiers — stricter on auth endpoints. JWT: verify signature + expiration + issuer. HTTPS only.

**Architecture**: Services are framework-agnostic — no `req`/`res` in business logic. Feature-based folders: `users/controller.ts`, `users/service.ts`, `users/routes.ts`.

**Performance**: Compression middleware. `Cache-Control` headers on GET responses. Always paginate list endpoints. Return only needed fields — don't send entire DB rows.

## Mistakes That Cost Hours
- Business logic in route handlers — untestable, can't reuse across routes
- Forgetting `return` before `res.json()` — handler continues, sends headers twice
- `res.send()` after `res.json()` — "headers already sent" crash
- Forgetting `next()` in middleware — request hangs forever
- `*` CORS in production — any origin can hit your API
- Synchronous file operations in handlers — blocks the event loop for all requests
