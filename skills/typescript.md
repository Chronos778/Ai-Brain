# TypeScript

Strict mode, every project, no exceptions.

## How I Use It
- `strict: true` always. Path aliases (`@/`) for all imports.
- `interface` for component props and extendable shapes. `type` for unions and utilities.
- Zod schemas as single source of truth — `type User = z.infer<typeof UserSchema>`.
- Types colocated with their modules, not in a giant `types/` folder.
- Let inference work. Don't annotate what TypeScript can figure out.

## Expert Decisions

**Types from runtime**: Zod at every boundary — API responses, form data, env vars. `JSON.parse()` returns `any` — always validate.

**Discriminated unions for state**: `{ status: 'idle' } | { status: 'loading' } | { status: 'success'; data: T } | { status: 'error'; error: Error }`. Switch on `status`, TypeScript narrows everything.

**Branded types**: `type UserId = string & { __brand: 'UserId' }` — prevents mixing user IDs with post IDs at compile time.

**Exhaustive switches**: `default: never` catches missing cases. When you add a union member, the compiler tells you every switch that needs updating.

**`satisfies` over `as`**: `const config = { ... } satisfies Config` validates the shape while preserving literal types. `as` lies to the compiler.

**Readonly by default**: `ReadonlyArray<T>`, `Readonly<T>` for data flowing down. Mutations should be explicit, not accidental.

**Result pattern**: `type Result<T, E = Error> = { ok: true; value: T } | { ok: false; error: E }` — typed error handling without exceptions.

## Mistakes That Cost Hours
- `any` instead of `unknown` — skips all checking, bugs surface at runtime
- `!` (non-null assertion) — crashes in production when the value IS null
- `enum` — use `as const` objects or union types, enums have weird runtime behavior
- `@ts-ignore` — use `@ts-expect-error` so it fails when the error is actually fixed
- Typing every intermediate variable — trust inference, annotate boundaries and exports
- `Function` or `Object` as types — meaningless, use specific signatures
- `as` for type casting when a type guard or narrowing would work
