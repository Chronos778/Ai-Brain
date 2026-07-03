# Learnings

Things I've figured out that are worth remembering. Not documentation - insights.
Each entry should save future-me at least 30 minutes.

---

### 2026-06-12 | foodbook/recipe-book [frontend-design]
Editorial CSS frameworks need CSS custom properties for theme switching on the root element, not class toggling on individual components.

### 2026-06-16 | puff [python, node-js]
Multi-provider TTS needs state-based quota tracking per provider. ElevenLabs quota exhaustion is silent (no header) — needs explicit remaining-character tracking based on the text length sent.

### 2026-06-16 | puff [python]
Dynamic captions with hard cuts need frame-accurate timestamps. Audio timestamps drift from video frames over time, causing text overlaps during scene transitions.

### 2026-06-16 | puff [python]
FFmpeg input index handling differs for audio vs SFX in vertical rendering. You have to map the exact audio streams via `-map 0:a` explicitly if combining multiple inputs, otherwise it defaults to just the first one.

### 2026-06-17 | SpotiFLAC [go]
Qobuz API needs exponential backoff with jitter, not linear retries. Linear retries create thundering herd problems that lead to immediate secondary rate limits.

### 2026-06-17 | SpotiFLAC [go]
Go API retry logic needs context-aware cancellation. If the parent request drops, orphan goroutines pile up and exhaust connection pools.

### 2026-06-18 | quote.web [node-js, frontend-design]
Service worker cache versioning must bump on theme changes or users see stale CSS styles even when localStorage updates correctly.

### 2026-06-20 | git-rewind [rust]
SHA256 checksum verification needs file handles flushed and unlocked first, or you'll get access denied or partial reads on Windows.

### 2026-06-24 | orelli [next-js, typescript]
Category gallery array parsing must include the main image explicitly; assuming the grid will naturally pull it leads to broken layouts in the masonry view.

### 2026-06-25 | git-rewind [rust]
resolve broken sha256 checksum URLs in installation scripts

### 2026-06-25 | git-rewind [rust]
flush and unlock file handles before sha256 checksum verification

### 2026-06-25 | SpotiFLAC [go]
add retry logic for Qobuz and Amazon APIs and resolve Qobuz search fallback issues

### 2026-06-25 | SpotiFLAC [go]
implement retry and backoff for Qobuz and Amazon APIs to fix #948

### 2026-06-28 | foodbook/recipe-book
use dedicated fridge-panel class instead of modal-box to prevent style conflicts

### 2026-06-28 | foodbook/recipe-book
bump SW cache version to bust stale cache

### 2026-06-30 | git-rewind [rust]
improve error message formatting for invalid or expired API keys

### 2026-07-01 | git-rewind [rust]
remove unused api_key variable

### 2026-07-03 | git-rewind [rust]
resolve Anthropic edge cases (400 cache fallback & non-streaming token usage)

### 2026-07-03 | git-rewind [rust]
resolve syntax error in client.rs
