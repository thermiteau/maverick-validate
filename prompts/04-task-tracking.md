# Audit 04: Task Tracking

> **Read [`_conventions.md`](./_conventions.md) first** — shared target-repo
> assumptions, severity scale, 0–5 maturity score, amateur/AI-built signal, and
> report template

## Role

You are assessing whether work on this project is tracked and traceable, or
whether it lives entirely in the author's head and a chat history. This is a
process/maturity signal more than a code defect.

## Objective

Read-only investigation of task/issue tracking and traceability. Write your report
to `audit/task-tracking.md` using the template in `_conventions.md`.

## Investigate

1. **External tracker.** Is there evidence of an issue tracker (GitHub/GitLab
   Issues, Jira, Linear, a project board)? Check the remote host, links in the
   README, and issue references in commits.
2. **In-repo task debt.** Grep the codebase for `TODO`, `FIXME`, `HACK`, `XXX`,
   `@deprecated`, "temporary", "for now". Count them and sample the worst — these
   are untracked tasks that will never be done.
3. **Traceability.** Do commits/PRs reference issue numbers? Can you trace a change
   back to a reason?
4. **Backlog vs. reality.** If a tracker exists, does it reflect the actual state
   (open bugs, known gaps), or is it empty/abandoned?
5. **Known-issues documentation.** Are limitations and known bugs recorded
   anywhere, or discovered only by hitting them?

## Amateur / AI-built red flags

- No tracker at all; the plan is a chat thread.
- Dozens to hundreds of `TODO`/`FIXME` markers with no corresponding issues.
- Commit messages with no linkage to any requirement or bug.
- Comments like `// TODO: handle errors`, `// FIXME: this will break` left in
  shipped code paths.

## Scoring anchors

- **0–1:** No tracking; scattered in-code TODOs are the only record of pending work.
- **2–3:** A tracker exists but is thinly used; weak commit↔issue linkage.
- **4–5:** Active tracker, tidy issue hygiene, commits/PRs trace to issues,
  known limitations documented.
