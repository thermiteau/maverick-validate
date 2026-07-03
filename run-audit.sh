#!/usr/bin/env bash
#
# run-audit.sh — drive the full AI Code Sanity Check suite over a target repo.
#
# PLATFORMS: Linux and macOS. The shebang runs this under bash even when your
#   login shell is zsh (the macOS default), so invoke it as ./run-audit.sh — not
#   `zsh run-audit.sh`. It stays compatible with macOS's system bash 3.2.
#   On Windows, use run-audit.ps1 instead (identical behaviour, PowerShell).
#
# WHY THIS EXISTS
#   The audit is 27 heavy topic prompts. If one agent tries to run them all in a
#   single session it will exhaust its context window and silently skip, truncate,
#   or shallow-do topics. This driver removes that failure mode structurally:
#
#     1. ISOLATION  — each topic prompt runs in its OWN fresh agent process, so
#                     context spent on topic N can never starve topic N+1.
#     2. PROOF      — a topic counts as done only when its audit/<slug>.md report
#                     actually exists and looks valid. The filesystem is the
#                     ledger, not the model's memory.
#     3. LOUD FAIL  — if any expected report is missing at the end, the script
#                     exits non-zero and names the gaps. "Complete" is verified,
#                     never assumed.
#     4. RESUMABLE  — re-running skips topics already produced, so a crash or a
#                     rate-limit halfway through never forces a full redo.
#
# USAGE
#   ./run-audit.sh --target /path/to/repo/under/audit [options]
#
#   Options:
#     --target DIR     Repo to audit (required). Reports land in DIR/audit/.
#     --agent NAME     claude | codex | custom            (default: claude)
#     --only "14 23"   Space-separated topic numbers to run (default: all)
#     --retries N      Attempts per topic before giving up (default: 2)
#     --force          Re-run topics even if a report already exists
#     --no-scorecard   Skip the final aggregated SCORECARD.md step
#     --dry-run        Print the plan and exit without invoking any agent
#     -h | --help      Show this help
#
#   The agent command is defined in run_agent() below — the ONE place to edit if
#   your CLI/version needs different flags. AUDIT_CMD=... --agent custom lets you
#   plug in any tool that reads the prompt on stdin.
#
set -euo pipefail

# --------------------------------------------------------------------------- #
# Resolve where the suite lives (this script's own directory), independent of cwd
# --------------------------------------------------------------------------- #
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
PROMPTS_DIR="$SCRIPT_DIR/prompts"
CONVENTIONS="$PROMPTS_DIR/_conventions.md"

# --------------------------------------------------------------------------- #
# Defaults & argument parsing
# --------------------------------------------------------------------------- #
TARGET=""
AGENT="claude"
ONLY=""
RETRIES=2
FORCE=0
SCORECARD=1
DRY_RUN=0

die() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }

while [ $# -gt 0 ]; do
  case "$1" in
    --target)       TARGET="${2:-}"; shift 2 ;;
    --agent)        AGENT="${2:-}"; shift 2 ;;
    --only)         ONLY="${2:-}"; shift 2 ;;
    --retries)      RETRIES="${2:-}"; shift 2 ;;
    --force)        FORCE=1; shift ;;
    --no-scorecard) SCORECARD=0; shift ;;
    --dry-run)      DRY_RUN=1; shift ;;
    -h|--help)      sed -n '2,45p' "$0"; exit 0 ;;
    *)              die "unknown argument: $1 (try --help)" ;;
  esac
done

[ -n "$TARGET" ]        || die "--target is required (the repo to audit). Try --help."
[ -d "$TARGET" ]        || die "--target '$TARGET' is not a directory."
[ -d "$PROMPTS_DIR" ]   || die "prompts/ not found next to this script ($PROMPTS_DIR)."
[ -f "$CONVENTIONS" ]   || die "prompts/_conventions.md not found."
[[ "$RETRIES" =~ ^[0-9]+$ ]] || die "--retries must be a number."

TARGET="$(cd -- "$TARGET" && pwd)"      # absolutise
AUDIT_DIR="$TARGET/audit"
LEDGER="$AUDIT_DIR/.run-audit.log"

