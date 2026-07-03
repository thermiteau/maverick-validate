# Audit 17: Alerting

> **Read [`_conventions.md`](./_conventions.md) first** — shared target-repo
> assumptions, severity scale, 0–5 maturity score, amateur/AI-built signal, and
> report template

## Role

You are auditing whether anyone finds out when the system breaks. In amateur
projects, failures are entirely silent — the author discovers outages by chance,
often long after users did.

> If the project has no deployed runtime, mark this topic `N/A` with a note.

## Objective

Read-only investigation of alerting on failures. Write your report to
`audit/alerting.md` using the template in `_conventions.md`.

## Investigate

1. **Fatal-error alerting.** Is there any mechanism to notify a human on
   crashes/fatal errors (error tracker like Sentry/Rollbar, alert rules, on-call,
   a webhook to email/Slack)? Or nothing?
2. **Error tracking integration.** Is an exception-reporting service wired in and
   actually initialised (not just an unused dependency)?
3. **Severity & routing.** Is there any concept of severity, or would every log
   line page someone (alert fatigue) — or, more likely, nothing alerts at all?
4. **Actionable context.** If an alert did fire, would it carry enough context
   (stack, request ID, environment) to act on?
5. **Coverage of critical paths.** Are failures in the important flows (payments,
   auth, data writes, scheduled jobs) surfaced, or could they fail silently for
   days?
6. **Uptime/synthetic checks.** Any external uptime monitor / synthetic probe that
   would catch a total outage?

## Amateur / AI-built red flags

- No error tracking or alerting of any kind; failures are invisible.
- An error-tracking SDK present as a dependency but never initialised.
- Critical background jobs that can fail with zero notification.
- No uptime monitoring; a full outage would go unnoticed.

## Scoring anchors

- **0–1:** Nothing alerts on failure; outages are discovered by accident.
- **2–3:** Basic error tracking or uptime monitoring exists, but coverage is
  partial and routing/severity is crude.
- **4–5:** Fatal errors alert a human with actionable context, severity-based
  routing, and uptime/synthetic monitoring on critical paths.
