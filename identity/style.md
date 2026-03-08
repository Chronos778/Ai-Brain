# Coding Style

## General
- Write clean, readable code
- Prefer descriptive variable/function names over abbreviations
- Keep functions small and focused — one function, one job
- Flat is better than nested — avoid deep nesting
- Early returns over deep if/else chains

## Naming
- **Variables/Functions**: camelCase (JS/TS), snake_case (Python), PascalCase (C#)
- **Components**: PascalCase
- **Files**: kebab-case for most files, PascalCase for components
- **Constants**: UPPER_SNAKE_CASE for true constants, camelCase for config values
- **Booleans**: prefix with is/has/should/can (e.g., `isLoading`, `hasAccess`)

## Formatting
- Use the language's standard formatter (Prettier for JS/TS, Black for Python, rustfmt for Rust)
- Consistent indentation (2 spaces for JS/TS/JSON, 4 spaces for Python)
- No trailing whitespace
- Single quotes in JS/TS, double quotes in Python

## Comments
- Don't comment obvious code
- Comment the WHY, not the WHAT
- Use TODO/FIXME/HACK markers for things that need attention
- JSDoc/docstrings for public APIs only, not for every internal function

## Error Handling
- Handle errors where they can be meaningfully handled
- Don't swallow errors silently
- Use typed errors when the language supports it
- Fail fast with clear error messages

## Git
- Commit messages: imperative mood, concise (e.g., "add auth flow", "fix rate limiter bug")
- Small, focused commits — one logical change per commit
- Branch names: feature/thing, fix/thing, refactor/thing

## Project Structure
- Group by feature/domain, not by file type
- Keep related files close together
- Index files for clean exports (JS/TS)
- Separate business logic from framework code

---

*This file grows over time. Update it as you discover more about your own style.*
