# Sitemap Infrastructure - Setup Guide

## GitHub Actions Secrets Configuration

This feature requires API credentials for automated sitemap submission to search engines.

## Search Engine Submission Setup

### Google Search Console Setup

1. **Create a Google Cloud Project**:
   - Go to [Google Cloud Console](https://console.cloud.google.com/)
   - Create a new project or select existing

2. **Enable Search Console API**:
   - Go to APIs & Services → Library
   - Search for "Google Search Console API"
   - Click "Enable"

3. **Create Service Account**:
   - Go to APIs & Services → Credentials
   - Click "Create Credentials" → "Service Account"
   - Name: `sitemap-submitter` (or your choice)
   - No role assignment needed at Cloud level

4. **Generate Service Account Key**:
   - Click on the service account
   - Go to "Keys" tab
   - Click "Add Key" → "Create new key"
   - Choose JSON format
   - Save the downloaded JSON file securely

5. **Add Service Account to Search Console**:
   - Go to [Google Search Console](https://search.google.com/search-console)
   - For each property (21.dev, docs.21.dev, md.21.dev):
     - Go to Settings → Users and permissions
     - Click "Add user"
     - Enter service account email (from JSON: `client_email`)
     - Set permission: **Owner** (required for API access)

### Bing Webmaster Tools Setup

**Note**: Bing does not provide an automated sitemap submission API. Sitemaps must be submitted manually (one-time setup).

1. **Sign in to Bing Webmaster Tools**:
   - Go to [Bing Webmaster Tools](https://www.bing.com/webmasters/)
   - Sign in with your Microsoft account

2. **Add/Verify Your Sites**:
   - Add 21.dev, docs.21.dev, and md.21.dev
   - Complete verification process (DNS, meta tag, or file)

3. **Submit Sitemaps Manually**:
   - For each site, go to Sitemaps section
   - Click "Submit sitemap"
   - Enter sitemap URL:
     - `https://21.dev/sitemap.xml`
     - `https://docs.21.dev/sitemap.xml`
     - `https://md.21.dev/sitemap.xml`
   - Click "Submit"

**Important**: After initial manual submission, Bing will automatically discover sitemap updates via the `robots.txt` file and the `lastmod` dates in your sitemaps.

### Configure GitHub Secrets

Add this secret to your GitHub repository:

1. **`GOOGLE_SERVICE_ACCOUNT_JSON`**:
   - Go to Settings → Secrets and variables → Actions
   - Click "New repository secret"
   - Name: `GOOGLE_SERVICE_ACCOUNT_JSON`
   - Value: Paste the entire contents of the service account JSON file (all lines, including braces)

### Verification

After setting up secrets and manual Bing submission, production deployments will automatically:
1. Deploy to Cloudflare Pages
2. Submit sitemap to Google Search Console (automated)
3. Bing discovers updates via robots.txt + lastmod (automatic after initial manual submission)

Check the workflow logs for confirmation:
- ✅ "Successfully submitted to Google Search Console"
- HTTP Status: 204 (No Content - Success)

If Google submission fails, warnings will appear in the logs without blocking deployment.

### Testing

**Local Testing** (recommended before relying on GitHub Actions):
```bash
# 1. Export your Google credentials
export GOOGLE_SERVICE_ACCOUNT_JSON="$(cat path/to/service-account.json)"

# 2. Test submission for one sitemap
./scripts/test-sitemap-submission.sh https://docs.21.dev/sitemap.xml

# 3. Test all sitemaps
./scripts/test-sitemap-submission.sh https://21.dev/sitemap.xml
./scripts/test-sitemap-submission.sh https://docs.21.dev/sitemap.xml
./scripts/test-sitemap-submission.sh https://md.21.dev/sitemap.xml
```

**Expected Output**:
```
✅ Successfully submitted to Google Search Console
HTTP Status: 204 (No Content - Success)
```

**GitHub Actions Testing**:
1. Ensure `GOOGLE_SERVICE_ACCOUNT_JSON` secret is configured
2. Trigger a production deployment with `deploy-to-production: true`
3. Monitor workflow logs for submission attempts
4. Check for HTTP 204 response
5. Verify no deployment blocking on API failures

### Troubleshooting

**Google Submission Fails**:
- Verify service account has "Owner" permission in Search Console for each property
- Check "Google Search Console API" (not Indexing API) is enabled in Google Cloud Console
- Ensure JSON secret is valid (no formatting issues, complete JSON with all brackets)
- Review error message in workflow logs (common: 403 = permission issue, 404 = site not verified)

**Bing Sitemaps Not Updating**:
- Verify robots.txt contains sitemap reference
- Check `lastmod` dates are updating in your sitemaps
- Allow 24-48 hours for Bing to re-crawl after sitemap changes
- Manually re-submit sitemap if needed (no API required)

## Monitoring Checklist

Use this checklist to verify sitemap infrastructure health after deployments.

### Workflow Logs

- [ ] Check latest production deployment workflow run
- [ ] Verify sitemap generation step completed successfully for each subdomain
- [ ] Confirm Google Search Console submission shows HTTP 204 response
- [ ] Review any warnings or errors in submission logs

### Search Console Verification

**Google Search Console** (https://search.google.com/search-console):

For each property (21.dev, docs.21.dev, md.21.dev):
- [ ] Navigate to Sitemaps section
- [ ] Verify sitemap.xml is listed with "Success" status
- [ ] Check last read date is recent (within 7 days)
- [ ] Review discovered URLs count matches expected page count
- [ ] Check Coverage report shows no errors

**Bing Webmaster Tools** (https://www.bing.com/webmasters/):

For each site (21.dev, docs.21.dev, md.21.dev):
- [ ] Navigate to Sitemaps section
- [ ] Verify sitemap.xml shows recent "Last Crawled" date
- [ ] Review URL count matches submitted sitemap
- [ ] Check for any crawl errors or warnings

### Sitemap Content Validation

For each subdomain sitemap (view in browser or curl):
- [ ] **21.dev/sitemap.xml**: Verify all static pages included
- [ ] **docs.21.dev/sitemap.xml**: Verify all documentation pages included
- [ ] **md.21.dev/sitemap.xml**: Verify all markdown files included
- [ ] Check `<lastmod>` dates are accurate and updating correctly
- [ ] Validate XML structure with https://www.xml-sitemaps.com/validate-xml-sitemap.html

### robots.txt Verification

For each subdomain (view in browser):
- [ ] **21.dev/robots.txt**: Contains `Sitemap: https://21.dev/sitemap.xml`
- [ ] **docs.21.dev/robots.txt**: Contains `Sitemap: https://docs.21.dev/sitemap.xml`
- [ ] **md.21.dev/robots.txt**: Contains `Sitemap: https://md.21.dev/sitemap.xml`

### Indexing Health (7-day check)

After 7 days post-deployment:
- [ ] Google Search Console shows 95%+ of submitted URLs indexed
- [ ] No significant coverage errors or excluded URLs
- [ ] Bing shows increasing indexed page count
- [ ] Manual `site:` search shows recent pages indexed

### State File Integrity

- [ ] `Resources/sitemap-state.json` version matches `Package.resolved` swift-secp256k1 version
- [ ] `generated_date` in state file is ISO 8601 format
- [ ] Lefthook hooks are installed (`swift package --disable-sandbox lefthook check-install`)

**Recommended Frequency**: 
- Weekly after initial deployment
- After each major content update
- After Package.resolved changes (dependency updates)
