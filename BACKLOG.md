# Backlog — Deferred Suite Enhancements

Durable record of enhancements considered for the suite. When you add a **new**
deferred idea, scope it enough here to pick up later without re-deriving it. When
you implement one, move it to "Implemented" and follow the wiring rules in
[`CLAUDE.md`](./CLAUDE.md) (add to the README table, the orchestrator groups/range,
and inter-prompt cross-references; the driver scripts pick up new
`prompts/NN-*.md` automatically). Run `./check-suite.sh` (or `check-suite.ps1`)
after wiring to confirm the invariants still hold.

## Pending

_None currently._

## Implemented

- **28 LLM / AI integration** → `prompts/28-llm-integration.md`.
- **29 Data privacy & compliance** → `prompts/29-data-privacy.md`.
- **Suite self-consistency checker** → `check-suite.sh` + `check-suite.ps1`.
