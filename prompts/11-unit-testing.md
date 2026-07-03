# Audit 11: Unit Testing

> **Read [`_conventions.md`](./_conventions.md) first** — shared target-repo
> assumptions, severity scale, 0–5 maturity score, amateur/AI-built signal, and
> report template

## Role

You are auditing the unit-test safety net. Vibe-coded repos usually have zero
tests — or a handful of AI-generated tests that assert nothing meaningful and
exist only to make a green badge.

## Objective

Read-only investigation of unit testing. Write your report to
`audit/unit-testing.md` using the template in `_conventions.md`.

## Investigate

1. **Tests exist and run.** Is there a test suite? Run it. Does it pass? How many
   tests, and how long do they take?
2. **Meaningful assertions.** Sample the tests. Do they assert real behaviour, or
   are they tautological / assertion-free / just checking "no error thrown"? Tests
   that mock the very thing they claim to test are a red flag.
3. **Coverage.** Is coverage measured? Run it if possible and report line/branch
   coverage. Note that high coverage with weak assertions is worse than it looks.
4. **What's tested vs. what matters.** Is the critical business logic (payments,
   auth, calculations, validation) tested, or only trivial getters?
5. **Edge cases & error paths.** Are boundaries, empty/null inputs, and error paths
   covered, or only the happy path?
6. **Isolation & determinism.** Do units mock external I/O (network, DB, filesystem,
   clock), or hit real services? Are tests order-independent and non-flaky?
7. **CI enforcement.** Are tests run in CI as a blocking gate? Any coverage
   threshold enforced?

## Amateur / AI-built red flags

- No tests at all, or a single `it('works', () => {})`.
- Tests with no `expect`/`assert`, or that only assert `toBeDefined()`.
- Tests that mock the function under test, or re-implement the logic they assert.
- Only happy-path tests; no error or edge-case coverage.
- Tests hitting real networks/DBs, so they're slow and flaky.
- Commented-out or skipped (`.skip`, `xit`) tests hiding failures.

## Scoring anchors

- **0–1:** No tests, or tests that assert nothing.
- **2–3:** Real tests for some logic, happy-path-heavy, no coverage gate, some
  brittleness.
- **4–5:** Meaningful, isolated, deterministic tests covering critical logic and
  edge cases, coverage measured and enforced in CI.
