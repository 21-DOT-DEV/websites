# Spec — 007 · Verify _redirects rules against deployed URLs

Feature 007 · Status lives in [plan.md](./plan.md)

## Summary

Every rule in a site's `_redirects` file is checked against the deployed
preview after each non-production deploy: the request fires, the response
status and `Location` are compared to what the file declares, and the
deploy fails loudly when they disagree. The check is derived from the
file itself, so a new rule is verified the moment it is written — today a
rule is only covered if someone remembers to add it to a hand-maintained
curl list in the deploy workflow.

## User journey

A maintainer edits `Resources/<site>/_redirects` and opens a PR. On
preview deploy, the workflow runs `util redirects verify --site <site>
--base-url <preview>`; every literal rule is requested and asserted
(status and `Location`), every 3xx wildcard rule is probed with a fixed
token, and any rule that cannot be proven by request is listed as
skipped. A disagreement — wrong status, wrong `Location`, unreachable
host — fails the deploy with the offending rule named.

**Independent test:** run the command against any deployment of either
site; it exits 0 when the file's rules match observed behavior and
non-zero naming the broken rule otherwise.

### Acceptance scenarios

1. **Given** `/docs https://docs.21.dev/documentation/ 301` in
   `_redirects` and a deployment returning exactly that redirect, **when**
   verify runs, **then** the rule is reported passed — covers FR-001,
   FR-002.
2. **Given** a literal rule whose live status is 404 instead of the
   declared 301, **when** verify runs, **then** it exits non-zero naming
   the source path, the expected status, and the observed status —
   covers FR-002, FR-005.
3. **Given** a literal rule whose `Location` differs from the declared
   target, **when** verify runs, **then** it exits non-zero naming the
   expected and observed targets — covers FR-002, FR-005.
4. **Given** `/p256k/* /documentation/p256k/:splat/ 301`, **when** verify
   runs, **then** a probe request with a fixed token substituted for `*`
   asserts `Location` equals `/documentation/p256k/<token>/` — covers
   FR-003.
5. **Given** `/.well-known/* /well-known/:splat 200`, **when** verify
   runs, **then** the rule is reported as skipped with a stated reason —
   neither passed nor failed — covers FR-004, FR-005.
6. **Given** a new rule committed to `_redirects` with no workflow edit,
   **when** the next preview deploy runs, **then** the rule is verified —
   covers SC-002.

## Functional requirements

- **FR-001** Parses `_redirects`: `source target status` columns, `#`
  comments and blank lines ignored; targets may be site-relative paths or
  absolute URLs.
- **FR-002** For every rule with a literal source, requests
  `base-url + source`, asserts the response status equals the declared
  status, and — for redirect statuses — asserts `Location` equals the
  declared target after normalization (relative targets resolve against
  the base URL).
- **FR-003** For every rule with a `*` source or `:`-placeholder target
  declaring a 3xx status, substitutes a fixed probe token for each
  wildcard and applies the FR-002 assertions to the probe response.
- **FR-004** Wildcard rules declaring a non-3xx status are reported as
  skipped with a stated reason — a rewrite cannot be proven by status
  alone when the probed target may not exist.
- **FR-005** Reports every rule as passed, failed (with expected and
  observed values), or skipped (with reason); exits non-zero when any
  rule fails.
- **FR-006** Issues HEAD requests, falling back to GET on 405/501; each
  request is bounded by a per-request timeout.
- **FR-007** The CLI accepts `--site <site>` resolving to
  `Resources/<site>/_redirects` and `--base-url <url>` accepting any
  deployment origin (preview or production).

## Measurable outcomes

- **SC-001** Both "Verify redirects" steps in `deploy-cloudflare.yml`
  are a single `swift run util redirects verify` invocation; no literal
  URL or status code remains in the workflow.
- **SC-002** A rule added to `_redirects` is verified on the next preview
  deploy with zero workflow changes.
- **SC-003** Verification completes in under 60 seconds per site at
  current rule counts (~20 rules each).

## Edge cases

- **Chained redirects** — only the first hop is asserted; the target's
  own rule, if any, covers the next hop.
- **External absolute targets** — `Location` asserted literally; no
  cross-host normalization.
- **Probe-token collision** — a probe path matching a real page could
  false-pass a wildcard rule; the token is chosen to be conspicuous and
  is named in the command output.
- **First-match semantics** — `_redirects` applies rules in file order;
  shadowed rules are verified as written, not flagged (lint-style shadow
  detection is out of scope).

## Assumptions and dependencies

- Runs against a live deployment — network access is required by design,
  unlike the planned `util links check`, which is filesystem-only.
  Post-deploy placement in `deploy-cloudflare.yml` satisfies this.
- Verification runs on preview deploys only, mirroring the existing
  `deploy-to-production == false` gate; production sweeps belong to
  external-monitoring scope, not this command.
- The www → apex canonical redirect lives in Cloudflare Rules, not
  `_redirects` (it needs dynamic expressions); out of scope.
