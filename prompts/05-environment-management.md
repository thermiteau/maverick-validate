# Audit 05: Environment Management

> **Read [`_conventions.md`](./_conventions.md) first** — shared target-repo
> assumptions, severity scale, 0–5 maturity score, amateur/AI-built signal, and
> report template

## Role

You are assessing whether this project can be set up and run reproducibly by
someone other than the author. Vibe-coded repos are famous for "works on my
machine": hardcoded paths, undocumented global installs, and no environment parity.

## Objective

Read-only investigation of environment reproducibility. Write your report to
`audit/environment-management.md` using the template in `_conventions.md`.

## Investigate

1. **Reproducible setup.** Is there a documented, deterministic path from clone to
   running (Makefile, scripts, `docker-compose`, devcontainer, task runner)? Or a
   list of manual steps that assume prior global state?
2. **Runtime version pinning.** Is the language/runtime version pinned
   (`.nvmrc`, `.python-version`, `engines`, `go.mod`, `.tool-versions`)? Or does
   it depend on "whatever's installed"?
3. **Config via environment.** Are secrets and config read from environment
   variables (12-factor), or hardcoded? Is there a `.env.example` listing required
   variables without values?
4. **Hardcoded machine specifics.** Grep for absolute paths (`/Users/`,
   `/home/<name>/`, `C:\Users\`), hardcoded `localhost`/ports assumptions,
   personal API keys, or machine-specific config baked into source.
5. **Environment parity.** Is there any notion of dev vs. staging vs. prod, or is
   there exactly one environment (the laptop)? Do configs differ safely per env?
6. **Containerisation / onboarding.** Is there a `Dockerfile`/compose or
   devcontainer that captures the environment? How long would onboarding take from
   the docs alone?

## Amateur / AI-built red flags

- Absolute paths tied to the author's home directory in source or config.
- No runtime version pin; the app breaks on a different Node/Python version.
- Secrets/config hardcoded instead of injected from the environment.
- No `.env.example`; required variables discoverable only by crashing.
- Single environment with prod values hardcoded for local dev.

## Scoring anchors

- **0–1:** Only runs on the author's machine; hardcoded paths/keys, no version pin.
- **2–3:** Documented manual setup, some env-var config, but no containerisation
  or parity between environments.
- **4–5:** One-command reproducible setup, pinned runtime, `.env.example`,
  container/devcontainer, clear dev/staging/prod parity.
