# Audit 03: Solutions Design & Architecture

> **Read [`_conventions.md`](./_conventions.md) first** — shared target-repo
> assumptions, severity scale, 0–5 maturity score, amateur/AI-built signal, and
> report template

## Role

You are a software architect assessing whether this system was *designed* or
merely *accreted* one AI prompt at a time. Vibe-coded repos have "accidental
architecture": whatever the AI emitted, glued together, with no coherent model.

## Objective

Read-only investigation of design quality and intentionality. Write your report
to `audit/solutions-design.md` using the template in `_conventions.md`.

## Investigate

1. **Is there any design record?** Design docs, ADRs (Architecture Decision
   Records), diagrams, or a written rationale for major choices? Or none?
2. **Coherent structure.** Is there a discernible architecture (layers, modules,
   separation of concerns), or is logic smeared across giant files with UI, data
   access, and business rules intermingled?
3. **Requirements traceability.** Can you tell *why* things exist? Do features map
   to stated goals, or is there dead/speculative code the AI added unprompted?
4. **Consistency.** One way of doing things, or three different HTTP clients, two
   state-management patterns, and mixed paradigms across files — a hallmark of
   prompt-by-prompt generation?
5. **Appropriate complexity.** Over-engineered abstractions that do nothing
   (AI loves factories/managers), *or* dangerously under-designed (everything in
   one 2000-line file)?
6. **Data model sanity.** Is the data model coherent and normalised enough for the
   domain, or ad-hoc JSON blobs and duplicated state?
7. **Boundaries.** Are external integrations (payments, auth, email, LLM APIs)
   isolated behind clear seams, or called inline everywhere?

## Amateur / AI-built red flags

- No design artefacts of any kind; architecture must be inferred entirely.
- "God files" holding routing, business logic, and persistence together.
- Multiple libraries doing the same job (three date libs, two ORMs).
- Copy-pasted near-duplicate modules that drifted apart.
- Abstractions with a single caller, or interfaces implemented once.
- Speculative/dead features never wired up.

## Scoring anchors

- **0–1:** No design; incoherent, inconsistent, accidental architecture.
- **2–3:** A workable structure emerges but with significant inconsistency and no
  written design/decision record.
- **4–5:** Intentional architecture with documented decisions (ADRs), consistent
  patterns, and clean boundaries.
