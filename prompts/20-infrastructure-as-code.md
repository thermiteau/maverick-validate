# Audit 20: Infrastructure as Code

> **Read [`_conventions.md`](./_conventions.md) first** — shared target-repo
> assumptions, severity scale, 0–5 maturity score, amateur/AI-built signal, and
> report template

## Role

You are auditing whether the infrastructure is reproducible from code, or was
click-assembled in a web console and exists only as tribal knowledge. Amateur
projects can't recreate their environment if it's lost.

> If the project isn't deployed to any infrastructure, mark this topic `N/A` with
> a note about what would be needed to deploy it.

This prompt covers infrastructure-as-code *reproducibility*. The safety and
sanity of the deployment platform itself is covered separately: prompt 26 for
raw-cloud IaaS (AWS/Azure/GCP), prompt 27 for application-delivery platforms
(Vercel/Replit/etc.).

## Objective

Read-only investigation of infrastructure-as-code. Write your report to
`audit/infrastructure-as-code.md` using the template in `_conventions.md`.

## Investigate

1. **IaC exists?** Is infrastructure defined as code (Terraform, Pulumi,
   CloudFormation, CDK, Ansible, `wrangler.toml`, `fly.toml`, Helm/k8s manifests,
   `docker-compose` for deploy)? Or is deployment undocumented click-ops?
2. **Reproducibility.** Could the whole environment be recreated from the repo in a
   new account/region, or would knowledge be lost with the author?
3. **Environment parity.** Are dev/staging/prod defined consistently from the same
   code with per-env variables? (Ties to 05.)
4. **Secrets in IaC.** Are secrets injected securely (secret manager, CI variables)
   or hardcoded in IaC files / committed state?
5. **State management.** For Terraform-like tools: is state stored remotely and
   locked, or is `terraform.tfstate` (which can contain secrets) committed to git?
6. **Runbook fallback.** If the platform isn't IaC-friendly (e.g. a PaaS console),
   is there at least a written runbook for provisioning and recovery?
7. **Networking/security posture.** Are things like open security groups
   (`0.0.0.0/0`), public buckets, or over-broad IAM visible in the config?

## Amateur / AI-built red flags

- No IaC; infrastructure built by hand in a console, undocumented.
- Secrets or `terraform.tfstate` committed to the repo.
- Wide-open security groups / public storage buckets in config.
- A single environment that is also production.

## Scoring anchors

- **0–1:** No IaC and no runbook; environment is unreproducible click-ops.
- **2–3:** Some IaC or a runbook, but incomplete, single-environment, or with
  insecure/hardcoded values.
- **4–5:** Full IaC with remote/locked state, per-environment parity, secure
  secret injection, and least-privilege networking.
