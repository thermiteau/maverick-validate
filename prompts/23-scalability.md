# Audit 23: Scalability

> **Read [`_conventions.md`](./_conventions.md) first** — shared target-repo
> assumptions, severity scale, 0–5 maturity score, amateur/AI-built signal, and
> report template.

## Role

You are assessing whether this system survives contact with real traffic and data
volume. Amateur/AI code is written for a demo of one user and one row, and quietly
assumes it never grows. This is exactly the class of question the author never
thought to ask the AI.

## Objective

Read-only investigation of scalability. Write your report to
`audit/scalability.md` using the template in `_conventions.md`. Reason about
*orders of magnitude* — what happens at 100×/1000× today's load or data?

## Investigate

1. **Stateless vs. stateful processes.** Can the app run as multiple instances
   behind a load balancer, or does it hold state in memory (in-process sessions,
   caches, counters, uploaded files on local disk) that breaks when horizontally
   scaled?
2. **Database access patterns.** N+1 queries, missing indexes, `SELECT *`,
   unbounded queries, loading whole tables into memory, per-request full scans?
   (Ties to 18.)
3. **Pagination & bounded work.** Do list/search endpoints and jobs bound their
   work, or grow linearly with data until they time out / OOM?
4. **Caching.** Is anything expensive cached (HTTP caching, memoisation, Redis)?
   Or is every request recomputed from scratch?
5. **Synchronous heavy work.** Are long tasks (emails, image/video processing, LLM
   calls, report generation) done inline in the request, blocking the worker,
   instead of on a queue/background worker?
6. **Concurrency model.** Single-threaded/single-process by default? Any worker
   pool / async I/O, or does one slow request block others?
7. **External rate limits & fan-out.** Does the code respect third-party rate
   limits and batch calls, or hammer APIs in loops?
8. **Resource limits.** Are payload sizes, upload sizes, and query result sizes
   bounded, or can one request consume all memory?

## Amateur / AI-built red flags

- Sessions/uploads/state stored in process memory or local disk — can't scale out.
- SQLite / single-file DB as the primary store for a multi-user app.
- N+1 queries and unindexed lookups on hot paths.
- Heavy work (LLM/email/image) run synchronously in the request handler.
- No caching anywhere; everything recomputed per request.
- Unbounded list endpoints and unbounded uploads.

## Scoring anchors

- **0–1:** Single-instance-only by construction; obvious N+1/unbounded work; would
  fall over at modest concurrency.
- **2–3:** Would scale vertically for a while; some pagination/caching, but stateful
  processes or heavy sync work cap horizontal scaling.
- **4–5:** Stateless and horizontally scalable, bounded queries with pagination,
  caching, background workers for heavy tasks, sensible resource limits.
