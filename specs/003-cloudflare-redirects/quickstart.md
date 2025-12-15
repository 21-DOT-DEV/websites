# Quickstart: Cloudflare _redirects Implementation

**Feature**: 003-cloudflare-redirects  
**Date**: 2025-12-14

## Prerequisites

- Access to websites repository
- GitHub Actions workflow permissions
- Cloudflare Pages deployment configured

## Implementation Steps

### Step 1: Create _redirects Files

**docs-21-dev** (`Resources/docs-21-dev/_redirects`):
```text
# docs.21.dev redirects
# Redirect root and legacy paths to documentation landing page

/ /documentation/ 301
/p256k /documentation/ 301
```

**md-21-dev** (`Resources/md-21-dev/_redirects`):
```text
# md.21.dev redirects
# Redirect root to main index file

/ /index.md 301
```

### Step 2: Update generate-docc.yml Workflow

Add after site generation, before deployment:

```yaml
- name: Copy _redirects file
  run: cp Resources/docs-21-dev/_redirects Websites/docs-21-dev/_redirects
```

Add after deployment completes:

```yaml
- name: Verify redirects
  run: |
    # Wait for deployment propagation
    sleep 30
    
    # Test root redirect
    status=$(curl -sI -o /dev/null -w "%{http_code}" "https://docs.21.dev/")
    if [ "$status" != "301" ]; then
      echo "ERROR: docs.21.dev/ expected 301, got $status"
      exit 1
    fi
    
    # Test /p256k redirect
    status=$(curl -sI -o /dev/null -w "%{http_code}" "https://docs.21.dev/p256k")
    if [ "$status" != "301" ]; then
      echo "ERROR: docs.21.dev/p256k expected 301, got $status"
      exit 1
    fi
    
    echo "✓ All docs.21.dev redirects verified"
```

### Step 3: Update generate-markdown.yml Workflow

Add after site generation, before deployment:

```yaml
- name: Copy _redirects file
  run: cp Resources/md-21-dev/_redirects Websites/md-21-dev/_redirects
```

Add after deployment completes:

```yaml
- name: Verify redirects
  run: |
    # Wait for deployment propagation
    sleep 30
    
    # Test root redirect
    status=$(curl -sI -o /dev/null -w "%{http_code}" "https://md.21.dev/")
    if [ "$status" != "301" ]; then
      echo "ERROR: md.21.dev/ expected 301, got $status"
      exit 1
    fi
    
    echo "✓ All md.21.dev redirects verified"
```

## Verification

### Local Verification

Check file syntax (no validation tool needed - syntax is simple):
```bash
cat Resources/docs-21-dev/_redirects
cat Resources/md-21-dev/_redirects
```

### Post-Deployment Verification

Manual curl test:
```bash
curl -I https://docs.21.dev/
# Should show: HTTP/2 301, location: https://docs.21.dev/documentation/

curl -I https://md.21.dev/
# Should show: HTTP/2 301, location: https://md.21.dev/index.md
```

## Rollback

To remove redirects:
1. Delete `_redirects` files from `Resources/<SiteName>/`
2. Remove copy steps from workflows
3. Remove verification steps from workflows
4. Re-deploy

## Related Files

- `Resources/docs-21-dev/_headers` — existing headers pattern to follow
- `Resources/md-21-dev/_headers` — existing headers pattern to follow
- `.github/workflows/generate-docc.yml` — docs.21.dev workflow
- `.github/workflows/generate-markdown.yml` — md.21.dev workflow
