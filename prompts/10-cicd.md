# Audit 10: CI/CD

> **Read [`_conventions.md`](./_conventions.md) first** — shared target-repo
> assumptions, severity scale, 0–5 maturity score, amateur/AI-built signal, and
> report template

## Role

You are auditing the build/test/deploy pipeline. Vibe-coded projects are typically
deployed by dragging a folder to a host or running a command on a laptop — no
pipeline, no gates, no repeatability.

## Objective

Read-only investigation of CI/CD. Write your report to `audit/cicd.md` using the
template in `_conventions.md`.

## Investigate

1. **CI exists?** Any pipeline config (GitHub Actions, GitLab CI, CircleCI,
   Jenkins, Azure Pipelines, Bitbucket)? What triggers it?
2. **Quality gates.** Does CI run install → lint → typecheck → tests → build →
   security scan? Which stages are present, and are failures blocking?
3. **Reproducible build.** Does the build run cleanly from scratch in CI (clean
   environment), or does it rely on local state?
4. **Deployment.** Is deploy automated and repeatable, or manual/click-ops? Is
   there environment promotion (dev → staging → prod), or deploy-straight-to-prod?
5. **Rollback.** Is there any rollback/revert strategy, or is the only recovery
   "fix forward under pressure"?
6. **Secrets in CI.** Are pipeline secrets injected securely, or hardcoded in the
   workflow file?
7. **Artefact handling.** Are build artefacts versioned/stored, or rebuilt ad hoc?

## Amateur / AI-built red flags

- No CI/CD configuration at all.
- A CI file that only echoes "hello" or was scaffolded and never wired to real steps.
- Manual deploy steps in the README ("run these 12 commands on the server").
- Secrets pasted directly into the workflow YAML.
- Deploy straight to prod with no staging and no rollback.

## Scoring anchors

- **0–1:** No CI/CD; builds and deploys are manual and non-reproducible.
- **2–3:** CI runs tests/build on push, but deploy is manual or lacks gates/rollback.
- **4–5:** Full pipeline with quality gates, environment promotion, secure secrets,
  automated deploy, and rollback.
