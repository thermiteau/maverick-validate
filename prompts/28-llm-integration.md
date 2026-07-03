# Audit 28: LLM / AI Integration

> **Read [`_conventions.md`](./_conventions.md) first** — shared target-repo
> assumptions, severity scale, 0–5 maturity score, amateur/AI-built signal, and
> report template

## Role

You are auditing how the project integrates with an LLM or AI provider (OpenAI,
Anthropic, Google, a local model, or an orchestration layer such as LangChain).
Vibe-coded projects are disproportionately AI-wrapper apps, so this is often the
riskiest and least-understood part of the system: the author wired up a provider
because the AI told them to, without knowing how prompt injection, unvalidated
output, or uncapped token spend can hurt them.

> If the project makes no LLM/AI-provider calls, mark this topic `N/A` with a
> one-line justification.

**Scope boundary.** Generic secret handling lives in 14 (security) and generic
spend lives in 25 (cost); this prompt covers their *LLM-specific manifestations*
(a key in the browser calling a paid model, an unbounded token bill from a public
endpoint) plus the correctness of the integration itself. Cross-reference 13
(error handling), 27 (platform), and 29 (data privacy).

## Objective

Read-only investigation of LLM/AI integration. Write your report to
`audit/llm-integration.md` using the template in `_conventions.md`. Do not call
the provider or run the app; identify issues from the code and config.

## Investigate

1. **Keys & provider access.** Is the provider API key kept server-side, or is it
   exposed in client code / a public bundle (`NEXT_PUBLIC_`, `VITE_`,
   `REACT_APP_`) or called directly from the browser? A leaked LLM key is both a
   secret breach and an open cheque. Are calls proxied through the backend with
   per-user authorisation? (Cross-ref 14, 27.)
2. **Prompt injection.** Is untrusted input (user text, uploaded files, retrieved
   documents, web content, tool output) concatenated into the prompt with no
   separation of instructions from data? Is there any defence against jailbreaks
   or instruction-override ("ignore previous instructions")? Critically: does
   model output drive **tools, actions, SQL, shell, or code** without validation —
   turning prompt injection into real-world impact?
3. **Output handling.** Is model output rendered as HTML/markdown without
   sanitisation (XSS), interpolated into SQL/shell/file paths, or `eval`'d? If the
   model is asked for JSON, is the output schema-validated with a fallback for
   malformed responses, or blindly `JSON.parse`d (which will throw in production)?
4. **Cost & rate control.** Is token spend bounded — `max_tokens` set, prompt/
   context sizes capped, identical calls cached? Is there a per-user and global
   rate limit on any paid endpoint, especially unauthenticated ones? Do retries or
   agent loops multiply cost without a ceiling? (Cross-ref 25.)
5. **Reliability.** Are provider calls wrapped with a timeout, sensible retries
   (with backoff on 429/5xx), and a fallback when the provider errors, rate-limits,
   or is slow? Or does a provider hiccup crash the request / hang the app / take
   the whole product down? (Cross-ref 13.)
6. **Model & config hygiene.** Are model IDs current and not deprecated/
   hallucinated? Are parameters (temperature, top-p) chosen deliberately for the
   task? Streaming handled correctly? Any evals or regression tests so a prompt
   edit doesn't silently degrade output quality?
7. **Data governance.** Is PII or secret data sent to a third-party provider
   without apparent awareness? Is there any consideration of the provider's data
   retention / training-opt-out? (Cross-ref 29.)

## Amateur / AI-built red flags

- An LLM API key shipped in the client bundle or called directly from the browser.
- User input pasted straight into a system prompt with no instruction/data split.
- Model output rendered with `dangerouslySetInnerHTML` / `v-html`, or used to
  build a SQL query, shell command, or file path.
- Model JSON `JSON.parse`d with no try/catch and no schema validation.
- No `max_tokens`, no timeout, and no rate limit on a public AI endpoint.
- No fallback when the provider returns an error or 429 — the feature just breaks.
- Hardcoded deprecated/hallucinated model names.

## Scoring anchors

- **0–1:** Provider key exposed client-side, **or** unvalidated model output
  reaches a dangerous sink (injection → RCE / XSS / SQL), **or** an unauthenticated
  public endpoint drives uncapped paid calls.
- **2–3:** Keys are server-side and output is loosely validated, but there is no
  prompt-injection defence, no timeout/fallback, or no spend/rate cap.
- **4–5:** Keys proxied and authorised, instructions separated from untrusted data,
  output schema-validated and context-encoded, spend bounded with rate limits,
  timeouts + retries + graceful fallback, and prompt regression tests.
