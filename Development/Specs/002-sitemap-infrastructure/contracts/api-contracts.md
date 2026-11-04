# Search Engine API Contracts

**Feature**: 001-sitemap-infrastructure  
**Purpose**: Automated sitemap submission to Google Search Console and Bing Webmaster Tools

## Google Search Console IndexingAPI

### Endpoint

```
POST https://indexing.googleapis.com/v3/urlNotifications:publish
```

### Authentication

**Method**: OAuth 2.0 Service Account  
**Scope**: `https://www.googleapis.com/auth/indexing`

**Requirements**:
1. Create service account in Google Cloud Console
2. Download JSON key file
3. Share property with service account email in Search Console
4. Store JSON key as GitHub Actions secret

**Token Generation** (for reference):
```bash
# Service account generates JWT, exchanges for access token
# Libraries handle this automatically (google-auth-library)
# For manual curl, use jwt.io or similar to create JWT assertion
```

---

### Request

#### Headers

```
Authorization: Bearer {ACCESS_TOKEN}
Content-Type: application/json
```

#### Body

```json
{
  "url": "https://21.dev/sitemap.xml",
  "type": "URL_UPDATED"
}
```

**Field Descriptions**:
- `url` (string, required): The URL to notify about (sitemap URL)
- `type` (string, required): Type of notification
  - `URL_UPDATED`: URL has been updated/added
  - `URL_DELETED`: URL has been removed (not used)

---

### Response

#### Success (200 OK)

```json
{
  "urlNotificationMetadata": {
    "url": "https://21.dev/sitemap.xml",
    "latestUpdate": {
      "type": "URL_UPDATED",
      "notifyTime": "2025-11-14T19:30:00Z"
    }
  }
}
```

#### Error (400 Bad Request)

```json
{
  "error": {
    "code": 400,
    "message": "Invalid URL format",
    "status": "INVALID_ARGUMENT"
  }
}
```

#### Error (403 Forbidden)

```json
{
  "error": {
    "code": 403,
    "message": "The caller does not have permission",
    "status": "PERMISSION_DENIED"
  }
}
```

#### Error (429 Too Many Requests)

```json
{
  "error": {
    "code": 429,
    "message": "Quota exceeded",
    "status": "RESOURCE_EXHAUSTED"
  }
}
```

---

### Rate Limits

- **Quota**: 100 requests per day per project
- **Burst**: No official burst limit documented
- **Quota Increases**: Request via Google Cloud Console

**Current Usage**: 3 sitemaps × ~5 deployments/week = ~15 requests/week (well within limit)

---

### Implementation (curl)

```bash
#!/bin/bash
# submit-to-google.sh

SITEMAP_URL="$1"
SERVICE_ACCOUNT_JSON="$GOOGLE_SERVICE_ACCOUNT_JSON"  # From GitHub secret

# Generate access token (requires google-auth or similar)
# For simplicity in CI, consider using gcloud CLI or pre-generated token

ACCESS_TOKEN=$(get_access_token_from_service_account)  # Implementation needed

curl -X POST \
  "https://indexing.googleapis.com/v3/urlNotifications:publish" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"url\":\"$SITEMAP_URL\",\"type\":\"URL_UPDATED\"}" \
  -w "\nHTTP Status: %{http_code}\n" \
  -o /tmp/google-response.json

HTTP_CODE=$(tail -1 /tmp/google-response.json | grep -oP '(?<=HTTP Status: )\d+')

if [ "$HTTP_CODE" = "200" ]; then
  echo "✅ Successfully submitted $SITEMAP_URL to Google"
  exit 0
else
  echo "⚠️  Google submission failed with status $HTTP_CODE"
  cat /tmp/google-response.json
  exit 1
fi
```

---

## Bing Webmaster Tools API

### Endpoint

```
POST https://ssl.bing.com/webmaster/api.svc/json/SubmitUrlBatch
```

### Authentication

**Method**: API Key (query parameter)  
**Key Location**: Query string `?apikey={API_KEY}`

**Requirements**:
1. Register site in Bing Webmaster Tools
2. Verify site ownership
3. Generate API key from dashboard
4. Store API key as GitHub Actions secret

---

### Request

#### URL

