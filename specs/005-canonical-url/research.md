# Research: Canonical URL Management

**Feature**: 005-canonical-url  
**Date**: 2025-12-30  
**Status**: Complete

## Research Questions

### 1. HTML Parsing Approach

**Decision**: Use SwiftSoup 2.8.8 (matching Slipstream's version)

**Rationale**: 
- SwiftSoup is already a transitive dependency via Slipstream
- Provides robust HTML parsing with DOM manipulation capabilities
- Handles malformed HTML gracefully
- Well-documented API for finding and modifying elements

**Alternatives Considered**:
- **Regex-based parsing**: Fast but fragile with edge cases (rejected)
- **Line-by-line scanning**: No dependency but less robust (rejected)
- **Foundation XMLParser**: Strict XML parsing, fails on HTML5 (rejected)

### 2. Canonical Tag Insertion Location

**Decision**: Append to end of `<head>` section

**Rationale**:
- Safest approach for varied HTML structures (DocC, Slipstream, etc.)
- Avoids accidentally breaking existing tag relationships
- Canonical position within `<head>` has no SEO impact—only presence matters
- SwiftSoup's `appendChild` makes this straightforward

**Alternatives Considered**:
- **After `<title>`**: Common convention but requires finding specific element (rejected—adds complexity)
- **After charset/viewport**: Groups with SEO tags but assumes specific structure (rejected)

### 3. URL Derivation Strategy

**Decision**: `base-url + normalized-relative-path`

**Rationale**:
- Simple, predictable derivation from filesystem structure
- Matches how static site generators map files to URLs
- Normalization rules:
  - `index.html` → trailing slash (e.g., `/docs/index.html` → `/docs/`)
  - Remove `.html` extension for non-index files (e.g., `/about.html` → `/about`)
  - Ensure consistent trailing slash handling

**Implementation**:
```swift
func deriveCanonicalURL(baseURL: URL, relativePath: String) -> URL {
    var path = relativePath
    
    // Normalize index.html to directory with trailing slash
    if path.hasSuffix("/index.html") {
        path = String(path.dropLast(10)) + "/"
    } else if path == "index.html" {
        path = "/"
    }
    
    return baseURL.appendingPathComponent(path)
}
```

### 4. Test Strategy

**Decision**: Unit tests (UtilitiesTests) + Integration tests (UtilitiesCLITests)

**Rationale**:
- Matches existing test structure in Package.swift
- Unit tests cover parsing/fixing logic with fixture HTML strings
- Integration tests verify CLI behavior with actual file operations
- TDD approach: write tests first per constitution

**Test Categories**:
1. **CanonicalCheckerTests**: Parsing HTML, detecting canonical tags, categorizing results
2. **CanonicalFixerTests**: Inserting/updating canonical tags, preserving formatting
3. **CanonicalURLDeriverTests**: Path normalization, URL construction
4. **CanonicalCLITests**: End-to-end CLI invocation, exit codes, output format

### 5. SwiftSoup Integration

**Decision**: Add SwiftSoup as explicit dependency to Utilities target

**Rationale**:
- Already transitive via Slipstream—no net-new dependency
- Version 2.8.8 matches Slipstream to avoid conflicts
- Enables direct `import SwiftSoup` in Utilities code

**Package.swift Change**:
```swift
.target(
    name: "Utilities",
    dependencies: [
        .product(name: "Subprocess", package: "swift-subprocess"),
        .product(name: "SwiftSoup", package: "SwiftSoup"),  // Add this
    ]
),
```

**Package Dependency**:
```swift
.package(url: "https://github.com/scinfu/SwiftSoup.git", from: "2.8.8"),
```

### 6. CLI Flags and Behavior

**Decision**: Follow existing `util` command patterns

**Flags**:
- `--path <dir>` (required): Directory to scan
- `--base-url <url>` (required): Base URL for canonical derivation
- `--verbose` / `-v`: Detailed output
- `--force` (fix only): Overwrite existing canonicals
- `--dry-run` (fix only): Preview changes without writing

**Exit Codes**:
- `0`: All canonicals valid (check) or all fixes successful (fix)
- `1`: Issues found (check) or errors during fix (fix)

**Output Format**: Human-readable with emoji indicators (✅ ⚠️ ❌)

### 7. Edge Case Handling

| Edge Case | Handling |
|-----------|----------|
| No `<head>` section | Skip file, warn |
| Multiple canonical tags | Report as error, do not modify |
| Malformed HTML | SwiftSoup handles gracefully; skip if parse fails |
| Binary file with .html extension | SwiftSoup will fail to parse; skip with warning |
| Symbolic links | Follow by default (standard FileManager behavior) |
| Empty directory | Report "0 files processed", exit 0 |
| `--base-url` without scheme | Validate and reject with clear error message |

## Dependencies Verified

| Dependency | Version | Purpose | Status |
|------------|---------|---------|--------|
| SwiftSoup | 2.8.8 | HTML parsing/manipulation | ✅ Available (via Slipstream) |
| ArgumentParser | existing | CLI interface | ✅ Already in use |
| swift-testing | existing | Unit/integration tests | ✅ Already in use |

## Risks and Mitigations

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| SwiftSoup version conflict | Low | Medium | Pin to exact version matching Slipstream |
| DocC HTML structure incompatible | Low | High | Test against actual DocC output early |
| Performance bottleneck on large sites | Low | Medium | Profile and optimize if needed; current sites are small |

## Next Steps

1. Create data-model.md with entity definitions
2. Define CLI contracts in contracts/
3. Write quickstart.md with usage examples
4. Proceed to /speckit.tasks for task breakdown
