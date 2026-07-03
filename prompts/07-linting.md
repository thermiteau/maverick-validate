# Audit 07: Linting & Formatting

> **Read [`_conventions.md`](./_conventions.md) first** — shared target-repo
> assumptions, severity scale, 0–5 maturity score, amateur/AI-built signal, and
> report template

## Role

You are auditing automated code-quality tooling. Vibe-coded repos usually have no
linter, so dead code, undefined variables, unused imports, and inconsistent style
accumulate unchecked.

## Objective

Read-only investigation of linting/formatting/static analysis. Write your report
to `audit/linting.md` using the template in `_conventions.md`.

## Investigate

1. **Linter configured?** Is there a linter for the stack (ESLint, Ruff/flake8/
   pylint, golangci-lint, clippy, RuboCop) with a real config, not an empty
   default?
2. **Formatter configured?** Prettier, Black, gofmt, rustfmt — and is the code
   actually formatted consistently, or a mix of tabs/spaces and quote styles?
3. **Type checking.** For typed/gradually-typed stacks: is `tsc --noEmit`, `mypy`,
   or equivalent run? Is `strict` on, or is everything `any`?
4. **Run it.** If tooling exists, run it and report the error/warning count. A
   config that exists but yields hundreds of violations is theatre.
5. **CI enforcement.** Is linting/formatting/type-checking enforced in CI or a
   pre-commit hook, or purely optional?
6. **Dead & unreachable code.** Note unused imports/variables/functions,
   commented-out blocks, and unreachable branches the linter would have caught.

## Amateur / AI-built red flags

- No linter or formatter at all.
- A linter config present but with hundreds of unfixed violations (added, never used).
- TypeScript with `any` everywhere or `strict: false`.
- Inconsistent formatting across files (each AI session used a different style).
- Large blocks of commented-out code left in place.

## Scoring anchors

- **0–1:** No linting/formatting/type-checking; inconsistent style; dead code.
- **2–3:** Tooling configured and mostly passing, but not enforced in CI.
- **4–5:** Linter + formatter + type-checker configured, clean, and enforced in
  CI / pre-commit.
