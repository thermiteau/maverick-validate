# AI Code Sanity Check — Audit Prompts

A library of drop-in prompts for **Claude Code** or **Codex** that audit a
repository for the failure modes typical of software built by a non-technical
person or beginner driving an AI assistant ("vibe-coded" projects).

Each prompt investigates **one best-practice topic**, writes an evidence-backed
findings report to `audit/<topic>.md`, and assigns a **0–5 maturity score** plus
an **amateur/AI-built signal** rating.

## How to run

1. Point your agent at the target repository (open it as the working directory).
2. Every topic prompt references [`_conventions.md`](./prompts/_conventions.md) — the
   shared severity scale, scoring rubric, and report template. Read it once.
3. Run one of:
   - **The whole suite, guaranteed complete (recommended)** — use the driver
     script (see below). It runs each prompt in its own fresh process so a long
     run can't skip topics.
   - **The whole suite, in one agent session** — give the agent
     [`00-orchestrator.md`](./prompts/00-orchestrator.md). It dispatches one
     subagent per topic and tracks a completion ledger, then rolls the results
     into `audit/SCORECARD.md`.
   - **A single topic** — paste or `@`-reference one file, e.g.
     `Follow the instructions in prompts/14-application-security.md`.

Reports are written under `audit/` in the target repo. Nothing is modified in the
codebase itself — these prompts are **read-only investigations**.

## Running the full suite without skipping topics

The suite is 27 heavy prompts. If a single agent session tries to do them all it
will run out of context and silently skip, truncate, or shallow-do topics. The
driver script removes that failure mode structurally. Two equivalent versions
ship, one per platform:

| OS                | Script            | Run with                                             |
| ----------------- | ----------------- | ---------------------------------------------------- |
| Linux             | [`run-audit.sh`](./run-audit.sh)   | `./run-audit.sh --target …`                          |
| macOS (zsh/bash)  | [`run-audit.sh`](./run-audit.sh)   | `./run-audit.sh --target …` (runs under bash via its shebang) |
| Windows           | [`run-audit.ps1`](./run-audit.ps1) | `powershell -ExecutionPolicy Bypass -File .\run-audit.ps1 -Target …` |

Both behave identically:

- **Isolation** — each prompt runs in its own fresh agent process, so context
  spent on one topic can't starve the next.
- **Proof, not memory** — a topic counts as done only when its `audit/<topic>.md`
  report actually exists and looks valid; the filesystem is the ledger.
- **Loud failure** — if any report is missing at the end, the script exits
  non-zero and names the gaps. "Complete" is verified, never assumed.
- **Resumable** — re-running skips topics already produced, so a crash or
  rate-limit halfway through never forces a full redo.

```bash
# Linux / macOS  (reports land in <repo>/audit/)
./run-audit.sh --target /path/to/repo/under/audit
./run-audit.sh --target ../my-app --agent codex
./run-audit.sh --target ../my-app --only "14 23 24"
./run-audit.sh --target ../my-app --dry-run
```

```powershell
# Windows (PowerShell 5.1 or 7) — same flags, PowerShell-style
.\run-audit.ps1 -Target C:\code\my-app
.\run-audit.ps1 -Target ..\my-app -Agent codex
.\run-audit.ps1 -Target ..\my-app -Only "14 23 24"
.\run-audit.ps1 -Target ..\my-app -DryRun
```

The agent command lives in one editable place near the top of each script
(`run_agent` in the `.sh`, `Invoke-Agent` in the `.ps1`) — adjust it if your
`claude`/`codex` CLI version needs different flags, or select `custom` with the
`AUDIT_CMD` environment variable. Run `./run-audit.sh --help` (or
`Get-Help .\run-audit.ps1`) for all options.

## Topics

