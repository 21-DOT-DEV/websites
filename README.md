# websites

## Features

### Sitemap Infrastructure

Automated sitemap generation and search engine submission across all subdomains:
- **21.dev**: Static site sitemap with git-based lastmod dates
- **docs.21.dev**: DocC documentation sitemap
- **md.21.dev**: Markdown documentation sitemap

Each subdomain maintains its own `sitemap.xml` and `robots.txt`, with automated submission to Google Search Console on production deployments.

**Setup & Configuration**: See [specs/001-sitemap-infrastructure/README.md](specs/001-sitemap-infrastructure/README.md) for API credential setup and monitoring instructions.

### Cloudflare Header Policy Matrix

| Subdomain | HTML Responses | Static Assets | Downloads / `.well-known` | Source |
|-----------|----------------|---------------|---------------------------|--------|
| **21.dev** | Prod: HSTS (max-age 63072000; includeSubDomains; preload), CSP allowing `self` + Cloudflare analytics, security headers, `Cache-Control: public, max-age=300, must-revalidate`, `Vary: Accept-Encoding`.<br>Preview: same minus HSTS. | `/static/*` + `/assets/*` use `Cache-Control: public, max-age=31536000, immutable` with `Vary: Accept-Encoding`. | `.json` + `/.well-known/*` run `Cache-Control: no-store` + `Pragma: no-cache`. | [Resources/21-dev/_headers](Resources/21-dev/_headers) |
| **docs.21.dev** | Prod DocC HTML matches security baseline + 5-minute cache; preview omits HSTS. | `/documentation/**/static/*` + `/js/*` use long-lived immutable cache. | `/.well-known/*` and JSON outputs set `Cache-Control: no-store`. | [Resources/docs-21-dev/_headers](Resources/docs-21-dev/_headers) |
| **md.21.dev** | Markdown served as HTML with CSP + 5-minute cache in prod; preview omits HSTS. | `/assets/*` cached 1 year immutable. | `.txt`, `.json`, and `/.well-known/*` return `no-store` and `Pragma: no-cache`. | [Resources/md-21-dev/_headers](Resources/md-21-dev/_headers) |

**Verification**: Run the curl matrix in [specs/002-cloudflare-headers/quickstart.md](specs/002-cloudflare-headers/quickstart.md#verification-commands-curl) for each deployment (HTML, asset, download per site). Preview builds must always exclude HSTS, while production must include it for 21.dev and docs.21.dev HTML routes.

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