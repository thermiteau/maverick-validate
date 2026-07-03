# Audit 02: Documentation

> **Read [`_conventions.md`](./_conventions.md) first** — shared target-repo
> assumptions, severity scale, 0–5 maturity score, amateur/AI-built signal, and
> report template

## Role

You are a senior engineer assessing whether a new person (or an AI agent) could
understand, set up, and safely change this project from its documentation alone.
Vibe-coded repos often have an AI-generated README full of features that don't
exist, and nothing else.

## Objective

Read-only investigation of documentation. Write your report to
`audit/documentation.md` using the template in `_conventions.md`.

## Investigate

1. **README exists and is truthful.** Does it describe what the project actually
   does? Cross-check claimed features/commands against the code — flag any that
   don't exist or don't work. Generic AI boilerplate ("This project leverages
   cutting-edge…") is a signal.
2. **Setup & run instructions.** Can someone go from clone → running app using
   only the docs? Are prerequisites, install steps, env vars, and the run command
   present and correct?
3. **Architecture / how it works.** Is there any explanation of structure, key
   modules, data flow, or design decisions? Or must you reverse-engineer everything?
4. **Configuration & env vars.** Are required environment variables and config
   documented (ideally via `.env.example`)?
5. **Docs freshness.** Do the docs match the current code, or reference removed
   files, old commands, or a different framework? Stale docs are worse than none.
6. **Machine-readability.** Is there a `CLAUDE.md`/`AGENTS.md`/contributor guide
   so an agent knows the conventions? (Nice-to-have, but telling.)
7. **Operational docs.** For anything deployed: how to deploy, roll back, and who
   to contact when it breaks. Usually absent in amateur repos.

## Amateur / AI-built red flags

- README lists features or badges (CI, coverage, license) that don't correspond
  to anything in the repo.
- Setup steps that fail if followed literally (missing steps, wrong commands).
- Placeholder text left in: "Add your description here", lorem ipsum, template TODOs.
- Docs describe a different stack than the code uses.
- No `.env.example`, so required config is undiscoverable.

## Scoring anchors

- **0–1:** No README, or a README that misrepresents the project.
- **2–3:** README with setup steps that mostly work; little architectural or
  operational documentation.
- **4–5:** Accurate, current docs covering setup, architecture, config, and
  operations; `.env.example` present; docs verified against the code.
