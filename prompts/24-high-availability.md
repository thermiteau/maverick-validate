# Audit 24: High Availability & Resilience

> **Read [`_conventions.md`](./_conventions.md) first** — shared target-repo
> assumptions, severity scale, 0–5 maturity score, amateur/AI-built signal, and
> report template

## Role

You are assessing whether the system stays up when a part of it fails. Amateur/AI
deployments are a single process on a single box with a single database and no
backups — a house of cards where any one failure is a total, possibly permanent,
outage.

> If the project has no deployed runtime, assess the *architecture's* resilience
> potential and note that it isn't deployed.

## Objective

Read-only investigation of availability and resilience. Write your report to
`audit/high-availability.md` using the template in `_conventions.md`.

## Investigate

1. **Single points of failure.** Map them. One app instance? One database with no
   replica? One node/region? A cron on the author's laptop? What is the blast radius
   of each failing?
2. **Redundancy.** Can the app run as ≥2 instances? Is there any load balancing /
   failover, or is it one process that, once dead, stays dead until a human notices?
3. **Data durability.** Backups exist and are *tested*? Point-in-time recovery? Or
   is the only copy of the data one disk away from gone? (Ties to 18.)
4. **Dependency failure handling.** When a downstream dependency (DB, cache,
   third-party API) is slow or down, does the app degrade gracefully, or cascade
   into a full outage? Timeouts, retries, circuit breakers? (Ties to 13.)
5. **Statelessness for recovery.** Can an instance be killed and replaced with no
   data loss (state externalised), or does restarting lose in-flight/in-memory data?
6. **Deployment safety.** Does deploying cause downtime (stop-then-start), or is
   there rolling/blue-green/zero-downtime deploy? Is there a rollback path? (Ties to 10.)
7. **Recovery objectives.** Is there any notion of RTO/RPO (how fast, how much data
   loss is acceptable), or has recovery never been considered?
8. **Scheduled work resilience.** Do cron/background jobs run somewhere durable, or
   on a single machine where a reboot silently stops them?

## Amateur / AI-built red flags

- Single instance + single DB + no backups = total, permanent-loss risk.
- Cron jobs or the whole app running on the author's personal machine.
- No timeouts on downstream calls, so one slow dependency hangs everything.
- Restarting the app loses sessions/queued work held in memory.
- Deploys require taking the app down; no rollback.

## Scoring anchors

- **0–1:** Multiple single points of failure; no backups; any one failure is a
  full/permanent outage.
- **2–3:** Some resilience (backups exist, graceful handling of some failures), but
  still single-instance or with untested recovery.
- **4–5:** Redundant instances, replicated + backed-up (and restore-tested) data,
  graceful degradation, zero-downtime deploys with rollback, defined RTO/RPO.
