# Shared Audit Conventions

> Every topic prompt in this folder references this file. If you are running a
> single topic prompt standalone, read this section first — it defines the
> target-repo assumptions, the severity scale, the maturity score, and the
> report format that all prompts share.

## About the target repository

The repository under audit was very likely built by a **non-technical person or
a beginner driving an AI coding assistant** ("vibe-coded"). Work from these
assumptions until the evidence says otherwise:

- The **happy path probably works** — a demo runs. That is not evidence of quality.
- The author **did not know which questions to ask the AI**, so entire concerns
  were never requested: scalability, availability, testing, security,
  operability, cost, data safety.
- **Absence is a finding.** "No CI config found", "no tests", "no error
  handling" are results, not dead ends. Do not assume a missing practice was
  deliberately deemed unnecessary.
- Expect **AI scaffolding hallmarks**: placeholder secrets committed to the
  repo, `TODO`/`FIXME` left in, copy-pasted boilerplate, dependencies pinned to
  whatever was latest that day, README claims that don't match the code,
  defensive code that silently swallows errors, and config that only works on
  the author's machine.
- Be **specific and evidence-based**. Every finding must cite `path/to/file:line`
  or a concrete command output. Never invent findings; if you cannot find
  evidence for or against a practice, say so and score accordingly.

## Severity scale

| Severity     | Meaning                                                                          |
| ------------ | -------------------------------------------------------------------------------- |
| **Critical** | Causes data loss, a breach, or an outage in normal use — or is already broken.   |
| **High**     | Likely to fail or be exploited under realistic load/input; no safety net exists. |
| **Medium**   | Degrades reliability or maintainability; a gap a professional would not ship.    |
| **Low**      | Minor deviation from best practice; low blast radius.                            |
| **Info**     | Observation or future improvement; not a defect today.                           |

## Maturity score (0–5)

| Score | Label            | Meaning                                                               |
| ----- | ---------------- | --------------------------------------------------------------------- |
| **0** | Absent           | No evidence of the practice at all.                                   |
| **1** | Accidental       | Fragments exist but are non-functional, unused, or purely decorative. |
| **2** | Basic / broken   | Present but with serious gaps typical of AI-generated scaffolding.    |
| **3** | Adequate         | Works with some gaps; not yet production-grade.                       |
| **4** | Solid            | Follows most best practices; minor gaps only.                         |
| **5** | Production-grade | Comprehensive, tested, and maintained.                                |

## Amateur / AI-built signal strength

Alongside the score, rate how strongly this topic signals amateur/AI-built origin:
`none` · `weak` · `moderate` · `strong`. This is about *provenance evidence*
(e.g. committed secrets, hallucinated dependencies, contradictory README), which
is distinct from the maturity score.

## Report format

Write your findings to `audit/<topic>.md` (create the `audit/` directory if
needed). Use this exact skeleton:

```markdown
# <Topic> Audit

- **Score:** X/5 — <label>
- **Amateur/AI-built signals:** <none | weak | moderate | strong>
- **Verdict:** <one sentence>

## Summary

<2–4 sentences: what exists, what is missing, the headline risk.>

## Findings

| #   | Severity | Finding | Evidence (file:line) | Recommendation |
| --- | -------- | ------- | -------------------- | -------------- |
| 1   | High     | ...     | `src/x.ts:42`        | ...            |

## Gap list — what "good" looks like here

- [ ] <checklist item the repo does not yet satisfy>

## Score justification

<Why this score and not one higher or lower. Reference the findings.>
```

Keep findings concrete and de-duplicated. Prefer 5 sharp findings over 30 noisy
ones. If the topic does not apply to this repository (e.g. accessibility for a
headless CLI), say so explicitly, score it `N/A`, and explain why.
