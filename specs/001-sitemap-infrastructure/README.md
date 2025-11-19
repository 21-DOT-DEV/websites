# Sitemap Infrastructure - Setup Guide

## GitHub Actions Secrets Configuration

This feature requires API credentials for automated sitemap submission to search engines.

### Google Search Console Setup

**1. Create a Service Account**:
   - Go to [Google Cloud Console](https://console.cloud.google.com/)
   - Create a new project or select existing project
   - Enable the "Web Search Indexing API"
   - Navigate to "IAM & Admin" → "Service Accounts"
   - Click "Create Service Account"
   - Name: `sitemap-submitter` (or your choice)
   - Grant role: "Service Account User"

**2. Generate JSON Key**:
   - Click on the created service account
   - Go to "Keys" tab
   - Click "Add Key" → "Create new key"
   - Choose "JSON" format
   - Download the JSON file

**3. Verify Search Console Access**:
   - Go to [Google Search Console](https://search.google.com/search-console)
   - Add your domain properties (21.dev, docs.21.dev, md.21.dev)
   - Add the service account email as a user:
     - Settings → Users and permissions
     - Add user with service account email (found in JSON: `client_email`)
     - Permission level: "Owner"

**4. Add to GitHub Secrets**:
   - Repository → Settings → Secrets and variables → Actions
   - Click "New repository secret"
   - Name: `GOOGLE_SERVICE_ACCOUNT_JSON`
   - Value: Paste the entire contents of the downloaded JSON file
   - Click "Add secret"

### Bing Webmaster Tools Setup

**1. Get API Key**:
   - Go to [Bing Webmaster Tools](https://www.bing.com/webmasters)
   - Sign in with Microsoft account
   - Add your sites (21.dev, docs.21.dev, md.21.dev)
   - Verify ownership (DNS TXT record or meta tag)
   - Navigate to Settings → API Access
   - Generate new API key
   - Copy the API key

**2. Add to GitHub Secrets**:
   - Repository → Settings → Secrets and variables → Actions
   - Click "New repository secret"
   - Name: `BING_API_KEY`
   - Value: Paste the API key
   - Click "Add secret"

### Required Secrets Summary

| Secret Name | Description | How to Get |
|-------------|-------------|------------|
| `GOOGLE_SERVICE_ACCOUNT_JSON` | Google service account credentials (JSON) | Google Cloud Console → Service Accounts → Create Key |
| `BING_API_KEY` | Bing Webmaster Tools API key | Bing Webmaster Tools → Settings → API Access |

### Verification

After setting up secrets, the next production deployment will automatically:
1. Deploy to Cloudflare Pages
2. Submit sitemap to Google Search Console
3. Submit sitemap to Bing Webmaster Tools

Check the workflow logs for confirmation:
- ✅ "Successfully submitted to Google Search Console"
- ✅ "Successfully submitted to Bing Webmaster Tools"

If submission fails, warnings will appear in the logs without blocking deployment.

### Testing

To test without production deployment:
1. Temporarily set `deploy-to-production: true` in a PR workflow
2. Monitor workflow logs for submission attempts
3. Check for HTTP 200 responses
4. Verify no deployment blocking on API failures

### Troubleshooting

**Google Submission Fails**:
- Verify service account has "Owner" permission in Search Console
- Check API is enabled in Google Cloud Console
- Ensure JSON secret is valid (no formatting issues)
- Review error message in workflow logs

**Bing Submission Fails**:
- Verify API key is active in Bing Webmaster Tools
- Confirm sites are verified in Bing Webmaster Tools
- Check API rate limits haven't been exceeded
- Review error message in workflow logs

**Both Submissions Fail**:
- Verify secrets are named correctly (case-sensitive)
- Check secrets are available in repository settings
- Ensure workflow has `secrets: inherit` when calling deploy-cloudflare.yml
