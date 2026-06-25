---
name: docker
description: Docker containerization patterns for predictable deployments
---

# Docker

My standard for isolating and deploying backend services.

## How I Build
- Multi-stage builds: build environment (with compilers/dev-dependencies) -> lean runtime image (Alpine or Distroless).
- `docker-compose.yml` for local orchestration (app + db + cache).
- Use `.dockerignore` aggressively to keep build context small (ignore `node_modules`, `.git`, local env files).
- Explicit tags for base images (`node:20-alpine`, not `node:latest`).

## Expert Decisions
- **Security**: Never run as `root`. Create a dedicated user in the Dockerfile and `USER nonroot`.
- **Caching**: Order Dockerfile commands from least frequently changed (OS dependencies) to most frequently changed (source code) to maximize layer caching.
- **Environment**: Keep images environment-agnostic. Inject config via environment variables at runtime, not build time.

## Mistakes That Cost Hours
- Copying `package.json` and source code in a single step, busting the `npm install` cache on every code change.
- Storing state (databases, uploads) inside the container filesystem instead of a mounted volume, losing data on restart.
- Forgetting to expose the correct port or binding to `127.0.0.1` instead of `0.0.0.1` inside the container.
