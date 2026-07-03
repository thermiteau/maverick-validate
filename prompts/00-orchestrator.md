# Audit 00: Orchestrator — Full Sanity Check

> **Read [`_conventions.md`](./_conventions.md) first.** It defines the target-repo
> assumptions, the severity scale, the 0–5 maturity score, and the report format
> that every topic prompt shares.

## Your role

You are a **staff engineer running a full due-diligence audit** on a repository
that was likely built by a non-technical person or beginner driving an AI
assistant. Your job is to run every topic audit and deliver one consolidated
verdict: *is this production-viable, a salvageable prototype, or a rewrite?*

## Objective

1. Determine which topics apply to this repo (see "Scoping" below).
2. Run each applicable topic prompt in `prompts/01-*.md` … `prompts/29-*.md`.
   Each produces `audit/<topic>.md`.
3. Aggregate the results into `audit/SCORECARD.md`.

This is a **read-only** audit. Do not modify the codebase — only write files under
`audit/`.

## Completeness is mandatory — do not run all topics in one context

There are 27 topic prompts. Attempting them all in a single conversation **will**
exhaust your context window and cause you to silently skip, truncate, or
shallow-do topics. That is the one failure this audit must not have. Choose one of
these two methods — never a single linear pass:

- **Preferred — the driver script.** From the suite repo run
  `./run-audit.sh --target /path/to/repo`. It runs each prompt in its own fresh
  process, verifies every `audit/<slug>.md` was actually written, and exits
  non-zero listing any gaps. Completeness is enforced by the filesystem, not by
  memory. Use this whenever you can run shell commands.
- **In-session — one subagent per topic.** If you must run inside a single agent
  session, dispatch **one subagent per topic** (each gets its own fresh context),
  and track completion with the ledger below. Your own context holds only the
  ledger and short summaries — never the full work of 27 topics.

Either way, a topic is "done" only when its `audit/<slug>.md` file exists and
contains a `**Score:**` line (N/A verdicts still write a file). Verify files on
disk; do not trust your recollection that you "did" a topic.

## Scoping (do this first)

Spend a few minutes characterising the repo so you don't waste effort auditing
topics that don't apply:

- What is it? (web app, API service, CLI, library, mobile app, data pipeline,
  static site, notebook…)
- What's the stack, and how is it (meant to be) deployed?
- Is there a user-facing UI? (drives whether **accessibility** applies)
- Does it expose an API? (drives **api-design**)
- Does it use a database or persistent storage? (drives **database-management**)
- Is it deployed anywhere, or purely local? (drives **infrastructure**, **observability**, **alerting**, **HA**, **cost**)
- **Where is it hosted?** Raw IaaS (AWS/Azure/GCP → run **26**), an
  application-delivery platform (Vercel/Netlify/Replit/Railway/Render/Fly/Heroku
  → run **27**), both (a hybrid → run both), or nowhere (both `N/A`)? If hosting
  can't be determined from the repo, note that — it is itself a finding.

Record this in the scorecard's "Repository profile" section, including the named
hosting platform. Mark clearly non-applicable topics as `N/A` rather than
scoring them 0.

## Running the topics

Build a ledger of every applicable topic up front (the full list below, minus any
you scoped out as `N/A` — but even `N/A` topics must still get a written report).
Dispatch one subagent per topic; after each returns, mark the ledger `done` **only
after confirming its `audit/<slug>.md` exists on disk**. Do not write the summary
or declare the audit finished while any ledger row is still `pending`. If a
subagent fails or its file is missing, re-dispatch it.

For each applicable topic, follow the corresponding `prompts/NN-*.md` file and
write `audit/<topic>.md`. You may run them in any order; grouping by theme helps:

- **Foundations:** 01 source-control, 02 documentation, 03 solutions-design, 04 task-tracking, 05 environment-management
- **Supply chain & style:** 06 dependency-management, 07 linting
- **Process & delivery:** 08 code-review, 09 remote-code-review, 10 cicd, 21 versioning
- **Correctness:** 11 unit-testing, 12 integration-testing, 13 error-handling
- **Security & data:** 14 application-security, 28 llm-integration, 29 data-privacy
- **Runtime & operability:** 15 logging, 16 observability, 17 alerting, 18 database-management, 19 api-design, 20 infrastructure-as-code, 26 iaas-platforms, 27 application-delivery-platforms
- **Non-functional:** 22 accessibility, 23 scalability, 24 high-availability, 25 cost-operational-readiness

> If you have subagents available, dispatch topics in parallel — each subagent
> owns one topic prompt and writes its own `audit/<topic>.md`. Keep each agent's
> scope to a single topic so context stays focused.

## Aggregate into `audit/SCORECARD.md`

```markdown
# Sanity Check Scorecard

- **Overall maturity:** X.X / 5 (mean of applicable topic scores)
- **Amateur/AI-built likelihood:** <low | moderate | high | near-certain>
- **Verdict:** <Production-viable | Salvageable prototype | Rewrite recommended>
- **Audited:** <date>

## Repository profile

<Stack, purpose, and the **named hosting platform** (e.g. AWS, Vercel, Fly.io, or
"none / local only"), from the scoping step. The named platform drives 26-vs-27
routing and sharpens topics 16, 17, 20, 24, and 25 — record it explicitly, not
just "deployed: yes/no".>

## Scores by topic

| Topic | Score | Signal | Headline risk |
| ----- | ----- | ------ | ------------- |
| Source control | 1/5 | strong | `.env` with live keys committed |
| ... | ... | ... | ... |

## Top 10 risks (ranked)

Pull the most severe findings across all topic reports, ranked by real-world
blast radius (Critical first). Each row: severity · topic · finding · evidence.

## What would make this production-viable

The shortest credible path: the 5–8 changes that move the most Critical/High
findings. Group by "do before any real users", "do before scale", "do before
launch".

## Amateur/AI-built evidence

The concrete provenance signals found (committed secrets, hallucinated
dependencies, README that contradicts the code, assertion-free tests, etc.).
```

## Determining the overall verdict

- **Rewrite recommended** — multiple Critical findings in security/data-safety,
  or mean score < 1.5, or the architecture can't reach the stated goal.
- **Salvageable prototype** — works but mean score ~1.5–3 with a clear remediation
  path and no unfixable Critical design flaws.
- **Production-viable** — mean score ≥ 3.5 and no open Critical findings.

Be honest and specific. A polished demo with committed AWS keys, no tests, and a
single-instance SQLite backend is **not** production-viable, however nice the UI is.
