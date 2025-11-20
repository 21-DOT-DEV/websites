# websites

## Features

### Sitemap Infrastructure

Automated sitemap generation and search engine submission across all subdomains:
- **21.dev**: Static site sitemap with git-based lastmod dates
- **docs.21.dev**: DocC documentation sitemap
- **md.21.dev**: Markdown documentation sitemap

Each subdomain maintains its own `sitemap.xml` and `robots.txt`, with automated submission to Google Search Console on production deployments.

**Setup & Configuration**: See [specs/001-sitemap-infrastructure/README.md](specs/001-sitemap-infrastructure/README.md) for API credential setup and monitoring instructions.

## Setup

### Lefthook (Git Hooks)

This project uses [Lefthook](https://github.com/evilmartians/lefthook) via the [lefthook-plugin](https://github.com/csjones/lefthook-plugin) Swift package to automatically manage the sitemap state file.

**Installation**:

```bash
swift package --disable-sandbox lefthook install
```

**What it does**:
- Automatically updates `Resources/sitemap-state.json` when `Package.resolved` changes
- Tracks the `swift-secp256k1` package version for sitemap lastmod dates
- Ensures docs/md subdomain sitemaps only update when the dependency version changes

**Manual verification**:

```bash
# Check if hooks are installed
swift package --disable-sandbox lefthook check-install

# Validate configuration
swift package --disable-sandbox lefthook validate
```

**Note**: The `--disable-sandbox` flag is required because the plugin needs file system access to manage git hooks.