# Audit 13: Error Handling & Resilience

> **Read [`_conventions.md`](./_conventions.md) first** — shared target-repo
> assumptions, severity scale, 0–5 maturity score, amateur/AI-built signal, and
> report template

## Role

You are auditing how the system behaves when things go wrong. Amateur/AI code
handles the happy path and either crashes or silently swallows everything else.

## Objective

Read-only investigation of error handling. Write your report to
`audit/error-handling.md` using the template in `_conventions.md`.

## Investigate

1. **Swallowed errors.** Grep for empty catches: `catch {}`, `except: pass`,
   `except Exception: pass`, `catch (e) {}`, `.catch(() => {})`. These hide
   failures and produce silent data corruption.
2. **Unhandled failures.** Are external calls (network, DB, filesystem, third-party
   APIs) wrapped in error handling, or do they throw straight to the user / crash
   the process? Any global handler for uncaught exceptions / unhandled rejections?
3. **Input validation at boundaries.** Is untrusted input validated before use, or
   does malformed input cause 500s / stack traces / crashes? (Overlaps 14 security.)
4. **Retries & timeouts.** Do outbound calls have timeouts and sensible retries
   (with backoff) for transient failures — or do they hang forever / fail on the
   first blip?
5. **Graceful degradation.** When a dependency is down, does the system degrade
   gracefully or fall over entirely? Any circuit-breaker / fallback behaviour?
6. **Error surfacing.** Are errors returned as typed/structured results with useful
   (non-leaky) messages, or do raw stack traces reach users? (Leaking internals is
   also a security issue.)
7. **Resource cleanup.** Are files/connections/locks released on error paths
   (`finally`, context managers, `defer`), or leaked?

## Amateur / AI-built red flags

- Empty catch blocks / bare `except: pass` scattered through the code.
- No timeouts on any network/DB call.
- Raw exceptions and stack traces returned to the client.
- `try/except Exception` wrapping huge blocks, hiding the real failure.
- No handling for the case where an external API returns an error or is down.
- Process crashes on any unexpected input.

## Scoring anchors

- **0–1:** Errors are swallowed or crash the app; no validation, timeouts, or
  retries.
- **2–3:** Some error handling on obvious paths, but inconsistent; missing
  timeouts/retries and graceful degradation.
- **4–5:** Consistent, typed error handling; validated inputs; timeouts, retries
  with backoff, graceful degradation, and clean resource cleanup.
