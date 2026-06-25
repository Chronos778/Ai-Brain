---
name: rust
description: Rust for fast, safe CLI tools and file manipulation
---

# Rust

My systems language of choice. Used for memory-safe CLIs, heavy file I/O, and cryptographic operations.

## How I Build
- `clap` for CLI argument parsing (derive feature preferred).
- `tokio` for async if making network calls, but stick to standard `std::thread` for purely local CPU/file bound CLIs.
- `serde` and `serde_json` for configuration parsing.
- Return `Result<T, Box<dyn std::error::Error>>` at the top level, specific custom errors internally.
- `reqwest` for HTTP clients if updating/downloading.
- Extensive use of `.expect()` only during initialization where failure is fatal, `match` or `?` everywhere else.

## Expert Decisions
- **File I/O**: Use buffered readers/writers (`BufReader`/`BufWriter`) for large files, especially when hashing (SHA256).
- **Concurrency**: Use `rayon` for data parallelism over `tokio` if the task is CPU-bound (e.g., checksumming multiple files).
- **Updates**: Cryptographic self-updating binaries need file handles to be explicitly closed and flushed before the new binary replaces the old one (especially on Windows).

## Mistakes That Cost Hours
- Forgetting to flush and unlock file handles before trying to verify or replace a file on Windows.
- Overusing async (`tokio`) for simple file parsing tools. It bloats the binary and complicates the mental model.
- Using `unwrap()` deep in the logic. It will panic in production. Always propagate with `?`.