```
https://ssl.bing.com/webmaster/api.svc/json/SubmitUrlBatch?apikey={API_KEY}
```

#### Headers

```
Content-Type: application/json
```

#### Body

```json
{
  "siteUrl": "https://21.dev",
  "urlList": [
    "https://21.dev/sitemap.xml"
  ]
}
```

**Field Descriptions**:
- `siteUrl` (string, required): The verified site URL (must match registered property exactly)
- `urlList` (array[string], required): List of URLs to submit (max 10 per request)

**Important**: `siteUrl` must match registered property format:
- If registered with `https://21.dev`, use `https://21.dev` (no trailing slash)
- If registered with `https://www.21.dev`, use `https://www.21.dev`

---

### Response

#### Success (200 OK)

```json
{
  "d": null
}
```

**Note**: Bing returns `{"d":null}` on success (unusual but documented behavior)

#### Error (400 Bad Request)

```json
{
  "Message": "The site 'https://21.dev' is not verified for this user",
  "ErrorCode": "InvalidSite"
}
```

#### Error (401 Unauthorized)

```json
{
  "Message": "Invalid API key",
  "ErrorCode": "InvalidAPIKey"
}
```

#### Error (429 Too Many Requests)

```json
{
  "Message": "Daily quota exceeded",
  "ErrorCode": "QuotaExceeded"
}
```

---

### Rate Limits

- **URLs per Request**: 10 maximum
- **Daily Quota**: 10,000 URLs per day
- **No Burst Limits**: Documented

**Current Usage**: 3 URLs × ~5 deployments/week = ~15 URLs/week (well within limit)

---

### Implementation (curl)

```bash
#!/bin/bash
# submit-to-bing.sh

SITEMAP_URL="$1"
SITE_URL="$2"  # e.g., "https://21.dev" (must match registered property)
API_KEY="$BING_WEBMASTER_API_KEY"  # From GitHub secret

curl -X POST \
  "https://ssl.bing.com/webmaster/api.svc/json/SubmitUrlBatch?apikey=$API_KEY" \
  -H "Content-Type: application/json" \
  -d "{\"siteUrl\":\"$SITE_URL\",\"urlList\":[\"$SITEMAP_URL\"]}" \
  -w "\nHTTP Status: %{http_code}\n" \
  -o /tmp/bing-response.json

HTTP_CODE=$(tail -1 /tmp/bing-response.json | grep -oP '(?<=HTTP Status: )\d+')

if [ "$HTTP_CODE" = "200" ]; then
  RESPONSE=$(head -1 /tmp/bing-response.json)
  if echo "$RESPONSE" | grep -q '"d":null'; then
    echo "✅ Successfully submitted $SITEMAP_URL to Bing"
    exit 0
  else
    echo "⚠️  Bing submission succeeded but response unexpected: $RESPONSE"
    exit 1
  fi
else
  echo "⚠️  Bing submission failed with status $HTTP_CODE"
  cat /tmp/bing-response.json
  exit 1
fi
```

---

## Combined Submission Script

**File**: `.github/workflows/submit-sitemap.sh`

```bash
#!/bin/bash
set -e

SITEMAP_URL="$1"
SITE_URL="$2"  # For Bing (e.g., "https://21.dev")

if [ -z "$SITEMAP_URL" ] || [ -z "$SITE_URL" ]; then
  echo "Usage: $0 <sitemap-url> <site-url>"
  exit 1
fi

echo "📤 Submitting sitemap: $SITEMAP_URL"
echo "----------------------------------------"

# Submit to Google
echo "→ Submitting to Google Search Console..."
if submit_to_google "$SITEMAP_URL"; then
  echo "✅ Google: Success"
  GOOGLE_SUCCESS=true
else
  echo "⚠️  Google: Failed (non-blocking)"
  GOOGLE_SUCCESS=false
fi

# Submit to Bing
echo "→ Submitting to Bing Webmaster Tools..."
if submit_to_bing "$SITEMAP_URL" "$SITE_URL"; then
  echo "✅ Bing: Success"
  BING_SUCCESS=true
else
  echo "⚠️  Bing: Failed (non-blocking)"
  BING_SUCCESS=false
fi

echo "----------------------------------------"
if [ "$GOOGLE_SUCCESS" = true ] && [ "$BING_SUCCESS" = true ]; then
  echo "✅ All submissions successful"
  exit 0
elif [ "$GOOGLE_SUCCESS" = true ] || [ "$BING_SUCCESS" = true ]; then
  echo "⚠️  Partial success (at least one failed)"
  exit 0  # Non-blocking per FR-038
else
  echo "❌ All submissions failed"
  exit 0  # Still non-blocking per FR-038
fi
```

