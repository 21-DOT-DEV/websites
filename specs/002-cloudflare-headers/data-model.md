# Data Model — Cloudflare _headers Optimization

## Overview
The feature revolves around three categories of data that must remain consistent across automation:
1. **Header Profiles** that define which directives apply to each URL pattern per environment.
2. **Validation Rules & Deployment Checks** that enforce those profiles pre- and post-deploy.
3. **Metrics Snapshots** collected from Cloudflare Analytics to prove success criteria.

## Entities

### 1. HeaderProfile
- **Description**: Canonical definition of the headers applied to a set of URL patterns for a specific site and environment.
- **Fields**:
  - `id` (string, e.g., `21-dev:html:prod`) — unique key composed of site + pattern + environment.
  - `site` (enum: `21-dev`, `docs-21-dev`, `md-21-dev`).
  - `environment` (enum: `production`, `preview`).
  - `pattern` (string, glob syntax) — e.g., `/*.html`, `/static/*`, `/documentation/**/static/*`.
  - `headers` (dictionary<string,string>) — resolved HTTP headers, e.g., `{"Strict-Transport-Security": "max-age=63072000; includeSubDomains; preload"}`.
  - `description` (string) — explains why profile exists (HTML baseline, assets, downloads, API, etc.).
- **Relationships**:
  - Has many `ValidationRule` entries (one per mandatory directive) referenced by `profileId`.
  - Referenced by `DeploymentCheck` to know which runtime URL should be tested.
- **Constraints**:
  - Production profiles MUST include all security directives; preview profiles MUST omit HSTS.
  - Patterns must not overlap with conflicting directives; deterministic precedence is enforced during linting.

### 2. ValidationRule
- **Description**: Machine-enforceable requirement associated with a header profile.
- **Fields**:
  - `id` (string).
  - `profileId` (foreign key to HeaderProfile).
  - `name` (string, e.g., `HSTS-prod`, `CSP-analytics-allowlist`).
  - `severity` (enum: `error`, `warning`).
  - `expectation` (string) — textual description of the required header/value pair.
  - `matcher` (struct) — data needed by the validator CLI (header name, mustInclude substrings, regex, etc.).
- **Relationships**:
  - Aggregated by HeadersValidator CLI to generate swift-testing cases.
- **Constraints**:
  - Severity `error` blocks builds; `warning` surfaces as GitHub annotation but does not block preview deployments.

### 3. DeploymentCheck
- **Description**: Runtime assertion executed by CI/CD after deployment.
- **Fields**:
  - `id` (string, e.g., `21-dev-home`, `docs-static-css`).
  - `site` (enum).
  - `url` (string) — absolute URL to test.
  - `expectedProfileId` (foreign key to HeaderProfile) — indicates which header set should be observed.
  - `tools` (array enum: `curl`, `securityheaders`, `graphQL`) — checks to run.
  - `retryPolicy` (int attempts, delay ms) — handle transient failures/rate limits.
- **Relationships**:
  - Uses `HeaderProfile` to compare actual vs expected values.
  - Logs results into `MetricsSnapshot` as pass/fail metadata.

### 4. MetricsSnapshot
- **Description**: Aggregated metrics from Cloudflare GraphQL Analytics used to prove success criteria.
- **Fields**:
  - `id` (UUID).
  - `site` (enum).
  - `capturedAt` (ISO8601 timestamp).
  - `cacheHitRatio` (float percentage).
  - `p75LCP` (milliseconds).
  - `p90LCP` (milliseconds).
  - `notes` (string) — optional annotation if thresholds not met.
- **Relationships**:
  - Populated by the analytics workflow step triggered post-deploy or daily.
- **Constraints**:
  - Stored as JSON artifacts to maintain historical evidence.

## State & Lifecycle
1. **Author headers**: Engineers edit `Resources/<site>/_headers`, implicitly creating/updating `HeaderProfile` records (represented as YAML/JSON within validator fixtures).
2. **Validate locally**: HeadersValidator reads `_headers`, materializes `HeaderProfile` + `ValidationRule`, and runs swift-testing to ensure compliance.
3. **Deploy**: GitHub Actions copies `_headers`, executes DeploymentChecks, and writes `MetricsSnapshot` artifacts.
4. **Monitor**: Automation compares latest `MetricsSnapshot` values against success criteria and notifies if thresholds regress.

## Open Questions
- None; all clarifications handled during `/speckit.clarify`.
