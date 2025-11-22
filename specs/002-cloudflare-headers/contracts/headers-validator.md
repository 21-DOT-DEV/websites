# Contract: HeadersValidator CLI

## Purpose
Static validation tool that ensures every `_headers` file across 21.dev, docs.21.dev, and md.21.dev satisfies mandatory security and caching directives before deployment.

## Invocation
```
swift run headers-validator --site <site> --environment <env> [--output json]
```
- `--site`: one of `21-dev`, `docs-21-dev`, `md-21-dev` (required)
- `--environment`: `production` or `preview`
- `--output`: optional, `text` (default) or `json`

## Input Data
- Reads `Resources/<site>/_headers`
- Loads canonical `HeaderProfile` + `ValidationRule` definitions from `Configuration/HeaderProfiles/*.json`

## Behavior
1. Parse `_headers` using Cloudflare Pages grammar.
2. For each URL pattern, map to one or more `HeaderProfile` entries.
3. Execute validators:
   - Presence checks (e.g., `Strict-Transport-Security` for production HTML patterns)
   - Value checks (substring or regex matches, case-insensitive)
   - Conflict detection (e.g., mutually exclusive directives between overlapping patterns)
4. Emit report with severity counts.
5. Exit with non-zero status if any `error` severity violations detected.

## Output Format (text)
```
HeadersValidator 1.0.0
Site: 21-dev (production)
Status: FAILED (2 errors, 1 warning)

[ERROR] pattern "/*.html" missing header Strict-Transport-Security
[ERROR] pattern "/static/*" cache-control value should include "immutable"
[WARN ] pattern "/documentation/**" Permissions-Policy should disable geolocation
```

## Output Format (JSON)
```json
{
  "site": "21-dev",
  "environment": "production",
  "status": "failed",
  "errors": [
    {
      "pattern": "/*.html",
      "rule": "HSTS-prod",
      "message": "missing Strict-Transport-Security header",
      "severity": "error"
    }
  ],
  "warnings": []
}
```

## Exit Codes
- `0`: All validations passed (only warnings or none)
- `1`: One or more errors detected
- `2`: Tool error (parse failure, missing file, etc.)

## Test Requirements
- Unit tests cover parser edge cases (comments, blank lines, duplicate headers).
- Integration tests render sample `_headers` (happy path + error path) and assert CLI exit codes/log output.
- Snapshot tests for JSON output to prevent format drift.
