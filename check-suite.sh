#!/usr/bin/env bash
#
# check-suite.sh — verify the audit-prompt suite's own invariants.
#
# This guards the mechanical rules that otherwise rely on reviewer discipline
# (see CLAUDE.md). Run it after adding, removing, renumbering, or editing a
# prompt. It exits non-zero and lists every violation; zero means the suite is
# internally consistent.
#
# Checks:
#   A. Numbering is contiguous 01..N with no gaps or duplicates.
#   B. Every prompt file is linked from README.md.
#   C. Every topic prompt appears in an orchestrator theme group.
#   D. Every ./... link in README.md resolves on disk.
#   E. The orchestrator range line's high number equals the highest topic.
#   F. Each topic prompt has the invariant sections, in order.
#   G. Each topic's declared audit/<slug>.md output equals its filename slug.
#
# PLATFORMS: Linux and macOS (bash via shebang; runs under a zsh login shell).
#   On Windows use check-suite.ps1.
#
set -uo pipefail   # deliberately NOT -e: this script runs greps that may no-match

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
PROMPTS_DIR="$SCRIPT_DIR/prompts"
README="$SCRIPT_DIR/README.md"
ORCH="$PROMPTS_DIR/00-orchestrator.md"

[ -d "$PROMPTS_DIR" ] || { echo "ERROR: prompts/ not found ($PROMPTS_DIR)"; exit 2; }
[ -f "$README" ]      || { echo "ERROR: README.md not found ($README)"; exit 2; }
[ -f "$ORCH" ]        || { echo "ERROR: 00-orchestrator.md not found ($ORCH)"; exit 2; }

fails=0
err()  { printf '  FAIL  %s\n' "$*"; fails=$((fails + 1)); }
pass() { printf '  ok    %s\n' "$*"; }

# The invariant section sequence every topic prompt must contain, in order.
REQUIRED_SECTIONS=(
  "## Role"
  "## Objective"
  "## Investigate"
  "## Amateur / AI-built red flags"
  "## Scoring anchors"
)

# Collect topic prompts (NN-*.md, excluding the orchestrator).
declare -a NUMS=() SLUGS=() FILES=()
while IFS= read -r f; do
  base="$(basename "$f")"
  [ "$base" = "00-orchestrator.md" ] && continue
  NUMS+=("${base%%-*}")
  slug="${base#[0-9][0-9]-}"; SLUGS+=("${slug%.md}")
  FILES+=("$f")
done < <(find "$PROMPTS_DIR" -maxdepth 1 -name '[0-9][0-9]-*.md' | sort)

count="${#FILES[@]}"
[ "$count" -gt 0 ] || { echo "ERROR: no topic prompts found."; exit 2; }

# first matching line number of a fixed string, or empty
line_of() { grep -nF -m1 -- "$2" "$1" 2>/dev/null | cut -d: -f1; }

echo "Checking $count topic prompts in $PROMPTS_DIR"
echo

# ---- A. contiguous numbering -------------------------------------------------
echo "A. Numbering contiguous 01..$(printf '%02d' "$count")"
expected=1
for n in "${NUMS[@]}"; do
  want="$(printf '%02d' "$expected")"
  [ "$n" = "$want" ] || err "numbering gap/dup near $n (expected $want)"
  expected=$((expected + 1))
done
[ "$fails" -eq 0 ] && pass "01..$(printf '%02d' "$count") present, no gaps"

# ---- B/C/F/G. per-topic checks ----------------------------------------------
echo "B/C/F/G. Per-topic (README link, orchestrator group, sections, slug map)"
for i in "${!FILES[@]}"; do
  f="${FILES[$i]}"; num="${NUMS[$i]}"; slug="${SLUGS[$i]}"; base="$(basename "$f")"

  # B: linked from README
  grep -qF "](./prompts/$base)" "$README" || err "$base — not linked from README table"

  # C: appears in an orchestrator theme group as "NN slug"
  grep -qF -- "$num $slug" "$ORCH" || err "$base — not in any orchestrator theme group ('$num $slug')"

  # F: header + sections present and in order
  head -1 "$f" | grep -qE "^# Audit 0*$((10#$num)):" || err "$base — title is not '# Audit $num: …'"
  head -8 "$f" | grep -qF '_conventions.md' || err "$base — header block does not reference _conventions.md"
  prev=0
  for sec in "${REQUIRED_SECTIONS[@]}"; do
    ln="$(line_of "$f" "$sec")"
    if [ -z "$ln" ]; then
      err "$base — missing section '$sec'"
    elif [ "$ln" -le "$prev" ]; then
      err "$base — section '$sec' is out of order"
    else
      prev="$ln"
    fi
  done

  # G: declared output slug == filename slug
  declared="$(grep -oE 'audit/[a-z0-9-]+\.md' "$f" | head -1)"
  if [ "$declared" != "audit/$slug.md" ]; then
    err "$base — declares '$declared' but filename slug is '$slug' (driver mapping breaks)"
  fi
done

# ---- B (reverse). 00 + _conventions are linked too --------------------------
for special in 00-orchestrator.md _conventions.md; do
  grep -qF "](./prompts/$special)" "$README" || err "$special — not linked from README"
done

# ---- D. every README relative link resolves ---------------------------------
echo "D. README relative links resolve"
d_fail_before="$fails"
while IFS= read -r rel; do
  # strip any #anchor
  target="${rel%%#*}"
  [ -e "$SCRIPT_DIR/$target" ] || err "README link does not resolve: $rel"
done < <(grep -oE '\]\(\./[^)]+\)' "$README" | sed -E 's/^\]\(\.\/(.*)\)$/\1/')
[ "$fails" -eq "$d_fail_before" ] && pass "all ./ links resolve"

# ---- E. orchestrator range high number == max topic -------------------------
echo "E. Orchestrator range line"
range_hi="$(grep -oE 'prompts/[0-9]{2}-\*\.md' "$ORCH" | tail -1 | grep -oE '[0-9]{2}')"
max_num="${NUMS[$((count - 1))]}"
if [ "$range_hi" = "$max_num" ]; then
  pass "range ends at $range_hi (matches highest topic)"
else
  err "range line ends at '${range_hi:-?}' but highest topic is '$max_num'"
fi

# ---- summary ----------------------------------------------------------------
echo
if [ "$fails" -eq 0 ]; then
  echo "SUITE OK — all invariants hold ($count topics)."
  exit 0
else
  echo "SUITE INCONSISTENT — $fails violation(s) above."
  exit 1
fi