# --------------------------------------------------------------------------- #
# THE agent invocation. Edit here if your CLI needs different flags.
# Contract: read the full prompt on STDIN, run non-interactively in $PWD
# (which the caller sets to $TARGET), and be allowed to read the repo + write
# files under audit/. Return non-zero on hard failure.
# --------------------------------------------------------------------------- #
run_agent() {
  # stdin = the composed prompt; cwd = $TARGET (set by caller)
  case "$AGENT" in
    claude)
      # Headless "print" mode. --permission-mode acceptEdits lets it write the
      # report; for fully unattended runs on locked-down machines you may need
      # --dangerously-skip-permissions instead (audits run read-only shell like
      # `git log`, `grep`, `npm audit`).
      claude -p --permission-mode acceptEdits ;;
    codex)
      # Codex headless. --full-auto enables workspace-write + no prompts.
      codex exec --full-auto - ;;
    custom)
      [ -n "${AUDIT_CMD:-}" ] || die "--agent custom requires AUDIT_CMD env var."
      eval "$AUDIT_CMD" ;;
    *)
      die "unknown --agent '$AGENT' (claude | codex | custom)." ;;
  esac
}

# --------------------------------------------------------------------------- #
# Build the topic list: every prompts/NN-*.md except the orchestrator.
# Mapping is deterministic: NN-<slug>.md  ->  audit/<slug>.md
# --------------------------------------------------------------------------- #
declare -a NUMS=() SLUGS=() FILES=()
while IFS= read -r f; do
  base="$(basename "$f")"
  [ "$base" = "00-orchestrator.md" ] && continue
  num="${base%%-*}"
  slug="${base#[0-9][0-9]-}"; slug="${slug%.md}"
  NUMS+=("$num"); SLUGS+=("$slug"); FILES+=("$f")
done < <(find "$PROMPTS_DIR" -maxdepth 1 -name '[0-9][0-9]-*.md' | sort)

[ "${#FILES[@]}" -gt 0 ] || die "no topic prompts found in $PROMPTS_DIR."

# Optional subset filter
selected() {
  local n="$1"
  [ -z "$ONLY" ] && return 0
  local want
  for want in $ONLY; do
    # accept "7" or "07"
    [ "$((10#$n))" -eq "$((10#$want))" ] && return 0
  done
  return 1
}

# A report is "valid" if it exists, is non-trivially sized, and carries the
# Score line from the report template (present even for N/A verdicts).
report_valid() {
  local path="$1"
  [ -f "$path" ] || return 1
  [ "$(wc -c < "$path")" -ge 200 ] || return 1
  grep -qE '\*\*Score:\*\*' "$path" || return 1
  return 0
}

# --------------------------------------------------------------------------- #
# Plan / dry-run
# --------------------------------------------------------------------------- #
echo   "AI Code Sanity Check — full-suite driver"
echo   "  suite     : $PROMPTS_DIR"
echo   "  target    : $TARGET"
echo   "  agent     : $AGENT"
echo   "  reports   : $AUDIT_DIR/<topic>.md"
[ -n "$ONLY" ] && echo "  subset    : $ONLY"
echo   "  topics    : ${#FILES[@]} available"
echo

if [ "$DRY_RUN" -eq 1 ]; then
  echo "DRY RUN — planned actions:"
  for i in "${!FILES[@]}"; do
    selected "${NUMS[$i]}" || continue
    out="$AUDIT_DIR/${SLUGS[$i]}.md"
    if [ "$FORCE" -eq 0 ] && report_valid "$out"; then
      printf '  [skip ] %s (report already valid)\n' "${SLUGS[$i]}"
    else
      printf '  [run  ] %s -> audit/%s.md\n' "${SLUGS[$i]}" "${SLUGS[$i]}"
    fi
  done
  exit 0
fi

mkdir -p "$AUDIT_DIR"
: > "$LEDGER"
log() { printf '%s\n' "$*" | tee -a "$LEDGER"; }

# --------------------------------------------------------------------------- #
# Run each selected topic in its own fresh agent process
# --------------------------------------------------------------------------- #
declare -a DONE=() SKIPPED=() FAILED=()
CONV_TEXT="$(cat "$CONVENTIONS")"

for i in "${!FILES[@]}"; do
  num="${NUMS[$i]}"; slug="${SLUGS[$i]}"; file="${FILES[$i]}"
  selected "$num" || continue
  out="$AUDIT_DIR/$slug.md"

  if [ "$FORCE" -eq 0 ] && report_valid "$out"; then
    log "[$num] $slug — SKIP (valid report exists; use --force to redo)"
    SKIPPED+=("$slug"); continue
  fi

  attempt=1; ok=0
  while [ "$attempt" -le "$RETRIES" ]; do
    log "[$num] $slug — running (attempt $attempt/$RETRIES)…"

    # Compose a fully self-contained prompt: driver preamble + shared
    # conventions + the topic prompt. No inter-file reads required, so each
    # process is hermetic.
    msg="$(cat <<EOF
