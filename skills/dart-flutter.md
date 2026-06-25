---
name: dart-flutter
description: Flutter and Dart patterns for cross-platform mobile apps
---

# Dart / Flutter

My stack for cross-platform mobile applications.

## How I Build
- **Riverpod** for robust, compile-safe state management and dependency injection.
- **Hive** for fast, local NoSQL key-value storage (offline-first).
- **Supabase** or **Firebase** for backend-as-a-service.
- Widget composition over deep nesting: extract widgets to separate classes, not helper methods returning `Widget`.
- Strictly typed Dart: no `dynamic` unless absolutely necessary.

## Expert Decisions
- **State**: Keep business logic out of the UI. Riverpod `StateNotifier` or `AsyncNotifier` handles the logic, UI just watches the state.
- **Performance**: Use `const` constructors wherever possible to prevent unnecessary rebuilds.
- **Architecture**: Feature-first folder structure (e.g., `features/auth/`, `features/settings/`) rather than layer-first (`models/`, `views/`).

## Mistakes That Cost Hours
- Calling `ref.read` inside a `build` method instead of `ref.watch`, leading to UI not updating when state changes.
- Doing heavy synchronous work on the main isolate, causing UI stutter. Use `compute()` or `Isolate.run()` for heavy parsing or audio processing.
- Not handling loading and error states explicitly in async operations, leading to frozen UIs or silent failures.