| #   | Prompt                                                                              | What it catches                                                                    |
| --- | ----------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------- |
| 00  | [Orchestrator](./prompts/00-orchestrator.md)                                        | Runs all topics, aggregates a scorecard                                            |
| 01  | [Source control](./prompts/01-source-control.md)                                    | Committed secrets, no remote, junk in history                                      |
| 02  | [Documentation](./prompts/02-documentation.md)                                      | README that lies, no setup/run docs                                                |
| 03  | [Solutions design](./prompts/03-solutions-design.md)                                | No design, no ADRs, accidental architecture                                        |
| 04  | [Task tracking](./prompts/04-task-tracking.md)                                      | No issue tracker, no traceability                                                  |
| 05  | [Environment management](./prompts/05-environment-management.md)                    | "Works on my machine", no reproducible setup                                       |
| 06  | [Dependency management](./prompts/06-dependency-management.md)                      | No lockfile, hallucinated/abandoned/vulnerable deps                                |
| 07  | [Linting & formatting](./prompts/07-linting.md)                                     | No linter, inconsistent style, dead code                                           |
| 08  | [Code review](./prompts/08-code-review.md)                                          | Direct-to-main, no review gate                                                     |
| 09  | [Remote code review](./prompts/09-remote-code-review.md)                            | No automated PR review in CI                                                       |
| 10  | [CI/CD](./prompts/10-cicd.md)                                                       | No pipeline, no quality gates, manual deploys                                      |
| 11  | [Unit testing](./prompts/11-unit-testing.md)                                        | No tests, assertion-free tests, no coverage                                        |
| 12  | [Integration testing](./prompts/12-integration-testing.md)                          | Nothing tests the seams between components                                         |
| 13  | [Error handling](./prompts/13-error-handling.md)                                    | Swallowed errors, no retries, crashes on bad input                                 |
| 14  | [Application security](./prompts/14-application-security.md)                        | OWASP Top 10, injection, secrets, authz                                            |
| 15  | [Logging](./prompts/15-logging.md)                                                  | `print` debugging, no structure, logged secrets                                    |
| 16  | [Observability](./prompts/16-observability.md)                                      | No metrics/traces/health checks, blind in prod                                     |
| 17  | [Alerting](./prompts/17-alerting.md)                                                | Failures are silent; nobody gets paged                                             |
| 18  | [Database management](./prompts/18-database-management.md)                          | No migrations, no backups, no pooling                                              |
| 19  | [API design](./prompts/19-api-design.md)                                            | No versioning, inconsistent errors, no pagination                                  |
| 20  | [Infrastructure as code](./prompts/20-infrastructure-as-code.md)                   | Click-ops infra, no reproducible environments                                      |
| 21  | [Versioning & releases](./prompts/21-versioning.md)                                 | No SemVer, no changelog, breaking changes                                          |
| 22  | [Accessibility](./prompts/22-accessibility.md)                                      | No a11y for user-facing UIs (WCAG)                                                 |
| 23  | [Scalability](./prompts/23-scalability.md)                                          | Won't survive load; N+1, no caching, single node                                   |
| 24  | [High availability & resilience](./prompts/24-high-availability.md)                | Single points of failure, no failover/backups                                      |
| 25  | [Cost & operational readiness](./prompts/25-cost-operational-readiness.md)         | Runaway cost, no limits, not deployable/operable                                   |
| 26  | [IaaS platforms](./prompts/26-iaas-platforms.md)                                   | Raw-cloud traps: open IAM/network/storage, no billing guardrails                   |
| 27  | [App-delivery platforms](./prompts/27-application-delivery-platforms.md)           | PaaS traps: ephemeral disk, timeouts, dashboard-only config, leaked client secrets |
| 28  | [LLM / AI integration](./prompts/28-llm-integration.md)                            | Client-side keys, prompt injection, unvalidated output, uncapped token spend       |
| 29  | [Data privacy & compliance](./prompts/29-data-privacy.md)                          | PII with no consent/retention/deletion, PII in logs, undisclosed third-party flows |

## Maintaining the suite

After adding, removing, renumbering, or editing a prompt, run the self-consistency
checker. It verifies the invariants the driver scripts and orchestrator rely on —
contiguous numbering, every prompt linked from this README and grouped in the
orchestrator, all links resolving, the invariant section shape, and the
`NN-<slug>.md → audit/<slug>.md` output mapping — and exits non-zero listing any
violation.

```bash
./check-suite.sh          # Linux / macOS
```
```powershell
.\check-suite.ps1         # Windows (PowerShell 5.1 or 7)
```

## Scoring at a glance

- **0–1** across many topics → almost certainly amateur/AI-built and not
  production-viable without significant remediation.
- **2–3** typical → a working prototype that has never met real users, load, or
  an attacker.
- **4–5** → professionally maintained; the audit becomes a punch list, not a rescue.

See [`prompts/_conventions.md`](./prompts/_conventions.md) for full definitions.
