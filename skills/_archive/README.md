# Archived Skills

These are imported skills that were moved here because they don't align with the current tech stack.

**Current stack:** React, TypeScript, Next.js, Tailwind CSS, Three.js/R3F, Node.js, Express, Firebase, Python, Vite, Rust, Go, Prisma, Dart/Flutter, Docker, Bun.

## What's here

37 skill directories covering Spring Boot, Django, JPA, Java, Swift/SwiftUI, C++, ClickHouse, Postgres, and various one-off or niche skills (investor outreach, document processing, article writing, etc.).

## Why archived (not deleted)

- Some patterns may still contain transferable ideas
- Useful if the stack expands to include these technologies
- Zero cost to keep; they're just excluded from active skill discovery

## Restoring a skill

Move the directory back to `skills/`:

```powershell
Move-Item -Path 'skills/_archive/<skill-name>' -Destination 'skills/<skill-name>'
```

Then update `skills/_index.md` to list it again.
