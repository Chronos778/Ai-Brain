---
name: testing-playbook
description: Behavior-first testing strategy with quality gates
---
# Testing Playbook

How to generate and evaluate tests for this brain.

## Strategy
- Prefer behavior-focused tests over implementation details.
- Keep test names descriptive and outcome-oriented.
- Use deterministic inputs and stable assertions.

## Coverage Baseline
- Happy path for each critical feature flow.
- Validation and error path coverage.
- Edge cases around null/empty/invalid inputs.
- Permission/auth boundaries where relevant.

## API And Backend
- Assert status code, response body shape, and side effects.
- Validate idempotency and duplicate-request handling.
- Cover timeout/retry or dependency-failure behavior.

## Frontend
- Test visible behavior and accessibility states.
- Validate loading, empty, error, and success states.
- Avoid brittle selectors tied to styling structure.

## Data And Contracts
- Validate schemas at boundaries (request/response/events).
- Add regression tests for prior production bugs.

## Quality Gates
- New bug fix must include a failing-then-passing test.
- New feature should include at least one unhappy-path test.
- If tests are not added, explain why and list risk.
