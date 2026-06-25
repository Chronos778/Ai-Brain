---
name: go
description: Go patterns for concurrent API clients and networking
---

# Go

My language for high-concurrency network tools, API scrapers, and backend services.

## How I Build
- Standard `net/http` for API clients. Avoid heavy third-party HTTP wrappers.
- `context.Context` passed to every function that does network or disk I/O.
- Goroutines with `sync.WaitGroup` for parallel fetching.
- Struct tags for JSON unmarshaling. Use explicit types, avoid `map[string]interface{}`.
- Errors are values: `if err != nil`. No panics for control flow.

## Expert Decisions
- **Rate Limiting**: Always implement exponential backoff with jitter for third-party APIs (Qobuz, Amazon). Linear retries cause thundering herds.
- **Concurrency Control**: Use buffered channels as semaphores to limit concurrent goroutines (e.g., max 10 concurrent downloads), preventing connection exhaustion.
- **HTTP Client**: Never use the default `http.Client`. Always specify explicit `Timeout`.

## Mistakes That Cost Hours
- Starting goroutines without a context-aware cancellation mechanism, leading to orphan goroutines and memory leaks when the main request aborts.
- Forgetting to call `defer resp.Body.Close()`, leading to connection pool exhaustion.
- Shadowing `err` variables in nested scopes, hiding the actual error.
