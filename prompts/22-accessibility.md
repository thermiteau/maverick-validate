# Audit 22: Accessibility

> **Read [`_conventions.md`](./_conventions.md) first** — shared target-repo
> assumptions, severity scale, 0–5 maturity score, amateur/AI-built signal, and
> report template

## Role

You are auditing accessibility (WCAG 2.1 AA) for any user-facing interface.
AI-generated UIs look fine but are often unusable with a keyboard or screen
reader: div-soup, no labels, poor contrast, no focus management.

> If there is no user-facing UI (headless service, CLI, library), mark this topic
> `N/A` with a one-line justification and move on.

## Objective

Read-only investigation of accessibility. Write your report to
`audit/accessibility.md` using the template in `_conventions.md`.

## Investigate

1. **Semantic HTML.** Are native elements (`button`, `a`, `nav`, `main`, headings,
   lists, `label`) used, or is everything `div`/`span` with click handlers?
2. **Keyboard operability.** Can all interactive elements be reached and operated
   with the keyboard? Is there a visible focus indicator? Any keyboard traps?
3. **Forms & labels.** Do inputs have associated `<label>`s? Are errors announced
   and programmatically associated with fields?
4. **Images & media.** Do images have meaningful `alt` text? Do icon-only buttons
   have accessible names (`aria-label`)?
5. **Colour & contrast.** Is text contrast likely to meet 4.5:1? Is colour the only
   means of conveying information anywhere?
6. **ARIA correctness.** Where ARIA is used, is it correct, or misused in ways that
   make things worse than no ARIA?
7. **Dynamic content.** Are dynamic updates/modals announced (live regions), and is
   focus managed when dialogs open/close?
8. **Automated checks.** Is any a11y linting/testing present (eslint-plugin-jsx-a11y,
   axe, Lighthouse)? Run one if feasible and fold in results.

## Amateur / AI-built red flags

- Clickable `div`s instead of buttons/links; no keyboard support.
- Inputs with no labels; placeholder used as the only label.
- Images with missing or junk `alt`; icon buttons with no accessible name.
- No focus styles (often `outline: none` with nothing replacing it).
- No a11y tooling of any kind.

## Scoring anchors

- **0–1:** Div-soup UI, keyboard-inoperable, unlabelled, no a11y tooling.
- **2–3:** Mostly semantic HTML and labels, but gaps in keyboard/focus/contrast and
  no automated checks.
- **4–5:** Semantic, keyboard-operable, labelled, sufficient contrast, correct
  ARIA, with automated a11y checks in CI.