You are running ONE topic of the AI Code Sanity Check audit against the
repository in your current working directory ($TARGET).

Rules for this run:
- This is a READ-ONLY audit of the code. The ONLY file you may create or modify
  is \`audit/$slug.md\` (create the \`audit/\` directory if needed).
- Do NOT attempt any other audit topic. Do exactly this one and then stop.
- Follow the shared conventions and the topic prompt below. Even if the topic is
  Not Applicable to this repo, you must still WRITE \`audit/$slug.md\` stating
  N/A and why — an absent file is treated as a failed run.

===== SHARED CONVENTIONS (_conventions.md) =====
$CONV_TEXT

===== TOPIC PROMPT ($(basename "$file")) =====
$(cat "$file")
EOF
)"

    # Proof over exit code: the report file is the source of truth. Accept the
    # attempt if a valid report exists, whatever the CLI's exit status.
    rc=0
    (cd "$TARGET" && printf '%s' "$msg" | run_agent) >>"$LEDGER" 2>&1 || rc=$?
    if report_valid "$out"; then ok=1; break; fi
    log "[$num] $slug — attempt $attempt produced no valid report (agent rc=$rc)."
    attempt=$((attempt + 1))
  done

  if [ "$ok" -eq 1 ]; then
    log "[$num] $slug — DONE (audit/$slug.md)"
    DONE+=("$slug")
  else
    log "[$num] $slug — FAILED after $RETRIES attempt(s)."
    FAILED+=("$slug")
  fi
done

# --------------------------------------------------------------------------- #
# Completeness gate — the whole point of this script
# --------------------------------------------------------------------------- #
echo
echo "===================== RUN SUMMARY ====================="
printf '  done    : %s\n' "${#DONE[@]}"
printf '  skipped : %s (already valid)\n' "${#SKIPPED[@]}"
printf '  failed  : %s\n' "${#FAILED[@]}"

# Verify EVERY selected topic now has a valid report, regardless of how it got
# there (done this run, or skipped because already present).
declare -a MISSING=()
for i in "${!FILES[@]}"; do
  selected "${NUMS[$i]}" || continue
  report_valid "$AUDIT_DIR/${SLUGS[$i]}.md" || MISSING+=("${SLUGS[$i]}")
done

if [ "${#MISSING[@]}" -gt 0 ]; then
  echo
  echo "INCOMPLETE — no report produced for:"
  for m in "${MISSING[@]}"; do echo "  - $m"; done
  echo "Re-run to fill the gaps (existing reports are kept): $0 --target \"$TARGET\""
  exit 1
fi

echo "  ALL SELECTED TOPICS HAVE A VALID REPORT ✅"

# --------------------------------------------------------------------------- #
# Optional: aggregate into SCORECARD.md (safe — it only reads the short reports)
# --------------------------------------------------------------------------- #
if [ "$SCORECARD" -eq 1 ] && [ -z "$ONLY" ]; then
  echo
  echo "Aggregating audit/SCORECARD.md …"
  agg="$(cat <<EOF
Every per-topic report has been written under \`audit/\` in your current working
directory. Read all of \`audit/*.md\` (they are short) and aggregate them into
\`audit/SCORECARD.md\` following the "Aggregate into audit/SCORECARD.md" section
of the orchestrator prompt below. Write ONLY \`audit/SCORECARD.md\`. Do not
re-run any topic audit.

===== ORCHESTRATOR (aggregation spec) =====
$(cat "$PROMPTS_DIR/00-orchestrator.md")
EOF
)"
  if (cd "$TARGET" && printf '%s' "$agg" | run_agent) >>"$LEDGER" 2>&1 \
       && [ -f "$AUDIT_DIR/SCORECARD.md" ]; then
    echo "  SCORECARD.md written ✅"
  else
    echo "  SCORECARD.md step did not complete — topic reports are still valid."
    echo "  You can retry aggregation, or build the scorecard by hand from audit/*.md."
    exit 1
  fi
fi

echo
echo "Done. Reports: $AUDIT_DIR/   (run log: $LEDGER)"
