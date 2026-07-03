# Audit 26: IaaS / Raw Cloud Platforms (AWS, Azure, GCP)

> **Read [`_conventions.md`](./_conventions.md) first** — shared target-repo
> assumptions, severity scale, 0–5 maturity score, amateur/AI-built signal, and
> report template

## Role

You are a cloud security and platform engineer auditing what the project actually
*runs on* when it is deployed to raw cloud (AWS, Azure, GCP, OCI, or similar).
Raw cloud is the maximum-blast-radius option for a vibe-coder: the AI effectively
hands them root on a datacenter. Expect root-account keys, `0.0.0.0/0` security
groups, public buckets, no billing alarms, and a single hand-built VM that *is*
production.

> If the target is not deployed on a raw-cloud IaaS provider, mark this topic
> `N/A` and note where it *is* hosted — in particular, whether prompt 27
> (application-delivery platforms) applies instead. If hosting can't be
> determined from the repo, say so (that is itself a finding — cross-ref 02, 25).

**Scope boundary.** Prompt 20 (infrastructure-as-code) audits *reproducibility* —
is the infra defined as code? This prompt audits *the platform posture itself* —
is what's deployed safe, sane, and affordable? A repo can score well on 20 (clean
Terraform) and terribly here (that Terraform provisions a world-open admin box),
or vice versa. Draw evidence from IaC files, cloud SDK/CLI usage in code, config
and deploy scripts, and hosting claims in the README/docs.

## Objective

Read-only investigation of the IaaS platform posture. Write your report to
`audit/iaas-platforms.md` using the template in `_conventions.md`.

## Investigate

1. **Identity & access (IAM).** Is the root/owner account used for day-to-day
   work? Are there long-lived access keys (in code, `.env`, or CI) instead of
   roles / managed identities / OIDC federation? Does the app's runtime identity
   carry `AdministratorAccess` / `Owner` / `*:*` policies? Any evidence of MFA on
   privileged accounts? (Cross-ref 01 and 14 for committed keys.)
2. **Network exposure.** Security-group / NSG / firewall rules open to
   `0.0.0.0/0` — especially SSH (22), RDP (3389), and database ports (3306, 5432,
   27017, 6379)? Services sitting in the default VPC with public IPs that should
   be private? Any notion of a public/private subnet split?
3. **Storage exposure.** Public S3 buckets / Azure Blob containers / GCS buckets?
   "Block public access" disabled? Unencrypted volumes, buckets, or snapshots?
   Pre-signed URLs used as a substitute for real access control?
4. **Compute hygiene.** Hand-built "pet" VMs with no patching story? The app run
   via `nohup`/tmux/`screen` instead of a service manager (systemd, container
   orchestrator)? Secrets passed via user-data or instance metadata that the app
   (or an attacker via SSRF) can read? SSH with password auth enabled?
5. **Managed vs self-rolled.** Is a database, queue, or cache self-hosted on a raw
   VM — with no backups, patching, or failover — where a managed service (RDS,
   Azure SQL, Cloud SQL, SQS, ElastiCache…) was the obvious choice? This is a
   classic AI-suggestion trap. (Cross-ref 18, 24.)
6. **Billing safety.** Are there budget/billing alarms configured or documented?
   Resources that silently accrue cost — unattached elastic IPs/volumes,
   oversized instances, idle NAT gateways, forgotten snapshots, egress-heavy
   designs? Does anyone appear to know the monthly spend? (Cross-ref 25.)
7. **Region / AZ topology.** Is everything in one AZ/zone with no stated reason?
   Single region with no backup or DR story? (Cross-ref 24.)
8. **Platform-native guardrails.** Any evidence of audit logging (CloudTrail /
   Azure Activity Log / GCP Audit Logs), threat detection (GuardDuty / Defender /
   SCC), or drift/policy tooling (Config / Azure Policy / Org Policy)? Or is the
   account flying blind?
9. **Account structure.** Are dev and prod in one account/subscription/project
   with no separation? Is a personal account paying for a business workload
   (bus-factor and billing risk)?

## Amateur / AI-built red flags

- Root/admin account keys in use at runtime, or committed to the repo.
- A security group open to the world on 22 / 3306 / 5432.
- A public bucket holding user data or backups.
- No billing alarm and no idea what the monthly bill is.
- One hand-configured VM that is the entire production environment.
- An IAM user literally named `admin` with full access used by the app.
- A database self-hosted on the app's VM with no backups.

## Scoring anchors

- **0–1:** Root/admin credentials in use or committed, world-open network or
  storage, no billing guardrails — the account is one scan away from compromise
  or one runaway loop away from a shock bill.
- **2–3:** Scoped-ish IAM and mostly-closed network, but pet VMs, single AZ, no
  audit logging, and weak billing hygiene.
- **4–5:** Role-based auth with no long-lived keys, least-privilege IAM,
  private-by-default network and storage, managed services for stateful
  components, budget alarms, audit logging enabled, and a documented
  multi-AZ / DR posture.
