# Quickstart: Canonical URL Management

**Feature**: 005-canonical-url  
**Date**: 2025-12-30

## Overview

The `util canonical` command audits and fixes `<link rel="canonical">` tags in generated HTML files to ensure proper SEO across all subdomains.

## Prerequisites

- Swift 6.1+ installed
- Repository cloned and dependencies resolved (`swift build`)
- Generated site output in `Websites/<site-name>/`

## Quick Commands

### Check for Issues

```bash
# Check 21.dev site
swift run util canonical check \
  --path ./Websites/21-dev \
  --base-url https://21.dev

# Check docs.21.dev (DocC output)
swift run util canonical check \
  --path ./Websites/docs-21-dev \
  --base-url https://docs.21.dev

# Check md.21.dev (markdown docs)
swift run util canonical check \
  --path ./Websites/md-21-dev \
  --base-url https://md.21.dev
```

### Fix Missing Canonicals

```bash
# Preview changes first (recommended)
swift run util canonical fix \
  --path ./Websites/docs-21-dev \
  --base-url https://docs.21.dev \
  --dry-run

# Apply fixes
swift run util canonical fix \
  --path ./Websites/docs-21-dev \
  --base-url https://docs.21.dev
```

### Force Update All (Domain Migration)

```bash
swift run util canonical fix \
  --path ./Websites/21-dev \
  --base-url https://new-domain.dev \
  --force
```

## Workflow Integration

### Post-Build Validation

Add to your build script after site generation:

```bash
#!/bin/bash
set -e

# Generate site
swift run 21-dev

# Validate canonicals
swift run util canonical check \
  --path ./Websites/21-dev \
  --base-url https://21.dev

echo "✅ Site built and validated"
```

### CI Pipeline

```yaml
# .github/workflows/build.yml
- name: Build site
  run: swift run 21-dev

- name: Check canonical URLs
  run: |
    swift run util canonical check \
      --path ./Websites/21-dev \
      --base-url https://21.dev
```

### DocC Post-Processing

DocC doesn't add canonical tags by default. Fix them after generation:

```bash
# Generate DocC documentation
swift package generate-documentation ...

# Add canonical tags
swift run util canonical fix \
  --path ./Websites/docs-21-dev \
  --base-url https://docs.21.dev

# Verify
swift run util canonical check \
  --path ./Websites/docs-21-dev \
  --base-url https://docs.21.dev
```

## Understanding Output

### Check Output

```
✅ 45 valid      # Canonical matches expected URL
⚠️ 3 mismatch   # Canonical exists but differs
❌ 12 missing    # No canonical tag found
```

### Fix Output

```
✅ Added: 12     # New canonical tags inserted
⚠️ Skipped: 3   # Had existing canonical (use --force)
❌ Failed: 0     # Errors during fix
```

## Common Scenarios

| Scenario | Command |
|----------|---------|
| Audit before deploy | `check --path ... --base-url ...` |
| Fix missing tags | `fix --path ... --base-url ...` |
| Preview fixes | `fix --path ... --base-url ... --dry-run` |
| Domain migration | `fix --path ... --base-url https://new.dev --force` |
| Verbose debugging | Add `-v` to any command |

## Troubleshooting

### "Path does not exist"
Ensure the site has been generated first:
```bash
swift run 21-dev  # or appropriate site target
```

### "Invalid base URL"
Base URL must include scheme:
```bash
# Wrong
--base-url 21.dev

# Correct
--base-url https://21.dev
```

### Files skipped with warnings
- **No `<head>` section**: File structure incompatible; manual fix needed
- **Multiple canonical tags**: Remove duplicates manually before running fix
- **Parse error**: Check file encoding (must be UTF-8)
