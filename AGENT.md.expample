# AGENTS.md

## What this repo is

A Docker image (`steveltn/https-portal`) that automates HTTPS with Nginx + Let's Encrypt. Users configure domains via env vars; the container obtains/renews certificates and generates Nginx configs.

## Running tests

```bash
bundle install
bundle exec rspec
```

- Tests require Docker running locally.
- The suite builds the Docker image automatically before the first feature spec (cached on subsequent runs). To skip: `SKIP_BUILD=1 bundle exec rspec`.
- `TEST_DOMAIN` defaults to `test.nginx-acme.site`; override if you need a different test domain.
- Feature specs run in `:defined` order and may reuse containers across example groups—do not randomize order.

## Project structure

- `fs_overlay/` — Copied into the Docker image at `/`. This is where the real application code lives:
  - `fs_overlay/opt/certs_manager/` — Ruby code for certificate management and Nginx config generation.
  - `fs_overlay/var/lib/nginx-conf/` — ERB Nginx config templates.
  - `fs_overlay/etc/services.d/` — s6-overlay service definitions (nginx, docker-gen, crond, dynamic-env).
  - `fs_overlay/etc/cont-init.d/` — s6-overlay init scripts.
- `spec/` — RSpec tests.
  - `spec/compositions/` — Docker Compose files for integration tests.
  - `spec/models/domain_spec.rb` — Unit tests for domain descriptor parsing.
- `examples/` — Example Docker Compose setups for users.
- `Makefile` — Multi-arch Docker image builds (using `docker buildx`). Not needed for local development or testing.

## Key conventions

- Domain descriptors are parsed from `DOMAINS` env var (comma-separated). Format supports upstreams (`->`), redirects (`=>`), basic auth, access restrictions, per-domain stages, and custom ports. See `spec/models/domain_spec.rb` for the canonical parsing behavior.
- Nginx configs are ERB templates rendered at runtime. Custom per-domain or global configs can be injected via env vars (`CUSTOM_NGINX_*_CONFIG_BLOCK`) or by mounting `.conf.erb` files.
- The container uses s6-overlay for process supervision. Entrypoint is `/init`.

## Local testing workflow

1. Make changes to `fs_overlay/` code or templates.
2. Run `bundle exec rspec` (or `SKIP_BUILD=1` if the image is already built).
3. For manual Docker testing, use one of the `examples/` or `spec/compositions/` docker-compose files.

## No CI / no lint / no typecheck

This repo has no GitHub Actions, no linting scripts, and no type checker. Verification is via RSpec only.
