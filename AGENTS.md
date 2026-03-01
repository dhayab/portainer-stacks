# AGENTS.md — portainer-stacks

This file provides context for AI agents working in this repository.

## Project Overview

**portainer-stacks** is a Docker service configuration repository for a home-lab managed by [Portainer](https://portainer.io). Each service is defined as an individual YAML file under `services/`, and a Makefile build system composes them into one or more `docker-compose*.yml` files that Portainer picks up automatically.

There are three deployment targets:
- **default** (`docker-compose.yml`) — critical infrastructure only
- **apeach** (`docker-compose-apeach.yml`) — all regular local services
- **ridge** (`docker-compose-ridge.yml`) — remote GPU server running AI services

## Repository Structure

```
portainer-stacks/
├── services/
│   ├── ai/          # AI/ML services
│   ├── lab/         # Infrastructure services
│   ├── media/       # Media stack
│   ├── misc/        # One-off utilities
│   └── pro/         # Production services
├── docker-compose.yml          # Auto-generated — do not edit manually
├── docker-compose-apeach.yml   # Auto-generated — do not edit manually
├── docker-compose-ridge.yml    # Auto-generated — do not edit manually
├── Makefile                    # `make build` regenerates compose files; `make validate` checks them
├── .env                        # Environment variables (gitignored)
└── README.md
```

## Key Conventions

### Adding a New Service
1. Create `services/<category>/<name>.yml` with a single Docker Compose service definition.
2. Run `make validate` to confirm correctness.
3. Commit and push — Portainer auto-deploys.

### Targeting a Specific Environment
Set `x-target: <target>` **inside the first service block** of the file. The Makefile scans for this field at any indentation level. Do not place it at the top level.

```yaml
services:
  myservice:
    x-target: apeach
    container_name: media-myservice
    ...
```

**Important for multi-service files** (e.g. a service + its database): only put `x-target` in the **first** service block. The Makefile finds all occurrences — if it appears multiple times in one file, the file gets included multiple times in the generated compose, which is invalid.

Most new local services should use `x-target: apeach`. Only add to the default stack (no `x-target`) if the service is critical infrastructure that must never be disrupted by other stack updates.

### Container Naming
Convention: `<category>-<servicename>`. Examples: `media-sonarr`, `lab-pomerium`, `misc-instafix`.

### Disabling a Service
Rename the file to `<name>.yml.disabled`. The Makefile only processes `*.yml` files, so the service is excluded from all generated compose files without being deleted.

### Environment Variables
All services pull variables from `.env`. Common variables:
- `CONFIG_ROOT` — host path for service config directories (local/apeach)
- `CONFIG_ROOT_RIDGE` — host path for service config directories (ridge)
- `MEDIA_ROOT` — host path for media library
- `DOWNLOADS` — host path for download directory
- `PUID` / `PGID` — UID/GID for container processes
- `TZ` — timezone (`Europe/Paris`)
- `HOST_IP` — host IP for services that need it

Service-specific variables are also in `.env`.

### Standard Container Patterns
Most services follow these conventions:
- `restart: unless-stopped` (or `always` for critical services like bastion)
- `environment: PUID/PGID/TZ` set from `.env`
- Config volume: `$CONFIG_ROOT/<service>/:/config`
- `depends_on:` with `condition: service_healthy` when a dependency has a healthcheck
- `init: true` for images that run as non-root and don't handle PID 1 themselves

## Build System

```bash
make build      # Regenerate docker-compose*.yml from services/**/*.yml
make validate   # Run build, then validate all compose files with docker-compose config -q
```

The Makefile scans all `*.yml` files under `services/`, reads any `x-target:` field, and groups files accordingly. Never edit `docker-compose*.yml` files directly — they are overwritten on every `make build`.

## Agent Guidance

### When modifying or adding a service
- Read an existing service YAML in the same category for style/pattern reference before creating a new one.
- Keep service files minimal — one `services:` block per file.
- Default new local services to `x-target: apeach` inside the first service block.
- Only omit `x-target` (default stack) for services that are critical gateway/infrastructure.
- Use `$CONFIG_ROOT` (not hardcoded paths) for volume mounts on local/apeach services; use `$CONFIG_ROOT_RIDGE` for ridge-target services.
- Always run `make validate` after changes to catch YAML or compose errors before committing.

### When asked to add a new variable
- Add it to `.env` with a descriptive comment grouping it with related vars.
- Reference it in the service YAML as `$VAR_NAME`.

### When disabling/removing a service
- Disable: rename to `.yml.disabled`.
- Remove: delete the file and run `make build` to drop it from generated files.

### Do not
- Edit any `docker-compose*.yml` file directly.
- Commit `.env` (it is gitignored).
- Add a service without running `make validate` to confirm the compose output is valid.
- Hardcode host paths — always use `.env` variables.
- Place `x-target` at the top level of a service file (put it inside the first service block).
- Place `x-target` in more than one service block per file (causes duplicate includes).
