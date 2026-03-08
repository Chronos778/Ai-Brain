# Code Style

These aren't rules for the sake of rules — they're what I've settled on after building across multiple stacks.

## Naming
- camelCase (JS/TS), snake_case (Python), PascalCase (C#/components)
- Booleans: `is`, `has`, `should`, `can` — `isLoading`, `hasAccess`
- Files: kebab-case. Components: PascalCase.
- Constants: UPPER_SNAKE_CASE only for true constants, camelCase for config

## Formatting
- Prettier (JS/TS), Black (Python), rustfmt (Rust) — the ecosystem standard
- 2 spaces JS/TS, 4 spaces Python. Single quotes JS. Double quotes Python.

## Structure
- Group by feature, not file type. Keep related files close.
- Index files for clean exports in JS/TS.
- Separate business logic from framework code.
- Flat over nested — early returns over deep if/else.
- One function, one job. If it needs a comment explaining what it does, it's doing too much.

## Git
- Imperative commit messages: `add auth flow`, `fix rate limiter bug`
- Small, focused commits — one logical change each
- Branches: `feature/`, `fix/`, `refactor/`

## The Line I Care About
Comment the WHY, never the WHAT. If the code isn't clear, rewrite it — don't comment it.
