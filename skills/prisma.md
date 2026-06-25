---
name: prisma
description: Prisma ORM patterns for Next.js and relational schema design
---

# Prisma

My ORM for Next.js full-stack applications.

## How I Build
- Single `PrismaClient` instance cached in `globalThis` during development to prevent connection limit exhaustion from hot reloading.
- Schema acts as the single source of truth for TypeScript types (via `prisma generate`).
- Use explicit foreign keys and relation fields in `schema.prisma`.
- Wrap multiple dependent writes in interactive transactions (`prisma.$transaction`).

## Expert Decisions
- **Client/Server Boundary**: Never pass raw Prisma objects to Client Components. Select only necessary fields or serialize explicitly to avoid sending sensitive data.
- **Data Access**: Abstract complex Prisma queries into service functions or repositories, keeping Next.js route handlers and Server Actions clean.
- **Migrations**: Always review generated SQL (`prisma migrate dev --create-only`) before applying, especially for destructive changes or index additions.

## Mistakes That Cost Hours
- Changing the schema and forgetting to run `prisma generate`, causing confusing TypeScript errors where types don't match the database.
- Selecting all fields (default behavior) when joining large relations, killing query performance and blowing up the payload size.
- Mixing `await` calls on Prisma without `$transaction`, leading to race conditions and partial inserts.
