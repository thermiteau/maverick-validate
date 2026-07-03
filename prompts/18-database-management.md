# Audit 18: Database & Data Management

> **Read [`_conventions.md`](./_conventions.md) first** — shared target-repo
> assumptions, severity scale, 0–5 maturity score, amateur/AI-built signal, and
> report template

## Role

You are auditing how the system stores and protects data. Amateur apps commonly
have no migrations (schema edited by hand), no backups (one disk failure from
total data loss), and no connection pooling.

> If the project uses no database or persistent store, mark this topic `N/A`.

## Objective

Read-only investigation of database/data management. Write your report to
`audit/database-management.md` using the template in `_conventions.md`.

## Investigate

1. **Schema migrations.** Is there a migration tool/history (Alembic, Prisma
   Migrate, Flyway, Liquibase, Rails/Django migrations), or is the schema created
   ad hoc / edited by hand with no version history?
2. **Backups & recovery.** Is there any backup strategy? Could the author restore
   after a crash/deletion? (For a committed SQLite file, the "backup" may be git —
   note the risk.) Has recovery ever been tested?
3. **Connection management.** Is there connection pooling, or a new connection per
   request (exhaustion under load)? Are connections closed on all paths?
4. **Indexing & query health.** Are there indexes on columns used in
   filters/joins? Any obvious N+1 query patterns or full-table scans? (Ties to 23
   scalability.)
5. **Data integrity.** Are constraints (FKs, NOT NULL, UNIQUE) used, or is
   integrity "enforced" only in application code (or not at all)?
6. **Transactions.** Are multi-step writes wrapped in transactions, or can partial
   failures leave inconsistent data?
7. **Sensitive data.** Is sensitive data encrypted at rest / access-controlled?
   Is PII minimised? (Cross-reference 14 security.)
8. **Data lifecycle.** Any retention/deletion strategy, or does data accumulate
   forever?

## Amateur / AI-built red flags

- No migrations; schema changes made by editing the DB directly.
- No backups; a single SQLite file (possibly committed to git) as the only copy.
- A fresh DB connection opened per request with no pool.
- No indexes on filtered/joined columns; N+1 queries.
- Multi-step writes with no transaction.
- Secrets/PII stored in plaintext.

## Scoring anchors

- **0–1:** No migrations and no backups; data loss is one mistake away.
- **2–3:** Migrations exist and basic integrity is enforced, but no tested backups,
  no pooling, or missing indexes.
- **4–5:** Versioned migrations, tested backups/restore, pooling, sound indexing,
  transactions, and protected sensitive data.
