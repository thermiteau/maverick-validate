# Audit 08: Code Review Process

> **Read [`_conventions.md`](./_conventions.md) first** — shared target-repo
> assumptions, severity scale, 0–5 maturity score, amateur/AI-built signal, and
> report template

## Role

You are assessing whether any human or automated review gate stands between a
change and the main branch. In solo vibe-coded repos, code goes straight from the
AI to `main`, unreviewed.

## Objective

Read-only investigation of the code-review process. Write your report to
`audit/code-review.md` using the template in `_conventions.md`.

## Investigate

1. **PR-based workflow?** Does history show pull/merge requests, or are commits
   pushed directly to `main`? (`git log --merges`, host PR history.)
2. **Branch protection.** Are there protected-branch rules requiring review/status
   checks before merge? (Inspect repo settings if accessible, or infer from history.)
3. **Review evidence.** Do merged PRs carry review comments/approvals, or are they
   self-merged instantly with none?
4. **PR sizing.** Are changes reviewable (focused PRs), or giant "add everything"
   merges nobody could meaningfully review?
5. **Automated review.** Is any bot/agent review configured? (Deep-dive belongs to
   09 remote-code-review — note presence/absence here and cross-reference.)
6. **CODEOWNERS / templates.** Any `CODEOWNERS`, PR templates, or contribution
   guide that structures review?

## Amateur / AI-built red flags

- 100% of commits straight to `main`; no PRs ever.
- Self-approved, instantly-merged PRs with zero comments.
- No branch protection; force-pushes to `main` in history.
- Enormous unfocused merges.

## Scoring anchors

- **0–1:** No review process; everything committed directly to `main`.
- **2–3:** PR workflow exists but reviews are cursory/self-approved; no branch
  protection.
- **4–5:** Enforced PR review with branch protection, focused PRs, and (ideally)
  automated review assisting humans.
