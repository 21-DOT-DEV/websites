# Contract: Deployment Header Checks

## Overview
After Cloudflare Pages publishes each subdomain, GitHub Actions runs this contract to confirm headers in production.

## Inputs
- `SITE` (required): `21-dev`, `docs-21-dev`, or `md-21-dev`
- `TARGET_URLS` (array): list of canonical URLs defined in repo (home page, representative HTML, static asset, download)
- `EXPECTED_PROFILES`: mapping of URL → `HeaderProfile.id`

## Workflow Steps
1. For each URL:
   - Run `curl -sSLI -H "Accept-Encoding: gzip" <url>`
   - Capture status code, headers, timing info
2. Compare response headers with expected profile requirements
3. If `SITE` == `production` domain:
   - Invoke `securityheaders.com` API (read-only) for the page URL
   - Compare score vs threshold (>= A)
4. Append results to GitHub Actions summary and store JSON artifact

## Pass/Fail Logic
- Hard fail (exit 1) when any `error` severity mismatch occurs:
  - Missing HSTS on production HTML
  - Missing CSP or X-Frame-Options
  - Cache-Control not matching required policy (HTML vs static vs downloads)
- Soft warning (exit 0) on:
  - Permissions-Policy missing optional directives
  - SecurityHeaders score drops from A to B (warn developer, continue)

## Output Artifact Schema (JSON)
```json
{
  "site": "21-dev",
  "environment": "production",
  "checks": [
    {
      "url": "https://21.dev/",
      "profile": "21-dev:html:prod",
      "status": "passed",
      "headers": {
        "strict-transport-security": "max-age=63072000; includeSubDomains; preload",
        "content-security-policy": "default-src 'self' https://static.cloudflareinsights.com; upgrade-insecure-requests; ..."
      },
      "securityheadersScore": "A"
    }
  ],
  "summary": {
    "errors": 0,
    "warnings": 1
  }
}
```

## Observability Hook
- Upload JSON artifact to workflow run.
- Emit summary line per URL: `✅ [site] [url] matched profile [profileId]`
- For failures, create `::error::` annotations referencing the profile and header mismatch.
