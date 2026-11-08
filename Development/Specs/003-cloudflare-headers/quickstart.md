# Quickstart — Cloudflare _headers Optimization

## Prerequisites
- Swift 6.1 toolchain installed (Xcode 16.4 or Swift.org toolchain)
- Cloudflare Pages access + API tokens for analytics (read-only)
- `swift package --disable-sandbox lefthook install` already executed

## Local Development Flow
1. **Install dependencies**
   ```bash
   nocorrect swift package resolve
   swift package --disable-sandbox lefthook install
   ```
2. **Edit `_headers` files**
   - Update `Resources/<site>/_headers` for any subdomain
   - Add/adjust patterns for HTML, static, and download profiles
3. **Run headers validation**
   ```bash
   nocorrect swift run util headers validate --site 21-dev --env prod
   ```
4. **Execute tests**
   ```bash
   nocorrect swift test --filter HeadersValidatorTests
   nocorrect swift test --filter HeadersCommandTests
   ```
5. **Preview site locally**
   ```bash
   nocorrect swift run 21-dev
   # docs-21-dev assembles via generate-docc.yml — no local equivalent
   ```

## Verification Commands (curl)

Use these exact commands after deploying. Each one prints the critical headers; compare with the expected snippet to confirm success criteria.

### 21.dev

```bash
# HTML (production)
curl -sI https://21.dev/ | grep -E 'Strict-Transport|Content-Security|Cache-Control|Permissions-Policy'
# Expected: Strict-Transport-Security max-age=63072000; includeSubDomains; preload
#           Content-Security-Policy default-src 'self'; ... https://static.cloudflareinsights.com
#           Cache-Control public, max-age=300, must-revalidate

# Static asset
curl -sI https://21.dev/static/style.css | grep -E 'Cache-Control'
# Expected: Cache-Control public, max-age=31536000, immutable

# Download endpoint
curl -sI https://21.dev/.well-known/security.txt | grep -E 'Cache-Control|Pragma'
# Expected: Cache-Control no-store / Pragma no-cache
```

### docs.21.dev

```bash
# DocC HTML
curl -sI https://docs.21.dev/documentation/index.html | grep -E 'Strict-Transport|Content-Security|Cache-Control'
# Expected: Strict-Transport-Security max-age=63072000... (production only)
#           Content-Security-Policy default-src 'self'; ... https://static.cloudflareinsights.com
#           Cache-Control public, max-age=300, must-revalidate

# DocC static asset
curl -sI https://docs.21.dev/documentation/tutorials/static/tutorial.js | grep -E 'Cache-Control'
# Expected: Cache-Control public, max-age=31536000, immutable

# Well-known JSON
curl -sI https://docs.21.dev/.well-known/security.txt | grep -E 'Cache-Control|Pragma'
# Expected: Cache-Control no-store / Pragma no-cache
```

## CI/CD Expectations
- GitHub Actions will run `util headers validate` for each site on PRs.
- Deployment workflows (21-DEV.yml, DOCS-21-DEV.yml) will:
  1. Copy `_headers` into `Websites/<site>/_headers`
  2. Deploy to Cloudflare Pages
  3. Hit canonical URLs with `curl -I` and record headers
  4. Optionally query securityheaders.com to confirm grade ≥ A
  5. Pull Cloudflare GraphQL metrics (cache hit %, LCP)
- Failures block merges; warnings appear as annotations.

## Troubleshooting
- **Validator missing**: it ships in the existing `util` target — run `swift run util headers validate --site <site> --env <env>`.
- **Curl mismatch**: check if Cloudflare still caching older `_headers`; purge cache or wait for TTL.
- **Preview builds**: confirm HSTS is disabled (FR-004.1) by verifying header absence.
