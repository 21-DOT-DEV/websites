# Data Model: Sitemap Infrastructure

**Feature**: 001-sitemap-infrastructure  
**Date**: 2025-11-14  
**Phase**: 1 (Design & Contracts)

## Entity Definitions

> **Source of truth for XML tag structure**: Detailed sitemap element/tag schema (including full XML examples and protocol-level constraints) lives in `contracts/sitemap-schema.md`. This `data-model.md` focuses on the logical entities and their relationships.

### 1. URL Entry (Sitemap)

**Purpose**: Represents a single page URL in a sitemap.xml file

**XML Structure**:
```xml
<url>
  <loc>https://21.dev/packages/p256k/</loc>
  <lastmod>2025-11-14</lastmod>
</url>
```

**Fields**:

| Field | Type | Required | Format | Validation |
|-------|------|----------|--------|------------|
| `loc` | String | Yes | Absolute URL | Must start with `https://`, max 2,048 chars, XML-escaped |
| `lastmod` | String | Yes | ISO 8601 date | Format: `YYYY-MM-DD`, valid date |

**Validation Rules**:
- URL must include protocol (`https://`)
- URL must include domain (21.dev, docs.21.dev, or md.21.dev)
- Special characters must be XML-escaped: `& → &amp;`, `< → &lt;`, `> → &gt;`, `" → &quot;`, `' → &apos;`
- lastmod must be parseable as ISO 8601 date
- No future dates allowed in lastmod

**Example Instances**:
```xml
<!-- Homepage -->
<url>
  <loc>https://21.dev/</loc>
  <lastmod>2025-11-14</lastmod>
</url>

<!-- Blog post -->
<url>
  <loc>https://21.dev/blog/announcing-swift-secp256k1/</loc>
  <lastmod>2025-11-10</lastmod>
</url>

<!-- Documentation page -->
<url>
  <loc>https://docs.21.dev/documentation/p256k/</loc>
  <lastmod>2025-11-13</lastmod>
</url>
```

---

### 2. Sitemap Index Entry

**Purpose**: References a subdomain sitemap within the sitemap index

**XML Structure**:
```xml
<sitemap>
  <loc>https://docs.21.dev/sitemap.xml</loc>
  <lastmod>2025-11-14T19:30:00-08:00</lastmod>
</sitemap>
```

**Fields**:

| Field | Type | Required | Format | Validation |
|-------|------|----------|--------|------------|
| `loc` | String | Yes | Absolute URL to sitemap | Must be valid sitemap.xml URL, reachable via HTTP |
| `lastmod` | String | Yes | ISO 8601 timestamp | Format: `YYYY-MM-DDTHH:MM:SS±HH:MM`, includes timezone |

**Validation Rules**:
- Same URL validation as URL Entry
- lastmod must include time and timezone (not just date)
- Should be extracted from the referenced sitemap's own `<lastmod>` (for sitemaps) or generation timestamp (for sitemap index itself)

**Example Instances**:
```xml
<!-- 21.dev main sitemap -->
<sitemap>
  <loc>https://21.dev/sitemap-main.xml</loc>
  <lastmod>2025-11-14T19:30:00-08:00</lastmod>
</sitemap>

<!-- docs.21.dev sitemap -->
<sitemap>
  <loc>https://docs.21.dev/sitemap.xml</loc>
  <lastmod>2025-11-13T14:20:00-08:00</lastmod>
</sitemap>

<!-- md.21.dev sitemap -->
<sitemap>
  <loc>https://md.21.dev/sitemap.xml</loc>
  <lastmod>2025-11-13T14:20:00-08:00</lastmod>
</sitemap>
```

---

### 3. Sitemap State File

**Purpose**: Persists swift-secp256k1 package version and generation timestamp to enable lastmod preservation across builds

**File Location**: `Resources/sitemap-state.json` (git-tracked)

**JSON Structure**:
```json
{
  "package_version": "0.22.0",
  "generated_date": "2025-11-13T14:20:00-08:00"
}
```

**Fields**:

| Field | Type | Required | Format | Description |
|-------|------|----------|--------|-------------|
| `package_version` | String | Yes | Semver | swift-secp256k1 version from Package.resolved |
| `generated_date` | String | Yes | ISO 8601 timestamp | When docs/md sitemaps were last generated |

**Lifecycle**:
1. **Created**: First time docs or md sitemap is generated
2. **Read**: During sitemap generation to determine if lastmod should be preserved
3. **Updated**: When swift-secp256k1 version changes (via Lefthook hook)
4. **Committed**: Alongside Package.resolved changes

