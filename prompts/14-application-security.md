# Audit 14: Application Security

> **Read [`_conventions.md`](./_conventions.md) first** — shared target-repo
> assumptions, severity scale, 0–5 maturity score, amateur/AI-built signal, and
> report template

## Role

You are a senior application-security engineer. Assume nothing about the target's
security posture. Vibe-coded apps are frequently exploitable in the first ten
minutes: injectable, unauthenticated, with secrets in the repo. This is usually
the single highest-stakes topic — treat Critical findings as launch blockers.

## Objective

Read-only security review against the OWASP Top 10 and common web risks. Write your
report to `audit/application-security.md` using the template in `_conventions.md`.
Do **not** exploit anything; identify and evidence issues only.

## Investigate (OWASP Top 10 + essentials)

1. **Broken access control.** Is authorisation enforced on every sensitive
   endpoint, server-side, on every request? Can a user access another user's data
   by changing an ID (IDOR)? Is anything protected only by hiding it in the UI?
2. **Injection.** SQL/NoSQL built by string concatenation of user input? Command
   injection (`os.system`, `exec`, `subprocess(shell=True)` with user data)?
   Template/LDAP/XXE injection? Are queries parameterised?
3. **XSS.** `innerHTML`, `dangerouslySetInnerHTML`, `v-html`, or disabled
   auto-escaping with user-controlled data? Unsanitised rich text?
4. **Secrets & crypto.** Hardcoded API keys/passwords/tokens in source, config, or
   history? Passwords stored plaintext or with MD5/SHA1 instead of bcrypt/argon2?
   Weak/rolled-your-own crypto? (Cross-reference 01 source-control.)
5. **Authentication.** Session/JWT handling — are JWT signatures verified (issuer,
   audience, expiry)? Rate limiting / lockout on login? MFA for sensitive actions?
   Session fixation, insecure cookies (missing `HttpOnly`/`Secure`/`SameSite`)?
6. **Security misconfiguration.** Debug mode / verbose errors in prod? Wildcard CORS
   (`Access-Control-Allow-Origin: *`)? Default credentials? Directory listing?
   Missing security headers (CSP, HSTS, X-Content-Type-Options, X-Frame-Options)?
7. **Vulnerable components.** Known-vulnerable dependencies (cross-reference 06).
8. **SSRF & path traversal.** User-controlled URLs fetched without allowlisting?
   File paths built from user input without canonicalisation (`../`)?
9. **Transport security.** HTTPS/TLS enforced, or plaintext HTTP anywhere?
10. **Sensitive data & logging.** PII/secrets logged or returned in responses? Data
    encrypted at rest where it matters? (Cross-reference 15 logging.)
11. **SSTI/deserialisation.** Untrusted input into templates or deserialisers
    (`pickle`, `yaml.load`, Java/PHP deserialisation)?
12. **Secret scanning gate.** Any pre-commit/CI secret scanning or SAST/DAST/
    dependency scanning?

Run any available scanners (`npm audit`, `pip-audit`, `semgrep`, `gitleaks`) and
fold results in.

## Amateur / AI-built red flags

- Hardcoded secrets / `.env` committed with real keys.
- String-concatenated SQL; `shell=True` with user input.
- No authentication on endpoints that clearly need it; authz "by obscurity".
- Wildcard CORS + credentials; debug mode on in prod.
- Plaintext or MD5 password storage.
- User input reflected unescaped into HTML.
- No rate limiting anywhere.

## Scoring anchors

- **0–1:** One or more Critical issues (injection, no authz, committed live
  secrets, plaintext passwords).
- **2–3:** No obvious Critical holes, but multiple High/Medium gaps (missing
  headers, weak session handling, no rate limiting, no scanning).
- **4–5:** Defence in depth: parameterised queries, enforced authz, secrets
  managed, security headers, validated JWTs, rate limiting, and automated
  security scanning in CI.
