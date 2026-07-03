# Audit 27: Application-Delivery Platforms (Vercel, Netlify, Replit, Railway, Render, Fly.io, Heroku, Cloudflare)

> **Read [`_conventions.md`](./_conventions.md) first** — shared target-repo
> assumptions, severity scale, 0–5 maturity score, amateur/AI-built signal, and
> report template

## Role

You are a platform engineer auditing how well the code fits the
application-delivery platform it is deployed on (Vercel, Netlify, Replit,
Railway, Render, Fly.io, Heroku, Cloudflare Pages/Workers, and similar). Unlike
raw cloud, these platforms absorb most of the ops burden — so IaaS-style findings
mostly don't apply. Instead they impose **invisible constraints the vibe-coder
never read**: execution-time limits, ephemeral filesystems,
connection-per-invocation databases, dashboard-only config, and usage-based
billing with no cap. Code that "works" locally silently violates them in
production.

> If the target is not deployed on an application-delivery platform, mark this
> topic `N/A` and note whether prompt 26 (raw-cloud IaaS) applies instead. If the
> hosting is *unknown* from the repo, that itself is a finding (cross-ref 02, 25)
> — say where the evidence ran out.

**Scope boundary.** This prompt audits the *fit between the code and the
platform's execution model*, plus platform-account hygiene. Generic scalability
and cost questions live in 23 and 25; here we cover their platform-specific
manifestations (e.g. an ephemeral filesystem eating a SQLite database, or
usage-based billing with no cap).

## Objective

Read-only investigation of application-delivery-platform fit. Write your report
to `audit/application-delivery-platforms.md` using the template in
`_conventions.md`.

## Investigate

1. **Identify the platform and runtime model.** Look for config files
   (`vercel.json`, `netlify.toml`, `fly.toml`, `render.yaml`,
   `railway.{json,toml}`, `Procfile`, `wrangler.{toml,jsonc}`, `.replit`),
   framework adapters, and hosting claims in docs. Is the runtime serverless
   functions, an edge runtime, a container, or a long-lived process? Every check
   below is judged against that model.
2. **Execution-model violations.** Long-running work (LLM calls, video/report
   generation, large uploads) inside a request handler on a platform with
   10–60 s function timeouts? Reliance on in-memory state across invocations
   (sessions, caches, rate-limit counters) when instances are ephemeral and run
   in parallel? Background `setInterval`/threads that die when the invocation
   ends? (Cross-ref 23.)
3. **Ephemeral filesystem traps.** SQLite databases or user uploads written to
   the local disk on a platform that wipes it per deploy or per invocation —
   silent data loss. Is persistent state externalised to a managed DB or object
   storage? (Cross-ref 18.)
4. **Database connections from serverless.** A new DB connection opened per
   invocation with no pooling proxy (pgBouncer, Neon/Supabase pooler, an HTTP
   Data API, Prisma Accelerate) — connection exhaustion under even modest load.
5. **Config & secrets locus.** Env vars set only in the platform dashboard: are
   they documented (`.env.example`) and reproducible (IaC / CLI-config / written
   down anywhere)? (Cross-ref 05, 20.) And the classic leak: secrets exposed to
   the browser via `NEXT_PUBLIC_` / `VITE_` / `REACT_APP_` prefixes — inspect
   every public-prefixed variable for values that must stay server-side.
6. **Preview / branch-deployment exposure.** Do preview deploys receive
   production env vars and hit real data? Are preview URLs unauthenticated and
   indexable? Is the `*.vercel.app` / `*.netlify.app` / `*.repl.co` URL itself the
   "production" URL with no custom domain?
7. **Build-time vs runtime confusion.** Values baked in at build (client bundles,
   SSG output) that the author believes can be changed per environment? The same
   build promoted across environments carrying wrong assumptions?
8. **Scheduled & background work.** Does the design need cron or queues, and does
   it use the platform's mechanism (Vercel Cron, platform workers/queues) — or
   nothing, or an in-process scheduler that can't survive the runtime model? On
   free tiers that sleep (Replit, Render free), does anything assume the app is
   always awake?
9. **Billing exposure.** Usage-based pricing with no spend cap or notification?
   Uncapped invocation sources (public endpoints calling paid APIs, image
   optimisation, bandwidth)? Free-tier limits the app will hit at first real
   traffic — and what fails when it does? (Cross-ref 25.)
10. **Platform-account hygiene.** Deploys tied to one personal account with no
    team/org? Deploy tokens committed to the repo? Could anyone but the author
    restore service if they were unavailable?
11. **Lock-in awareness.** Heavy use of platform-proprietary APIs without the
    author appearing to understand the coupling. (Info-level unless it blocks a
    stated goal such as portability.)

## Amateur / AI-built red flags

- A SQLite file on an ephemeral filesystem as the primary datastore.
- `NEXT_PUBLIC_OPENAI_API_KEY` (or any secret) exposed in the client bundle.
- A multi-minute LLM job inside a 10-second serverless function.
- Env vars that exist only in the dashboard with no record anywhere in the repo.
- Preview deployments running against the production database.
- Free-tier sleep "fixed" with an external cron pinger.
- No spend limit on a usage-billed account.

## Scoring anchors

- **0–1:** Code violates the platform's execution model — data written to
  ephemeral disk, long jobs in short functions, secrets in the client bundle —
  so it is broken or leaking in production right now.
- **2–3:** Runs within the model, but config is dashboard-only and undocumented,
  previews are exposed, connections are unpooled, and billing is uncapped.
- **4–5:** Architecture matches the runtime model, state is externalised,
  connections are pooled, platform config is documented and reproducible,
  previews are protected, spend caps/alerts exist, and the account is org-owned.