**Update Logic**:
```
IF swift-secp256k1 version in Package.resolved != package_version in state file:
  UPDATE state file with new version + current timestamp
  COMMIT alongside Package.resolved
ELSE:
  NO CHANGE (preserve existing lastmod)
```

**Fallback Behavior**:
- File missing → Create with current version + timestamp
- File corrupt → Log warning, recreate with current values
- Package version not found in Package.resolved → Error, fail build

---

### 4. Sitemap XML Document

**Purpose**: Complete sitemap.xml file with header and URL entries

**XML Structure**:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
  <url>
    <loc>https://21.dev/</loc>
    <lastmod>2025-11-14</lastmod>
  </url>
  <url>
    <loc>https://21.dev/packages/p256k/</loc>
    <lastmod>2025-11-13</lastmod>
  </url>
</urlset>
```

**Components**:
- XML declaration: `<?xml version="1.0" encoding="UTF-8"?>`
- Root element: `<urlset>` with namespace
- Multiple `<url>` entries

**Validation**:
- Well-formed XML
- Valid namespace
- Maximum 50,000 `<url>` entries
- Maximum 50MB uncompressed size
- Each URL entry valid per URL Entry model

---

### 5. Sitemap Index Document

**Purpose**: Aggregates references to all subdomain sitemaps

**XML Structure**:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<sitemapindex xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
  <sitemap>
    <loc>https://21.dev/sitemap-main.xml</loc>
    <lastmod>2025-11-14T19:30:00-08:00</lastmod>
  </sitemap>
  <sitemap>
    <loc>https://docs.21.dev/sitemap.xml</loc>
    <lastmod>2025-11-13T14:20:00-08:00</lastmod>
  </sitemap>
  <sitemap>
    <loc>https://md.21.dev/sitemap.xml</loc>
    <lastmod>2025-11-13T14:20:00-08:00</lastmod>
  </sitemap>
</sitemapindex>
```

**Components**:
- XML declaration: `<?xml version="1.0" encoding="UTF-8"?>`
- Root element: `<sitemapindex>` with namespace
- Multiple `<sitemap>` entries

**Generation Strategy**:
1. Fetch `https://21.dev/sitemap-main.xml` → Parse for lastmod (or use current timestamp)
2. Fetch `https://docs.21.dev/sitemap.xml` → Parse for lastmod
3. Fetch `https://md.21.dev/sitemap.xml` → Parse for lastmod
4. Generate index with all three entries
5. If any fetch fails → Log warning, omit from index (partial index OK)

---

## Relationships

```
Sitemap Index (21.dev/sitemap.xml)
├── References: 21.dev/sitemap-main.xml (Sitemap Document)
│   └── Contains: Multiple URL Entries (21.dev pages)
├── References: docs.21.dev/sitemap.xml (Sitemap Document)
│   └── Contains: Multiple URL Entries (documentation pages)
└── References: md.21.dev/sitemap.xml (Sitemap Document)
    └── Contains: Multiple URL Entries (markdown files)

Sitemap State File (Resources/sitemap-state.json)
└── Controls lastmod for: docs.21.dev + md.21.dev sitemaps
```

---

## State Transitions

### URL Entry lastmod Lifecycle

**21.dev pages**:
```
Source file modified (git commit) 
  → git log extracts commit timestamp 
  → lastmod updated in sitemap
```

**docs.21.dev / md.21.dev pages**:
```
Package.resolved changes (swift-secp256k1 version bump)
  → Lefthook detects change
  → Updates sitemap-state.json
  → Developer commits state file
  → Next sitemap generation uses new timestamp
  → All docs/md page lastmod values update
```

### Sitemap Index lastmod Lifecycle

```
Subdomain sitemap regenerated
  → Sitemap deployed with new lastmod
  → 21.dev deployment fetches sitemap
  → Extracts lastmod from subdomain sitemap
  → Updates sitemap index entry
  → Index deployed with updated reference
```

---

## Volume & Scale

**Current Scale** (as of 2025-11-14):
- 21.dev: ~5 pages (homepage, package page, blog posts)
- docs.21.dev: ~20-30 documentation pages
- md.21.dev: ~20-30 markdown files
- **Total**: ~50-65 URLs across all sitemaps

**Growth Projections**:
- Year 1: ~100-200 URLs (more blog posts, package pages)
- Year 2: ~500-1,000 URLs (expanded docs, multiple packages)
- Sitemap protocol limit: 50,000 URLs (well within capacity)

**Performance Targets**:
- Sitemap generation: < 5 seconds per subdomain
- State file read/write: < 100ms
- Git log queries: < 1 second total for all files
- Sitemap index generation: < 2 seconds (includes HTTP fetches)
