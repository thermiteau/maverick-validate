# Audit 16: Observability

> **Read [`_conventions.md`](./_conventions.md) first** — shared target-repo
> assumptions, severity scale, 0–5 maturity score, amateur/AI-built signal, and
> report template

## Role

You are auditing whether a deployed version of this system could be understood
from the outside — metrics, traces, and health checks. Amateur apps are completely
blind in production: when something breaks, the first signal is an angry user.

> If the project is a local-only tool/library with no deployed runtime, mark this
> topic `N/A` with a note, and lean on 15 logging instead.

## Objective

Read-only investigation of observability. Write your report to
`audit/observability.md` using the template in `_conventions.md`.

## Investigate

1. **Metrics.** Is there any metrics instrumentation (OpenTelemetry, Prometheus/
   `prom-client`, Micrometer, StatsD)? Are the RED signals (Rate, Errors,
   Duration) captured for request handling?
2. **Tracing.** Any distributed tracing / trace-context propagation across service
   or external-call boundaries? Or is a slow request impossible to diagnose?
3. **Health checks.** Are there liveness/readiness endpoints (`/health`, `/ready`)?
   Does liveness stay lightweight while readiness checks dependencies?
4. **SLIs/SLOs.** Any notion of target availability/latency and error budgets, or
   none at all?
5. **Dashboards & correlation.** Any dashboards, and do metrics/logs/traces share
   IDs so a metric spike can be traced to specific requests and logs?
6. **Blind spots.** If this were live now and slow/erroring, what could the author
   actually see? Usually: nothing.

## Amateur / AI-built red flags

- No metrics, no tracing, no health endpoints.
- Health check that hits the database (so a slow DB triggers restart loops), or a
  fake `return 200` that never reflects real health.
- "Monitoring" that is just tailing logs by hand.
- High-cardinality labels (user IDs) if any metrics exist.

## Scoring anchors

- **0–1:** No metrics, traces, or health checks; blind in production.
- **2–3:** Basic health check and/or some metrics, but no tracing, SLOs, or
  dashboards.
- **4–5:** RED metrics, distributed tracing with propagation, proper
  liveness/readiness, SLIs/SLOs, and dashboards linking the three pillars.
