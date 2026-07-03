# Audit 29: Data Privacy & Compliance

> **Read [`_conventions.md`](./_conventions.md) first** — shared target-repo
> assumptions, severity scale, 0–5 maturity score, amateur/AI-built signal, and
> report template

## Role

You are auditing how the project handles personal and sensitive data. Amateur apps
routinely collect PII with no inventory, no consent, no retention policy, and no
way to delete it — a legal and financial risk (GDPR, CCPA, and similar) the author
never considered because the AI was never asked about it.

> If the project handles no personal data at all, mark this topic `N/A` with a
> one-line justification.

**Scope boundary.** Technical protection of data (encryption, access control,
injection) is audited in 14 (security) and 18 (database); this prompt covers the
*privacy and compliance* dimension — what personal data exists, why, whether users
consented, and whether it can be exported and deleted. Cross-reference 14, 15
(logging), 18, and 28 (LLM providers).

## Objective

Read-only investigation of data privacy and compliance. Write your report to
`audit/data-privacy.md` using the template in `_conventions.md`. You are not giving
legal advice — you are flagging obvious gaps a professional would not ship.

## Investigate

1. **PII inventory.** What personal or sensitive data does the app collect and
   store — names, emails, phone, address, location, IP, payment, health,
   government IDs, biometrics? Is it even knowable from the code, or is it
   accreted ad hoc? Build the inventory from models/schemas, forms, and API
   payloads.
2. **Data minimisation.** Is data collected or stored that the app does not
   actually need (over-broad forms, logging full profiles, storing raw payment
   details instead of a processor token)?
3. **Consent & transparency.** Is there a privacy policy? Cookie/tracking consent
   where required? Disclosure of third-party data sharing — analytics, ads, error
   trackers, and LLM/AI providers that receive user content? (Cross-ref 28.)
4. **Retention & deletion.** Is data kept indefinitely by default? Is there a user
   data-export path and a real deletion path (data-subject rights)? Does "delete"
   actually delete, or soft-delete forever while retaining the PII?
5. **Data protection (privacy lens).** Is sensitive data encrypted at rest and
   access-controlled? Does PII leak into logs, analytics events, error-tracker
   payloads, or URLs/query strings? (Cross-ref 14, 15, 18.)
6. **Cross-border & third-party flows.** Is PII sent to external services
   (including LLM providers, offshore infra, or analytics) without apparent
   awareness of where it goes or what those services do with it?
7. **Special categories & minors.** Any handling of health, financial, or
   children's data that carries heightened obligations the author is unlikely to
   have accounted for?

## Amateur / AI-built red flags

- Collects PII (emails, addresses, payment) with no privacy policy anywhere.
- No deletion mechanism — user data can never be removed.
- Full request bodies or user profiles (with PII) written to logs or a
  third-party error tracker.
- Analytics or session-replay capturing PII without consent.
- Raw payment card / government-ID data stored in the app's own database.
- User content forwarded to an LLM provider with no disclosure or opt-out.

## Scoring anchors

- **0–1:** Sensitive PII collected with no policy, consent, or deletion path, and
  leaking into logs or third parties.
- **2–3:** A basic policy and some protection exist, but no retention/deletion
  strategy, no data-subject rights, or unconsented third-party sharing.
- **4–5:** Documented PII inventory with minimisation, clear consent and
  disclosure, retention limits plus working export/deletion, PII kept out of logs,
  and controlled, disclosed cross-border/third-party flows.
