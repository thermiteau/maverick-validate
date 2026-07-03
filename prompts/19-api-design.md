# Audit 19: API Design

> **Read [`_conventions.md`](./_conventions.md) first** — shared target-repo
> assumptions, severity scale, 0–5 maturity score, amateur/AI-built signal, and
> report template

## Role

You are auditing the design of any API the project exposes. Amateur APIs are
inconsistent, unversioned, unvalidated, and undocumented — each endpoint invented
in a separate AI session.

> If the project exposes no API (pure UI, CLI, or library), mark this topic `N/A`.

## Objective

Read-only investigation of API design. Write your report to `audit/api-design.md`
using the template in `_conventions.md`.

## Investigate

1. **Consistency.** Are resources, naming, HTTP methods, and status codes used
   consistently, or does each endpoint do its own thing (POST for reads, 200 on
   errors, mixed casing)?
2. **Versioning.** Is the API versioned (path/header) so it can evolve without
   breaking clients? (Ties to 21 versioning.)
3. **Error format.** Is there a consistent, structured error response shape, or
   raw strings / stack traces / inconsistent bodies?
4. **Input validation & schemas.** Are request bodies validated against schemas
   (zod, pydantic, JSON Schema, OpenAPI)? Are oversized/unexpected payloads
   rejected? (Overlaps 13, 14.)
5. **Pagination & limits.** Do list endpoints paginate, or return unbounded result
   sets that will fall over at scale?
6. **Auth & rate limiting.** Are endpoints authenticated as appropriate and
   rate-limited? (Cross-reference 14.)
7. **Documentation.** Is there an OpenAPI/GraphQL schema or reference docs, or must
   clients read the source?
8. **Idempotency & side effects.** Are unsafe methods idempotent where they should
   be? Any idempotency keys for payment-like operations?

## Amateur / AI-built red flags

- No versioning; breaking changes shipped in place.
- Inconsistent status codes (200 with an error body; 500 for validation failures).
- No request validation; endpoints trust whatever they receive.
- List endpoints with no pagination.
- No API docs/schema of any kind.

## Scoring anchors

- **0–1:** Inconsistent, unversioned, unvalidated, undocumented endpoints.
- **2–3:** Reasonably consistent and validated, but unversioned or unpaginated and
  lightly documented.
- **4–5:** Consistent, versioned, schema-validated, paginated, authenticated,
  rate-limited, documented (OpenAPI/GraphQL).
