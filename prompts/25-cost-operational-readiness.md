# Audit 25: Cost & Operational Readiness

> **Read [`_conventions.md`](./_conventions.md) first** — shared target-repo
> assumptions, severity scale, 0–5 maturity score, amateur/AI-built signal, and
> report template

## Role

You are assessing whether this system can be *operated* affordably and safely once
it's real — the boring realities the author never asked the AI about: runaway
bills, no limits, no way to deploy or recover repeatably. Vibe-coded apps ship
with uncapped third-party API calls and no operational plan.

## Objective

Read-only investigation of cost and operational readiness. Write your report to
`audit/cost-operational-readiness.md` using the template in `_conventions.md`.

## Investigate

1. **Uncapped cost drivers.** Identify anything metered: LLM/AI API calls, email/
   SMS, cloud functions, storage, egress. Are there usage limits, budgets, or
   spend alerts — or could a loop/bot/viral spike produce a shock bill?
2. **Abuse & rate limiting.** Can an anonymous user trigger expensive operations
   without limits (unauthenticated LLM endpoint, unthrottled uploads)? (Ties to 14, 23.)
3. **Resource right-sizing.** Any evidence of thinking about compute/memory sizing,
   or is it "biggest instance" / "whatever the default is"?
4. **Deployability.** Can someone other than the author deploy this from the docs,
   repeatably? (Ties to 10, 20.) Or is deployment a one-person manual ritual?
5. **Runbooks & recovery.** Is there any operational documentation — how to deploy,
   roll back, restore data, rotate a leaked key, respond to an incident? Or none?
6. **Configuration & feature flags.** Can behaviour be changed/turned off without a
   code deploy (kill switch for an expensive feature), or is everything hardcoded?
7. **Ownership & on-call.** Is it clear who operates this and how they'd be reached?
   (Realistically: one person, no plan — note it.)
8. **Data & compliance overheads.** Any obligations implied by the data (PII,
   payments) that carry operational cost the author hasn't accounted for?

## Amateur / AI-built red flags

- Unauthenticated or unthrottled calls to paid APIs (LLM, email/SMS) — bill-bomb risk.
- No budget alerts or spend caps on any cloud/AI account.
- No runbook; deploy/rollback/restore live only in the author's head.
- No kill switch to disable an expensive or misbehaving feature without a redeploy.
- No cost consideration anywhere; "it's basically free" assumptions.

## Scoring anchors

- **0–1:** Uncapped paid operations reachable by anyone; no budgets, no runbooks, no
  repeatable deploy.
- **2–3:** Some limits and a rough deploy process, but no spend alerts, thin
  runbooks, and single-person operability.
- **4–5:** Cost drivers bounded and monitored with budget alerts, abuse-limited,
  repeatable deploy/rollback, runbooks for common incidents, and clear ownership.
