# Data Model: Utilities Library Extraction

**Feature**: 004-utilities-library  
**Date**: 2025-12-15

## Entities

### SitemapEntry

Represents a single URL entry in a sitemap.

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| url | String | Yes | Absolute URL (must be valid HTTP/HTTPS, max 2048 chars) |
| lastmod | Date | Yes | Last modification date in ISO8601 format |

**Validation Rules**:
- URL must use HTTP or HTTPS scheme
- URL must have a valid host
- URL length ≤ 2048 characters (sitemap protocol limit)
- lastmod must be valid ISO8601 date

**Swift Definition**:
```swift
public struct SitemapEntry: Codable, Equatable {
    public let url: String
    public let lastmod: Date
    
    public init(url: String, lastmod: Date) throws {
        guard isValidSitemapURL(url) else {
            throw SitemapError.invalidURL(url)
        }
        self.url = url
        self.lastmod = lastmod
    }
}
```

---

### SiteConfiguration

Configuration for a specific site/subdomain.

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| name | SiteName | Yes | Site identifier enum |
| outputDirectory | String | Yes | Path to built site output (e.g., `Websites/21-dev/`) |
| baseURL | String | Yes | Base URL for the site (e.g., `https://21.dev`) |
| urlDiscoveryStrategy | URLDiscoveryStrategy | Yes | How to find URLs in the output |
| lastmodStrategy | LastmodStrategy | Yes | How to determine lastmod dates |

**SiteName Enum**:
```swift
public enum SiteName: String, CaseIterable, Codable {
    case dev21 = "21-dev"
    case docs21dev = "docs-21-dev"
    case md21dev = "md-21-dev"
    
    public var baseURL: String {
        switch self {
        case .dev21: return "https://21.dev"
        case .docs21dev: return "https://docs.21.dev"
        case .md21dev: return "https://md.21.dev"
        }
    }
    
    public var outputDirectory: String {
        return "Websites/\(rawValue)"
    }
}
```

**URLDiscoveryStrategy Enum**:
```swift
public enum URLDiscoveryStrategy {
    case htmlFiles(directory: String)      // Scan for .html files
    case markdownFiles(directory: String)  // Scan for .md files
    case sitemapDictionary                 // Use Slipstream Sitemap dictionary
}
```

**LastmodStrategy Enum**:
```swift
public enum LastmodStrategy {
    case gitCommitDate       // Use git log for file's last commit
    case packageVersionState // Use state file's generated_date
    case currentDate         // Fallback to now
}
```

---

### StateFile

Tracks package version and generation dates for docs/md sitemaps.

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| packageVersion | String | Yes | Current swift-secp256k1 package version |
| generatedDate | Date | Yes | When state was last updated |
| subdomains | [String: SubdomainState] | Yes | Per-subdomain state |

**SubdomainState**:
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| lastmod | Date | Yes | Last modification date for this subdomain |

**JSON Schema**:
```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "type": "object",
  "required": ["package_version", "generated_date", "subdomains"],
  "properties": {
    "package_version": { "type": "string", "pattern": "^\\d+\\.\\d+\\.\\d+$" },
    "generated_date": { "type": "string", "format": "date-time" },
    "subdomains": {
      "type": "object",
      "additionalProperties": {
        "type": "object",
        "required": ["lastmod"],
        "properties": {
          "lastmod": { "type": "string", "format": "date-time" }
        }
      }
    }
  }
}
```

**Swift Definition**:
```swift
public struct StateFile: Codable {
    public var packageVersion: String
    public var generatedDate: Date
    public var subdomains: [String: SubdomainState]
    
    enum CodingKeys: String, CodingKey {
        case packageVersion = "package_version"
        case generatedDate = "generated_date"
        case subdomains
    }
}

public struct SubdomainState: Codable {
    public var lastmod: Date
}
```

---

### ValidationResult

Result of a validation operation (sitemap, headers, state).

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| isValid | Bool | Yes | Overall pass/fail status |
| errors | [ValidationError] | Yes | List of errors (empty if valid) |
| warnings | [String] | No | Non-fatal warnings |

**ValidationError**:
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| code | String | Yes | Error code (e.g., `INVALID_URL`, `MISSING_HEADER`) |
| message | String | Yes | Human-readable error message |
| location | String? | No | File path or line number if applicable |

**Swift Definition**:
```swift
public struct ValidationResult {
    public let isValid: Bool
    public let errors: [ValidationError]
    public let warnings: [String]
    
    public static func success(warnings: [String] = []) -> ValidationResult {
        ValidationResult(isValid: true, errors: [], warnings: warnings)
    }
    
    public static func failure(_ errors: [ValidationError]) -> ValidationResult {
        ValidationResult(isValid: false, errors: errors, warnings: [])
    }
}

public struct ValidationError: Error, CustomStringConvertible {
    public let code: String
    public let message: String
    public let location: String?
    
    public var description: String {
        if let location = location {
            return "[\(code)] \(message) at \(location)"
        }
        return "[\(code)] \(message)"
    }
}
```

---

## Relationships

```
┌─────────────────┐     generates     ┌──────────────┐
│ SiteConfiguration│ ───────────────▶ │ SitemapEntry │
└─────────────────┘                   └──────────────┘
        │                                    │
        │ uses                               │ validated by
        ▼                                    ▼
┌─────────────────┐                  ┌──────────────────┐
│    StateFile    │                  │ ValidationResult │
└─────────────────┘                  └──────────────────┘
```

## State Transitions

### StateFile Lifecycle

```
┌─────────────┐   create    ┌──────────────┐   update    ┌──────────────┐
│  Not Exists │ ──────────▶ │   Created    │ ──────────▶ │   Updated    │
└─────────────┘             └──────────────┘             └──────────────┘
                                   │                           │
                                   │         validate          │
                                   └───────────┬───────────────┘
                                               ▼
                                       ┌──────────────┐
                                       │   Validated  │
                                       └──────────────┘
```

**Transitions**:
- `Not Exists → Created`: `util state update` with no existing file
- `Created → Updated`: `util state update --package-version X.Y.Z`
- `* → Validated`: `util state validate` (read-only check)
