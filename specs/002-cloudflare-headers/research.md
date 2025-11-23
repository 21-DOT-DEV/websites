# Research: Cloudflare _headers Optimization

## Decision 1: Header Linting & Enforcement Mechanism
- **Decision**: Implement a Swift-based "HeadersValidator" CLI (within the existing package) that parses each `_headers` file, verifies mandatory directives per URL pattern, and runs as part of unit/integration tests plus CI pre-checks.
- **Rationale**: Reuses the Swift toolchain already required by the repo, keeps validation logic testable with swift-testing, and avoids introducing Node/Python dependencies that violate the zero-dependency principle. By living inside the repo, developers can run `swift test --filter HeadersValidatorTests` or `swift run headers-validator --site 21-dev` locally before pushing.
- **Alternatives Considered**:
  1. **Use third-party CLI (e.g., `cf-pages-lint`)** – rejected because it introduces a new dependency and provides limited customization for multi-site rules.
  2. **Rely solely on `curl -I` smoke tests** – insufficient; curl proves runtime behavior but cannot enforce repository-stored `_headers` before deployment.

## Decision 2: Runtime Verification Strategy
- **Decision**: After each production deployment, run a GitHub Actions job that hits representative URLs per subdomain using `curl -I` and records results plus a `securityheaders.com` scan (read-only) for auditing. Failures block completion and surface as annotations.
- **Rationale**: Combines fast, deterministic header checks (curl) with an external heuristic score without adding runtime dependencies. Hitting a small sample (home page + asset + markdown file) balances coverage and cost.
- **Alternatives Considered**:
  1. **Full site crawl** – too expensive for every deployment; risk of rate limits.
  2. **Rely only on securityheaders.com** – service occasionally rate-limits and does not understand cache headers, so we still need direct header assertions.

## Decision 3: Observability & Metrics Collection
- **Decision**: Use Cloudflare GraphQL Analytics queries (invoked via `curl` with project tokens) to log cache-hit ratio and LCP percentiles for each subdomain once per day (or post-deploy) and post results as part of the workflow summary.
- **Rationale**: Cloudflare already captures the target metrics; querying GraphQL keeps everything in existing infra and avoids building a separate monitoring stack. Results can be compared against success criteria and stored as artifacts for audit.
- **Alternatives Considered**:
  1. **Build custom logging via Workers** – unnecessary complexity plus new runtime code.
  2. **Manual dashboard checks** – fails constitutional requirement for automated validation and would not scale.
