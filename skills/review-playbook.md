# Review Playbook

Use this checklist when reviewing code or proposing fixes.

## Severity Order
- Blockers: crashes, data loss, auth/security issues.
- High: behavior regressions, API contract breaks, race conditions.
- Medium: performance pitfalls, reliability gaps, weak error handling.
- Low: maintainability, clarity, naming, minor style concerns.

## Core Checks
- Confirm changed behavior matches requirement and edge cases.
- Check for breaking changes in public interfaces and schemas.
- Verify input validation, error paths, and fallback behavior.
- Validate async logic for race conditions and unhandled promises.
- Confirm logging is structured and actionable for failures.

## Security Checks
- AuthN/AuthZ paths are explicit and test-covered.
- No secret leakage in code, logs, or responses.
- Sensitive operations have server-side validation.

## Performance Checks
- Hot paths avoid unnecessary allocations/work.
- Expensive operations are memoized/cached where appropriate.
- Network/database calls avoid N+1 patterns.

## Testing Expectations
- Tests cover success path, failure path, and edge cases.
- Regression tests exist for bug fixes.
- Contract tests updated when API shape changes.

## Review Output Style
- Findings first, ordered by severity.
- Each finding includes file reference and concrete impact.
- Summaries stay brief; focus on actionable risk.
