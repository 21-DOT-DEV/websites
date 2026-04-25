# websites

## Features

### Sitemap Infrastructure

Automated sitemap generation and search engine submission across all subdomains:
- **21.dev**: Static site sitemap with git-based lastmod dates
- **docs.21.dev**: DocC documentation sitemap (includes co-located markdown files)

Each subdomain maintains its own `sitemap.xml` and `robots.txt`, with automated submission to Google Search Console on production deployments.

**Setup & Configuration**: See [specs/001-sitemap-infrastructure/README.md](specs/001-sitemap-infrastructure/README.md) for API credential setup and monitoring instructions.

### Cloudflare Header Policy Matrix

| Subdomain | HTML Responses | Static Assets | Downloads / `.well-known` | Source |
|-----------|----------------|---------------|---------------------------|--------|
| **21.dev** | Prod: HSTS (max-age 63072000; includeSubDomains; preload), CSP allowing `self` + Cloudflare analytics, security headers, `Cache-Control: public, max-age=300, must-revalidate`, `Vary: Accept-Encoding`.<br>Preview: same minus HSTS. | `/static/*` + `/assets/*` use `Cache-Control: public, max-age=31536000, immutable` with `Vary: Accept-Encoding`. | `.json` + `/.well-known/*` run `Cache-Control: no-store` + `Pragma: no-cache`. | [Resources/21-dev/_headers](Resources/21-dev/_headers) |
| **docs.21.dev** | Prod DocC HTML matches security baseline + 5-minute cache; preview omits HSTS. Markdown files at `/data/documentation/**/*.md` served with `text/markdown` content type. | `/documentation/**/static/*` + `/js/*` use long-lived immutable cache. | `/.well-known/*` and JSON outputs set `Cache-Control: no-store`. | [Resources/docs-21-dev/_headers](Resources/docs-21-dev/_headers) |

**Verification**: Run the curl matrix in [specs/002-cloudflare-headers/quickstart.md](specs/002-cloudflare-headers/quickstart.md#verification-commands-curl) for each deployment (HTML, asset, download per site). Preview builds must always exclude HSTS, while production must include it for 21.dev and docs.21.dev HTML routes.