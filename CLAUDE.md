# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repository is

A **library of audit prompts** (Markdown only — no application code, no build
system, no tests). The prompts are fed to Claude Code or Codex to audit a *target*
repository for the failure modes typical of software built by a non-technical
person or beginner driving an AI assistant ("vibe-coded" projects). Each prompt
investigates one best-practice topic, writes an evidence-backed report to
`audit/<topic>.md` **in the target repo**, and assigns a 0–5 maturity score plus an
amateur/AI-built signal rating.

There is nothing to build, lint, or test here. "Running" a prompt means pointing an
agent at a target repo and giving it a prompt file (e.g. `prompts/00-orchestrator.md`
for the whole suite, or a single `prompts/NN-*.md` for one topic). The prompts are
**read-only investigations**: they instruct the agent to write only under `audit/`
and never modify the target's code.

## Running the whole suite: `run-audit.sh` / `run-audit.ps1`

The driver script (repo root) is the reliable way to run all 27 topics. Its reason
for existing is a completeness guarantee a single agent session cannot give: one
agent doing all 27 heavy prompts exhausts its context and silently skips topics.
The driver instead runs **one fresh agent process per prompt** and treats a topic
as done **only when `audit/<slug>.md` exists and contains a `**Score:**` line**
(N/A verdicts still write a file). It exits non-zero listing any missing report,
and is resumable (re-runs skip already-valid reports).

**Two platform versions, kept at behavioural parity** — `run-audit.sh` (bash, for
Linux and macOS; written to run under macOS's bash 3.2, invoked via its shebang so
it works under a zsh login shell) and `run-audit.ps1` (PowerShell 5.1+ / 7, for
Windows). A change to one's behaviour (new flag, validity rule, agent invocation)
must be mirrored in the other. Both compose each prompt as: a driver preamble +
`_conventions.md` + the topic prompt, piped to the CLI on stdin, so each process is
hermetic (no inter-file reads). Note for the `.ps1`: `$OutputEncoding` is forced to
UTF-8 because Windows PowerShell 5.1 otherwise pipes stdin as ASCII and would
mangle the em-dashes/arrows in the prompts.

Key invariants the script depends on — preserve them when editing prompts:

- The prompt→output mapping is deterministic: `prompts/NN-<slug>.md` writes
  `audit/<slug>.md`. Keep each prompt's `## Objective` output path equal to its
  filename slug, or the driver's validity check breaks.
- Every report carries a `**Score:**` line (defined in `_conventions.md`'s report
  template). That string is the driver's "valid report" signal — don't rename it.
- Even `N/A` topics must still write their report file.
- The single per-run edit point for CLI flags is the `run_agent()` function; the
  orchestrator's aggregation step reuses `00-orchestrator.md`. Adding/removing a
  prompt is picked up automatically (the driver globs `prompts/[0-9][0-9]-*.md`),
  but still update the README table and orchestrator groups per the rules below.

## Layout

- `prompts/_conventions.md` — the shared spec. **Single source of truth** for the
  target-repo assumptions, severity scale (Critical→Info), the 0–5 maturity rubric,
  the amateur/AI-built signal rating, and the exact `audit/<topic>.md` report
  template. Every topic prompt references it.
- `prompts/00-orchestrator.md` — scopes the target, runs every applicable topic
  prompt, and aggregates results into `audit/SCORECARD.md` with an overall verdict.
- `prompts/NN-*.md` — 27 topic prompts (`01`–`27`). 01–25 cover per-topic best
  practices; 26 (raw-cloud IaaS) and 27 (application-delivery platforms) audit the
  hosting platform and are routed by the orchestrator's scoping step based on where
  the target is deployed.
- `README.md` (repo root) — topic index table and how-to-run. Its links point into
  `./prompts/`; keep them in sync when adding, removing, or renumbering a prompt.
- `temp/` — gitignored scratch space for analysis/planning docs (e.g. gap
  analyses). Not part of the published suite.
- `BACKLOG.md` — durable record of deferred/implemented enhancements. Consult
  before proposing "new" topics so effort isn't re-derived.
- `check-suite.sh` / `check-suite.ps1` — self-consistency checker (parity pair,
  like the driver). Run after any prompt add/remove/renumber/edit; it enforces the
  invariants below (numbering, README + orchestrator coverage, link resolution,
  section shape, slug→output mapping) and exits non-zero on any violation. Treat a
  green run as the definition of "the suite is wired correctly".

## Conventions to preserve when editing

The suite's value depends on consistency. Keep these invariants:

- **Don't redefine shared rubric per file.** Severity scale, scoring, signal
  rating, and the report template live only in `_conventions.md`. Topic prompts
  reference it; they must not fork their own copies.
- **Every topic prompt follows the same shape**, in this order: a header block
  referencing `_conventions.md` (only — do not reintroduce the older per-prompt
  maverick-skill references that were deliberately removed) → `## Role` →
  `## Objective` (states the `audit/<topic>.md` output path) → `## Investigate`
  (numbered checklist) → `## Amateur / AI-built red flags` → `## Scoring anchors`
  (0–1 / 2–3 / 4–5 bands). Match this when adding or editing a prompt.
- **Numbering is contiguous and load-bearing.** `NN` prefixes double as ordering
  and as IDs cross-referenced between prompts (e.g. "Cross-reference 14 security").
  If you add, remove, or renumber a prompt, update in the same change: the
  `README.md` topic table, the topic groupings/list in `00-orchestrator.md`, and
  any inter-prompt "see NN" references.
- **Topics that may not apply** (accessibility, api-design, database-management,
  observability, alerting, infrastructure, HA, versioning, and the two
  hosting-platform prompts 26/27) instruct the agent to mark themselves `N/A` with
  justification rather than score 0. Preserve that when editing those files. Note
  26 and 27 are mutually exclusive per target (IaaS vs app-delivery platform), or
  both apply to a hybrid deployment.