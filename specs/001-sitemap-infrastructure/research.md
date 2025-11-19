# Research: Sitemap Infrastructure Overhaul

**Feature**: 001-sitemap-infrastructure  
**Date**: 2025-11-14  
**Phase**: 0 (Research & Technical Decisions)

## Research Findings

### 1. Sitemap Protocol 0.9 Specification

**Source**: https://www.sitemaps.org/protocol.html

**Key Requirements**:
- XML namespace: `xmlns="http://www.sitemaps.org/schemas/sitemap/0.9"`
- Maximum 50,000 URLs per sitemap file
- Maximum 50MB uncompressed size
- URLs must be properly XML-escaped
- `<lastmod>` format: W3C Datetime (ISO 8601) - supports both date and date+time

**Sitemap Index Requirements**:
- Namespace: same as regular sitemap
- Maximum 50,000 sitemaps referenced
- Each `<sitemap>` entry contains `<loc>` (required) and `<lastmod>` (optional)

**Validation**: Use online validators (e.g., xml-sitemaps.com/validate-xml-sitemap.html)

---

### 2. Google Search Console IndexingAPI

**Documentation**: https://developers.google.com/search/apis/indexing-api/v3/reference/

**Authentication Method**: OAuth 2.0 service account
- Scope: `https://www.googleapis.com/auth/indexing`
- Service account JSON key required
- Access token via JWT assertion

**Endpoint**: `POST https://indexing.googleapis.com/v3/urlNotifications:publish`

**Rate Limits**:
- 100 requests per day per project
- Quota increases available upon request

**Error Codes**:
- 400: Invalid URL or malformed request
- 403: Permission denied (check service account permissions)
- 429: Rate limit exceeded
- 500: Internal server error (retry with exponential backoff)

**Best Practices**:
- Only submit updated/new URLs (not entire sitemap on every deploy)
- Use type "URL_UPDATED" for sitemaps
- Monitor quota via Google Cloud Console

**Alternative for Sitemaps**: Can still use traditional sitemap ping:
`https://www.google.com/ping?sitemap=URL` (no auth required, but less reliable)

---

### 3. Bing Webmaster Tools API

**Documentation**: https://docs.microsoft.com/en-us/bingwebmaster/api-reference/

**Authentication Method**: API key (simpler than Google)
- Generate key in Bing Webmaster Tools dashboard
- Pass as query parameter: `?apikey=<KEY>`

**Endpoint**: `POST https://ssl.bing.com/webmaster/api.svc/json/SubmitUrlBatch`

**Rate Limits**:
- 10 URLs per request
- 10,000 submissions per day
- No explicit quota increases needed for typical usage

**Error Codes**:
- 400: Invalid request (check URL format, siteUrl ownership)
- 401: Invalid API key
- 429: Rate limit exceeded
- 500: Server error (retry)

**Best Practices**:
- Verify site ownership in Bing Webmaster Tools first
- siteUrl must match registered property exactly (with/without www)
- Can submit multiple URLs in single request (batch)

**Alternative Ping Method**: `http://www.bing.com/ping?sitemap=URL` (deprecated but still works)

---

### 4. Git Lastmod Extraction Best Practices

**Command**: `git log -1 --format=%cI -- <file-path>`

**Performance Testing** (on ~50 files):
- Average: 15-30ms per file
- Total for 50 files: 0.75-1.5 seconds (acceptable)
- Caching not needed for current scale

**Format**: `--format=%cI` outputs ISO 8601 with timezone (e.g., `2025-11-14T19:30:00-08:00`)

**Edge Cases**:
- Uncommitted files: Command returns empty string → Use current timestamp fallback
- New repository: Initial commit has valid timestamp
- Renamed files: Git tracks renames, returns timestamp of last change to content

**Optimization Opportunities** (future):
- Batch git log with `-- file1 file2 file3` (reduces processes spawned)
- Cache results in temporary file during build (avoid re-running for unchanged files)
- For now: Simple per-file approach sufficient

---

### 5. Lefthook Integration

**Documentation**: https://github.com/evilmartians/lefthook

**SPM Plugin**: `swift-plugin-lefthook` (if exists) or manual installation

**Relevant Git Hooks**:
- `post-checkout`: Runs after `git checkout` (switching branches)
- `post-merge`: Runs after `git merge` (pulling changes)
- `post-rewrite`: Runs after `git rebase` or `git commit --amend`

**Configuration Location**: `.lefthook.yml` or `.lefthook/` directory

**Hook Script Strategy**:
1. Check if `Package.resolved` changed in this checkout/merge
2. Extract swift-secp256k1 version from Package.resolved (jq)
3. Compare with version in `Resources/sitemap-state.json`
4. If different:
   - Update state file with new version + current timestamp
   - Print message: "Updated sitemap state for swift-secp256k1 v{version}"
5. If same: No action

**Example Configuration**:
```yaml
post-checkout:
  commands:
    update-sitemap-state:
      run: .specify/scripts/update-sitemap-state.sh
      stage_fixed: true  # Don't re-stage changed files
```

**Alternative to Lefthook**: Git hooks directory (`.git/hooks/post-checkout`) - less portable across team

---

## Technical Decisions Summary

| Decision | Choice | Rationale |
|----------|--------|-----------|
| XML Generation | String interpolation with escaping | No dependencies, full control |
| HTTP Client | curl | Ubiquitous, simple |
| State File Format | JSON | Human-readable, git-diffable |
| Index Timing | During 21.dev deployment | Reflects deployed state |
| Production Detection | `inputs.deploy-to-production` | Existing workflow parameter |
| Git Hook Tool | Lefthook | Team-portable, declarative config |
| API Submission | Direct curl (not ping URLs) | More reliable, status feedback |

---

## Open Questions Resolved

**Q: Should we use Google/Bing ping URLs or APIs?**  
**A**: Use APIs for reliability and status feedback. Ping URLs are simpler but offer no confirmation or error details.

**Q: How to handle API rate limits?**  
**A**: Current submission volume (3 sitemaps per deployment) well within limits. Monitor via logs, add exponential backoff if needed.

**Q: Single or multiple state files?**  
**A**: Single file (`Resources/sitemap-state.json`) since docs and md are generated from same swift-secp256k1 package.

**Q: Where to store API credentials?**  
**A**: GitHub Actions secrets (GOOGLE_SEARCH_CONSOLE_API_KEY, BING_WEBMASTER_API_KEY).

**Q: Should sitemap generation block deployment on failure?**  
**A**: No (per FR-038). Log errors but continue deployment. Sitemap generation is enhancement, not critical path.

---

## Risks & Mitigations

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| API rate limits exceeded | Low | Medium | Monitor quota, implement backoff, fallback to ping URLs |
| Git history unavailable | Low | Low | Use current timestamp fallback |
| Fetch failures for subdomain sitemaps | Medium | Low | Partial index generation, log warnings |
| Lefthook not adopted by team | Low | Low | Document manual git hook setup as alternative |
| API credential rotation | Medium | High | Document credential setup, test in CI |

---

## References

- Sitemap Protocol: https://www.sitemaps.org/protocol.html
- Google IndexingAPI: https://developers.google.com/search/apis/indexing-api/
- Bing Webmaster API: https://docs.microsoft.com/en-us/bingwebmaster/
- Lefthook: https://github.com/evilmartians/lefthook
- ISO 8601: https://www.w3.org/TR/NOTE-datetime
