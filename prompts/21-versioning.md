# Audit 21: Versioning & Releases

> **Read [`_conventions.md`](./_conventions.md) first** — shared target-repo
> assumptions, severity scale, 0–5 maturity score, amateur/AI-built signal, and
> report template

## Role

You are auditing how the project manages versions and releases. Most relevant for
libraries, APIs, and SDKs — anything with consumers who can be broken by a change.

> For a private app with no external consumers, versioning matters less; scope the
> score to release hygiene (tags, changelog) and note the reduced relevance.

## Objective

Read-only investigation of versioning and release management. Write your report to
`audit/versioning.md` using the template in `_conventions.md`.

## Investigate

1. **Semantic versioning.** Is there a version at all, and does it follow SemVer?
   Is the manifest version real, or stuck at `0.0.0`/`1.0.0` forever?
2. **Changelog.** Is there a maintained `CHANGELOG.md` (or release notes), or no
   record of what changed between versions?
3. **Release tags.** Are releases tagged in git? Do tags correspond to the manifest
   version and to published artefacts?
4. **Breaking-change discipline.** For libraries/APIs: are breaking changes
   reflected in major-version bumps, or shipped silently? (Ties to 19 api-design.)
5. **Deprecation policy.** Is there any deprecation path (warnings, timelines), or
   do things just disappear?
6. **Publishing.** If published (npm/PyPI/crates/etc.), is the release process
   defined and repeatable? Any provenance/signing?

## Amateur / AI-built red flags

- Version permanently `0.0.0`/`1.0.0`; no meaningful versioning.
- No changelog and no release tags.
- Breaking changes shipped in place with no version bump.
- Manual, undocumented publish steps.

## Scoring anchors

- **0–1:** No versioning, tags, or changelog.
- **2–3:** Versioned and tagged, but changelog is thin and breaking-change
  discipline is loose.
- **4–5:** SemVer, maintained changelog, tagged releases matching artefacts, clear
  deprecation policy, repeatable publishing.
