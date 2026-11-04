# Sitemap XML Schema

**Feature**: 001-sitemap-infrastructure  
**Protocol**: Sitemap 0.9  
**Reference**: https://www.sitemaps.org/protocol.html

## Sitemap Document Schema

### XML Namespace
```
http://www.sitemaps.org/schemas/sitemap/0.9
```

### Root Element: `<urlset>`

**Attributes**:
- `xmlns` (required): Must be `"http://www.sitemaps.org/schemas/sitemap/0.9"`

**Child Elements**: One or more `<url>` elements

**Constraints**:
- Maximum 50,000 `<url>` elements per file
- Maximum 50MB uncompressed size
- If limits exceeded, split into multiple sitemaps and use sitemap index

---

### URL Element: `<url>`

**Parent**: `<urlset>`

**Required Child Elements**:
- `<loc>`: URL of the page

**Optional Child Elements** (not used in this implementation):
- `<priority>`: Priority of this URL (0.0 to 1.0)
- `<changefreq>`: How frequently page changes

**Implementation-Specific**:
- `<lastmod>`: Last modification date (REQUIRED in this implementation)

---

### Location Element: `<loc>`

**Parent**: `<url>`

**Content**: Absolute URL string

**Format Requirements**:
- Must include protocol (https://)
- Must include domain
- Maximum 2,048 characters
- Special characters must be XML-escaped:
  - `&` → `&amp;`
  - `<` → `&lt;`
  - `>` → `&gt;`
  - `"` → `&quot;`
  - `'` → `&apos;`

**Examples**:
```xml
<loc>https://21.dev/</loc>
<loc>https://21.dev/packages/p256k/</loc>
<loc>https://docs.21.dev/documentation/p256k/privatekey/</loc>
```

---

### Last Modified Element: `<lastmod>`

**Parent**: `<url>`

**Content**: ISO 8601 date or datetime string

**Supported Formats**:
- Date only: `YYYY-MM-DD` (e.g., `2025-11-14`)
- Date with time: `YYYY-MM-DDTHH:MM:SS` (e.g., `2025-11-14T19:30:00`)
- Date with time and timezone: `YYYY-MM-DDTHH:MM:SS±HH:MM` (e.g., `2025-11-14T19:30:00-08:00`)

**Implementation Choice**: Date only (`YYYY-MM-DD`) for individual page sitemaps

**Examples**:
```xml
<lastmod>2025-11-14</lastmod>
<lastmod>2025-11-13</lastmod>
<lastmod>2025-11-10</lastmod>
```

---

## Complete Sitemap Example

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
  <url>
    <loc>https://21.dev/blog/</loc>
    <lastmod>2025-11-12</lastmod>
  </url>
  <url>
    <loc>https://21.dev/blog/announcing-swift-secp256k1/</loc>
    <lastmod>2025-11-10</lastmod>
  </url>
</urlset>
```

---

## Sitemap Index Schema

### Root Element: `<sitemapindex>`

**Attributes**:
- `xmlns` (required): Must be `"http://www.sitemaps.org/schemas/sitemap/0.9"`

**Child Elements**: One or more `<sitemap>` elements

**Constraints**:
- Maximum 50,000 `<sitemap>` elements
- Maximum 50MB uncompressed size

---

### Sitemap Reference Element: `<sitemap>`

**Parent**: `<sitemapindex>`

**Required Child Elements**:
- `<loc>`: URL of the sitemap

**Optional Child Elements**:
- `<lastmod>`: Last modification date of the sitemap file (REQUIRED in this implementation)

---

### Sitemap Index Example

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

---

## Validation

### XML Well-formedness
- Valid XML declaration
- Proper namespace declaration
- All tags properly closed
- No invalid characters in content

### Protocol Compliance
- Correct namespace URI
- Required elements present
- URL format valid
- Size/count limits respected

### Online Validators
- https://www.xml-sitemaps.com/validate-xml-sitemap.html
- https://technicalseo.com/tools/sitemap-validator/
- Google Search Console (after submission)

---

## Error Handling

**Invalid URL Format**:
- Log error with specific URL
- Skip invalid URL, continue with others
- Report count of skipped URLs

**XML Escaping Failures**:
- Apply escaping before adding to sitemap
- Test with URLs containing special chars

**Size Limit Exceeded**:
- Monitor URL count during generation
- Split into multiple sitemaps if approaching 50,000
- Use sitemap index to reference splits

**Encoding Issues**:
- Always use UTF-8 encoding
- Declare encoding in XML header
- Test with non-ASCII characters in URLs
