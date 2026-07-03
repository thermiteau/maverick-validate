# Audit 06: Dependency Management

> **Read [`_conventions.md`](./_conventions.md) first** — shared target-repo
> assumptions, severity scale, 0–5 maturity score, amateur/AI-built signal, and
> report template

## Role

You are auditing the software supply chain. Vibe-coded repos accumulate
dependencies the AI suggested — some hallucinated, some abandoned, some
vulnerable — usually with no lockfile and no scanning.

## Objective

Read-only investigation of dependency health. Write your report to
`audit/dependency-management.md` using the template in `_conventions.md`.

## Investigate

1. **Lockfile present and committed.** Is there a lockfile (`package-lock.json`,
   `yarn.lock`, `pnpm-lock.yaml`, `poetry.lock`, `Pipfile.lock`, `go.sum`,
   `Cargo.lock`) committed and in sync with the manifest? Without it, builds are
   non-reproducible.
2. **Version pinning strategy.** Are versions pinned/ranged sensibly, or is
   everything `*`/`latest`/unbounded? Any dependency on a git URL or a specific
   commit?
3. **Vulnerability scan.** Run the ecosystem auditor if available
   (`npm audit`, `pip-audit`, `osv-scanner`, `yarn audit`, `govulncheck`). Report
   Critical/High counts. Is any automated scanning (Dependabot/Snyk/Renovate)
   configured?
4. **Hallucinated / suspicious packages.** Look for dependencies that don't seem to
   exist, are typosquats, or are wildly unpopular/unmaintained — a known AI failure
   mode ("slopsquatting"). Verify each non-obvious dependency is real and used.
5. **Unused & duplicate deps.** Are listed dependencies actually imported? Multiple
   libraries doing the same job? Bloated dependency trees for a small app?
6. **Abandonment & freshness.** Are key dependencies years out of date,
   deprecated, or unmaintained? Any depending on EOL runtimes?
7. **License compliance.** Any copyleft (GPL/AGPL) or unlicensed dependencies that
   conflict with the project's intent?

## Amateur / AI-built red flags

- No lockfile committed.
- Everything on `latest`/`*`; no reproducibility.
- Dependencies that don't resolve, or obscure typosquat-looking names.
- Huge dependency list for a tiny app; many unused entries.
- `npm audit`/`pip-audit` reporting known Critical/High vulns, unaddressed.
- No automated dependency updates or scanning.

## Scoring anchors

- **0–1:** No lockfile, unpinned versions, unresolved/suspicious packages,
  unaddressed known vulnerabilities.
- **2–3:** Lockfile present and versions pinned, but no scanning/automation and
  some stale or vulnerable dependencies.
- **4–5:** Committed lockfile, sane pinning, automated scanning + updates, clean
  audit, no unused deps, license-aware.
