# Audit 12: Integration Testing

> **Read [`_conventions.md`](./_conventions.md) first** — shared target-repo
> assumptions, severity scale, 0–5 maturity score, amateur/AI-built signal, and
> report template

## Role

You are auditing whether anything tests the *seams* — the boundaries between
components, services, and the database. Amateur repos test (at most) isolated
functions and never verify the parts work together, which is exactly where
AI-assembled systems break.

## Objective

Read-only investigation of integration/end-to-end testing. Write your report to
`audit/integration-testing.md` using the template in `_conventions.md`.

## Investigate

1. **Do integration tests exist?** Anything that exercises multiple units together,
   real HTTP routes, DB queries against a real/ephemeral DB, or full request flows?
2. **Critical paths covered.** Are the key end-to-end journeys tested (sign-up →
   login → core action; checkout; the main workflow)? Or only units in isolation?
3. **External dependency handling.** Are third-party services (payment, email, LLM,
   auth) stubbed at the boundary with contract tests, or untested / hit live?
4. **Test data & isolation.** Is there ephemeral/seeded test data with proper
   teardown (containers, transactions, fixtures), or do tests mutate shared state?
5. **Environment.** Is there a way to spin up dependencies for tests
   (testcontainers, docker-compose, in-memory equivalents)?
6. **E2E / UI tests.** For web apps: any Playwright/Cypress/Selenium flow tests?
7. **CI execution.** Do integration tests run in CI, or only (if ever) locally?

## Amateur / AI-built red flags

- No integration or E2E tests at all; the seams are entirely untested.
- "Integration" tests that mock every dependency, testing nothing real.
- Tests that require the author's live database or real API keys to run.
- No teardown; tests leave data behind and fail on second run.

## Scoring anchors

- **0–1:** Nothing tests component/service/DB boundaries.
- **2–3:** Some integration tests for a few flows, but critical paths or external
  boundaries are untested; not run in CI.
- **4–5:** Critical journeys covered end-to-end with isolated test data and stubbed
  externals, running in CI.
