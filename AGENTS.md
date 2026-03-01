# AGENTS.md — portainer-stacks

This file provides context for AI agents working in this repository.

## Project Overview

**portainer-stacks** is a Docker service configuration repository for a home-lab managed by [Portainer](https://portainer.io). Each service is defined as an individual YAML file under `services/`, and a Makefile build system composes them into one or more `docker-compose*.yml` files that Portainer picks up automatically.

There are two deployment targets:
- **default** — local home server (NAS/Synology-like setup), most services
- **ridge** — remote GPU server running AI services (ComfyUI, Ollama, OpenWebUI)

## Repository Structure

```
portainer-stacks/
├── services/
│   ├── ai/          # AI/ML services — ridge target only
│   ├── lab/         # Infrastructure services
│   ├── media/       # Media stack
│   ├── misc/        # One-off utilities
│   └── pro/         # Production services
├── docker-compose.yml          # Auto-generated — do not edit manually
├── docker-compose-ridge.yml    # Auto-generated — do not edit manually
├── Makefile                    # `make build` regenerates compose files; `make validate` checks them
├── .env                        # Environment variables (gitignored)
└── README.md
```

## Key Conventions

### Adding a New Service
1. Create `services/<category>/<name>.yml` with a single Docker Compose service definition.
2. Run `make build` to regenerate the compose files.
3. Run `make validate` to confirm correctness.
4. Commit and push — Portainer auto-deploys.

### Targeting a Specific Environment
Add a top-level `x-target: ridge` field to the service YAML to route it into `docker-compose-ridge.yml` instead of the default `docker-compose.yml`.

```yaml
x-target: ridge

services:
  myservice:
    ...
```

### Disabling a Service
Rename the file to `<name>.yml.disabled`. The Makefile only processes `*.yml` files, so the service is excluded from all generated compose files without being deleted.

### Environment Variables
All services pull variables from `.env`. Common variables:
- `CONFIG_ROOT` — host path for service config directories (local)
- `CONFIG_ROOT_RIDGE` — host path for service config directories (ridge)
- `MEDIA_ROOT` — host path for media library
- `DOWNLOADS` — host path for download directory
- `PUID` / `PGID` — UID/GID for container processes
- `TZ` — timezone (`Europe/Paris`)
- `HOST_IP` — host IP for services that need it

Service-specific variables (e.g. `BROWSERLESS_TOKEN`, `UMAMI_APP_SECRET`) are also in `.env`.

### Standard Container Patterns
Most services follow these conventions:
- `restart: unless-stopped` (or `always` for critical services)
- `environment: PUID/PGID/TZ` set from `.env`
- Config volume: `$CONFIG_ROOT/<service>/:/config`
- `depends_on:` with `condition: service_healthy` when a dependency has a healthcheck

## Build System

```bash
make build      # Regenerate docker-compose*.yml from services/**/*.yml
make validate   # Run build, then validate all compose files with docker-compose config -q
```

The Makefile scans all `*.yml` files under `services/`, reads any `x-target:` field, and groups files accordingly. Never edit `docker-compose.yml` or `docker-compose-ridge.yml` directly — they are overwritten on every `make build`.

## Agent Guidance

### When modifying or adding a service
- Read the existing service YAML in the same category for style/pattern reference before creating a new one.
- Keep service files minimal — one `services:` block per file.
- Prefer `unless-stopped` restart policy unless the service is infrastructure-critical.
- Use `$CONFIG_ROOT` (not hardcoded paths) for volume mounts on local services; use `$CONFIG_ROOT_RIDGE` for ridge-target services.
- Always run `make validate` after changes to catch YAML or compose errors before committing.

### When asked to add a new variable
- Add it to `.env` with a descriptive comment grouping it with related vars.
- Reference it in the service YAML as `$VAR_NAME`.

### When disabling/removing a service
- Disable: rename to `.yml.disabled`.
- Remove: delete the file and run `make build` to drop it from generated files.

### Do not
- Edit `docker-compose.yml` or `docker-compose-ridge.yml` directly.
- Commit `.env` (it is gitignored).
- Add a service without running `make validate` to confirm the compose output is valid.
- Hardcode host paths — always use `.env` variables.
