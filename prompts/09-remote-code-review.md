# Audit 09: Remote / Automated Code Review

> **Read [`_conventions.md`](./_conventions.md) first** — shared target-repo
> assumptions, severity scale, 0–5 maturity score, amateur/AI-built signal, and
> report template

## Role

You are checking whether an automated reviewer runs on every pull request in CI —
the safety net that catches what a solo author (or the AI that wrote the code)
will not catch reviewing their own work.

## Objective

Read-only investigation of automated PR review in CI. Write your report to
`audit/remote-code-review.md` using the template in `_conventions.md`.

## Investigate

1. **CI-triggered review workflow.** Is there a workflow (`.github/workflows`,
   `.gitlab-ci.yml`, Azure/Bitbucket pipelines) that runs an automated reviewer or
   quality/security bot on PR `opened`/`synchronize`/`reopened`?
2. **What it actually checks.** Does it run meaningful analysis (static analysis,
   security scan, AI review, tests) as a required gate — or is it a rubber-stamp?
3. **Blocking vs. advisory.** Are findings a required status check that blocks
   merge, or informational only?
4. **Coverage of the safety net.** Combined with 07 (lint), 10 (CI), 11–12 (tests),
   14 (security): is there *any* automated gate between a bad change and `main`?

## Amateur / AI-built red flags

- No CI at all, so no automated review is even possible.
- A workflow that exists but runs nothing meaningful, or never blocks merge.
- Self-hosted author bypasses all checks by pushing to `main`.

## Scoring anchors

- **0–1:** No automated review; nothing inspects changes before they land.
- **2–3:** Some automated checks run on PRs but are advisory or shallow.
- **4–5:** Required, blocking automated review (analysis/security/tests) on every PR.
