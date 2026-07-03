# Audit 15: Logging

> **Read [`_conventions.md`](./_conventions.md) first** — shared target-repo
> assumptions, severity scale, 0–5 maturity score, amateur/AI-built signal, and
> report template

## Role

You are auditing whether the running system can be understood from its logs.
Amateur apps use `print`/`console.log` debugging left in, no levels, no structure,
and — dangerously — sometimes log passwords and tokens.

## Objective

Read-only investigation of logging. Write your report to `audit/logging.md` using
the template in `_conventions.md`.

## Investigate

1. **Logging approach.** Is a real logging library used with levels
   (debug/info/warn/error), or ad-hoc `print`/`console.log`/`fmt.Println`
   scattered around?
2. **Structure.** Are logs structured (JSON/key-value) for machine parsing, or
   free-text strings that can't be queried?
3. **Levels used correctly.** Is there control over verbosity per environment, or
   is everything logged at one level (or debug spam in prod)?
4. **Sensitive data in logs.** Grep for logging of passwords, tokens, API keys,
   full request bodies, card/PII data. Logging secrets is a security finding.
5. **Correlation.** Do logs carry a request/trace/correlation ID so a single
   request can be followed? (Ties to 16 observability.)
6. **Context & usefulness.** Do error logs include enough context (what failed,
   inputs, stack) to diagnose, or just "error" / "something went wrong"?
7. **Aggregation.** Is there any log shipping/aggregation for a deployed service,
   or do logs vanish with the process/container?
8. **Noise.** Debug `print`s and commented-out logging left in shipped code.

## Amateur / AI-built red flags

- `print`/`console.log` used as the logging strategy.
- No log levels; no way to reduce verbosity in production.
- Secrets, tokens, or full PII payloads written to logs.
- Unstructured messages that can't be searched or aggregated.
- No correlation IDs; impossible to trace a request across components.

## Scoring anchors

- **0–1:** `print`-style debugging only, or secrets logged.
- **2–3:** A logging library with levels, but unstructured and not aggregated; no
  correlation IDs.
- **4–5:** Structured, levelled logging with correlation IDs, no sensitive data,
  shipped to an aggregator.