---

## GitHub Actions Integration

### Secrets Required

```yaml
secrets:
  GOOGLE_SEARCH_CONSOLE_API_KEY: ${{ secrets.GOOGLE_SEARCH_CONSOLE_API_KEY }}
  BING_WEBMASTER_API_KEY: ${{ secrets.BING_WEBMASTER_API_KEY }}
```

### Workflow Step Example

```yaml
- name: Submit sitemaps to search engines
  if: inputs.deploy-to-production == true
  env:
    GOOGLE_SEARCH_CONSOLE_API_KEY: ${{ secrets.GOOGLE_SEARCH_CONSOLE_API_KEY }}
    BING_WEBMASTER_API_KEY: ${{ secrets.BING_WEBMASTER_API_KEY }}
  run: |
    chmod +x .github/workflows/submit-sitemap.sh
    
    # Submit sitemap index
    .github/workflows/submit-sitemap.sh \
      "https://21.dev/sitemap.xml" \
      "https://21.dev"
    
    # Submit subdomain sitemaps
    .github/workflows/submit-sitemap.sh \
      "https://docs.21.dev/sitemap.xml" \
      "https://docs.21.dev"
    
    .github/workflows/submit-sitemap.sh \
      "https://md.21.dev/sitemap.xml" \
      "https://md.21.dev"
```

---

## Error Handling Strategy

### Non-Blocking Failures (per FR-038)

**Principle**: Sitemap submission failures MUST NOT block deployment

**Implementation**:
- Log all errors with detailed information
- Return exit code 0 even on failure (allows workflow to continue)
- Set GitHub Actions step output to indicate success/failure for monitoring
- Send notifications via GitHub Actions annotations (warning, not error)

### Retry Logic (Optional Enhancement)

**Current**: No automatic retries (simplicity)

**Future Enhancement**:
```bash
retry_with_backoff() {
  local max_attempts=3
  local timeout=1
  local attempt=1
  
  while [ $attempt -le $max_attempts ]; do
    if "$@"; then
      return 0
    fi
    
    echo "Attempt $attempt failed, retrying in ${timeout}s..."
    sleep $timeout
    timeout=$((timeout * 2))
    attempt=$((attempt + 1))
  done
  
  return 1
}

retry_with_backoff submit_to_google "$SITEMAP_URL"
```

---

## Monitoring & Observability

### Log Messages

```
📤 Submitting sitemap: https://21.dev/sitemap.xml
----------------------------------------
→ Submitting to Google Search Console...
✅ Google: Success (HTTP 200)
→ Submitting to Bing Webmaster Tools...
✅ Bing: Success (HTTP 200, {"d":null})
----------------------------------------
✅ All submissions successful
```

### GitHub Actions Annotations

```yaml
- name: Annotate submission results
  if: always()
  run: |
    if [ "$GOOGLE_SUCCESS" = false ]; then
      echo "::warning::Google Search Console submission failed"
    fi
    if [ "$BING_SUCCESS" = false ]; then
      echo "::warning::Bing Webmaster Tools submission failed"
    fi
```

---

## Testing Strategy

### Development Testing

**Google Ping Alternative** (no auth needed):
```bash
curl "https://www.google.com/ping?sitemap=https://21.dev/sitemap.xml"
```

**Bing Ping Alternative** (no auth needed):
```bash
curl "http://www.bing.com/ping?sitemap=https://21.dev/sitemap.xml"
```

### Verification

1. **Google Search Console**:
   - Navigate to Sitemaps section
   - Check "Last read" timestamp
   - Verify URL count matches sitemap

2. **Bing Webmaster Tools**:
   - Navigate to Sitemaps section
   - Check submission status
   - Verify discovered URLs

3. **Logs**:
   - Check GitHub Actions workflow logs
   - Verify HTTP 200 responses
   - Confirm submission count (3 sitemaps per deployment)
