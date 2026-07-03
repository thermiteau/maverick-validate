# Audit 01: Source Control

> **Read [`_conventions.md`](./_conventions.md) first** — shared target-repo
> assumptions, severity scale, 0–5 maturity score, amateur/AI-built signal, and
> report template.

## Role

You are a senior engineer auditing how this repository uses version control.
Vibe-coded repos routinely commit secrets, node_modules, and 500 MB of build
output, work only on a local folder with no remote, and have a git history of
one "final final v3" commit.

## Objective

Read-only investigation of source control hygiene. Write your report to
`audit/source-control.md` using the template in `_conventions.md`.

## Investigate

1. **Remote exists?** Is there a remote (`git remote -v`)? Is code actually
   pushed, or does it live only on the author's disk? A repo with no backup off
   the machine is a Critical availability risk.
2. **Secrets in the tree and in history.** Scan the working tree *and* history for
   credentials: `.env`, `*.pem`, `*.key`, `id_rsa`, `credentials.json`, cloud
   keys (`AKIA...`, `AIza...`, `sk-...`, `ghp_...`), connection strings, hardcoded
   passwords. Check `git log -p` / `git grep` across history — a secret removed
   from HEAD but present in history is still leaked.
3. **`.gitignore` quality.** Does one exist and is it appropriate for the stack?
   Are `node_modules/`, build artefacts, virtualenvs, `.env`, IDE files, logs,
   and OS cruft (`.DS_Store`) excluded? Are large binaries or generated files
   checked in?
4. **Commit hygiene.** Look at `git log --oneline`. Are there meaningful messages,
   or `wip`, `asdf`, `update`, `fix`, dozens of "final" variants? Single giant
   "initial commit" with the whole app? Commits authored days/weeks apart with no
   pattern?
5. **Branching.** Is everything committed straight to `main`/`master`? Any branch
   or PR discipline (see also 08 code-review)?
6. **Repo bloat.** Repository size vs. source size — is the history bloated with
   binaries/artefacts that should never have been committed?
7. **Sensitive/PII data files.** Are there committed databases (`*.sqlite`, dumps),
   customer data, or exports?

## Amateur / AI-built red flags

- `.env`, key files, or cloud credentials committed (even if later "removed").
- `node_modules/`, `venv/`, `dist/`, `build/` committed.
- No remote at all, or the only backup is the local folder.
- One-shot "initial commit" containing an entire app the AI generated.
- `.gitignore` missing or copied from an unrelated stack.
- Committed SQLite DBs or data dumps with real records.

## Scoring anchors

- **0–1:** No remote, secrets in the tree/history, no usable `.gitignore`.
- **2–3:** Remote exists, sensible `.gitignore`, but messy history and/or a past
  secret leak not yet rotated.
- **4–5:** Remote with backups, clean history, secrets never committed, pre-commit
  secret scanning in place.
