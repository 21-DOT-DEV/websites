# Quickstart: Utilities Library

**Feature**: 004-utilities-library  
**Date**: 2025-12-15

## Prerequisites

- Swift 6.1+
- macOS 15+
- Repository cloned with git history (for lastmod dates)

## Installation

The `util` CLI is built as part of the websites package:

```bash
# Build the CLI
swift build --target util

# Verify installation
swift run util --help
```

## Quick Examples

### Generate Sitemap for 21.dev

```bash
# Generate sitemap using git commit dates for lastmod
swift run util sitemap generate --site 21-dev

# Output: ✅ Sitemap generated: Websites/21-dev/sitemap.xml (42 URLs)
```

### Generate Sitemap for Documentation

```bash
# Generate sitemap using package version state for lastmod
swift run util sitemap generate --site docs-21-dev

# Output: ✅ Sitemap generated: Websites/docs-21-dev/sitemap.xml (156 URLs)
```

### Validate Headers Before Deployment

```bash
# Validate production headers
swift run util headers validate --site 21-dev --env prod

# Output: ✅ Headers valid: 12 rules for 21-dev (prod)
```

### Update State After Package Release

```bash
# Update state with new package version
swift run util state update --package-version 0.22.0

# Output: ✅ State updated: 0.21.1 → 0.22.0 (2025-12-15T08:30:00Z)
```

## Integration Scenarios

### Scenario 1: Local Development

Generate sitemap after building the site locally:

```bash
# 1. Build the site
swift run 21-dev

# 2. Generate sitemap
swift run util sitemap generate --site 21-dev --verbose

# 3. Validate the sitemap
swift run util sitemap validate --site 21-dev
```

### Scenario 2: CI/CD Pipeline (Future - Feature 2)

In GitHub Actions workflow (after Feature 2 migration):

```yaml
- name: Generate sitemap
  run: swift run util sitemap generate --site ${{ inputs.site-name }}

- name: Validate sitemap
  run: swift run util sitemap validate --site ${{ inputs.site-name }}
```

### Scenario 3: Package Version Update

When swift-secp256k1 releases a new version:

```bash
# 1. Update Package.swift with new version
# 2. Update state file
swift run util state update --package-version 0.22.0

# 3. Regenerate docs/md sitemaps (they use state for lastmod)
swift run util sitemap generate --site docs-21-dev
swift run util sitemap generate --site md-21-dev
```

## Library Usage (for developers)

### Using Utilities in Swift Code

```swift
import Utilities

// Generate sitemap entries
let config = SiteConfiguration.for(.dev21)
let entries = try await SitemapGenerator.discoverURLs(config: config)

// Validate a URL
if isValidSitemapURL("https://21.dev/packages/") {
    print("Valid URL")
}

// Read state file
let state = try StateManager.load(from: "Resources/sitemap-state.json")
print("Package version: \(state.packageVersion)")
```

### Backward Compatibility (via DesignSystem)

Existing code continues to work:

```swift
import DesignSystem

// These APIs are re-exported from Utilities (deprecated)
let header = sitemapXMLHeader()
let entry = sitemapURLEntry(url: "https://21.dev", lastmod: "2025-12-15")
```

Migration warning will appear:
```
⚠️ 'sitemapXMLHeader()' is deprecated: Import Utilities directly instead of DesignSystem
```

## Troubleshooting

### "Site output directory not found"

The site must be built before generating a sitemap:

```bash
# Build the site first
swift run 21-dev

# Then generate sitemap
swift run util sitemap generate --site 21-dev
```

### "No URLs discovered"

Check that the output directory contains the expected files:

```bash
# For 21-dev: should contain .html files
ls Websites/21-dev/*.html

# For docs-21-dev: should contain documentation/
ls Websites/docs-21-dev/documentation/
```

### "Cannot detect package version"

The state update command auto-detects version from Package.resolved. If this fails:

```bash
# Specify version explicitly
swift run util state update --package-version 0.21.1
```

### Git lastmod returns current date

This happens when:
- File is not tracked by git
- Git history is shallow (CI clone)
- File has never been committed

For CI, ensure full git clone:
```yaml
- uses: actions/checkout@v4
  with:
    fetch-depth: 0  # Full history for accurate lastmod
```
