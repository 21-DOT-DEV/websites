# Data Model: Canonical URL Management

**Feature**: 005-canonical-url  
**Date**: 2025-12-30

## Entities

### CanonicalStatus

Enumeration representing the check result state for a single HTML file.

```swift
public enum CanonicalStatus: String, Sendable {
    case valid      // Existing canonical matches expected
    case mismatch   // Existing canonical differs from expected
    case missing    // No canonical tag present
    case error      // File could not be processed (parse error, no head, etc.)
}
```

**States**:
| Status | Description | CLI Display |
|--------|-------------|-------------|
| `valid` | Canonical tag exists and matches derived URL | ✅ |
| `mismatch` | Canonical tag exists but differs from derived URL | ⚠️ |
| `missing` | No `<link rel="canonical">` tag in `<head>` | ❌ |
| `error` | File could not be parsed or has structural issues | ⚠️ (with error message) |

### CanonicalResult

Represents the check result for a single HTML file.

```swift
public struct CanonicalResult: Sendable {
    /// Absolute path to the HTML file
    public let filePath: String
    
    /// Relative path from scan directory (used for URL derivation)
    public let relativePath: String
    
    /// Check result status
    public let status: CanonicalStatus
    
    /// Existing canonical URL found in file (nil if missing)
    public let existingURL: URL?
    
    /// Expected canonical URL derived from base URL + path
    public let expectedURL: URL
    
    /// Error message if status is .error
    public let errorMessage: String?
}
```

**Relationships**:
- Belongs to one `CheckReport`
- Status determined by comparing `existingURL` to `expectedURL`

**Validation Rules**:
- `filePath` must be absolute path
- `relativePath` must not start with `/`
- `expectedURL` must have http/https scheme
- `errorMessage` required when `status == .error`

### CheckReport

Aggregate container for all check results with summary statistics.

```swift
public struct CheckReport: Sendable {
    /// All individual file results
    public let results: [CanonicalResult]
    
    /// Base URL used for derivation
    public let baseURL: URL
    
    /// Directory that was scanned
    public let scanDirectory: String
    
    /// Summary counts
    public var validCount: Int { results.filter { $0.status == .valid }.count }
    public var mismatchCount: Int { results.filter { $0.status == .mismatch }.count }
    public var missingCount: Int { results.filter { $0.status == .missing }.count }
    public var errorCount: Int { results.filter { $0.status == .error }.count }
    public var totalCount: Int { results.count }
    
    /// Whether all files are valid (no issues found)
    public var isAllValid: Bool { mismatchCount == 0 && missingCount == 0 && errorCount == 0 }
}
```

**Computed Properties**:
- `validCount`, `mismatchCount`, `missingCount`, `errorCount`: Filtered counts
- `totalCount`: Total files processed
- `isAllValid`: True only if all files have `.valid` status

### FixResult

Represents the result of a fix operation on a single file.

```swift
public struct FixResult: Sendable {
    /// Path to the file
    public let filePath: String
    
    /// Action taken
    public let action: FixAction
    
    /// Error message if action is .failed
    public let errorMessage: String?
}

public enum FixAction: String, Sendable {
    case added      // Canonical tag was inserted
    case updated    // Existing canonical tag was replaced (--force)
    case skipped    // File already has canonical (no --force)
    case failed     // Error occurred during fix
}
```

### FixReport

Aggregate container for fix operation results.

```swift
public struct FixReport: Sendable {
    /// All individual fix results
    public let results: [FixResult]
    
    /// Summary counts
    public var addedCount: Int { results.filter { $0.action == .added }.count }
    public var updatedCount: Int { results.filter { $0.action == .updated }.count }
    public var skippedCount: Int { results.filter { $0.action == .skipped }.count }
    public var failedCount: Int { results.filter { $0.action == .failed }.count }
    
    /// Whether all operations succeeded (no failures)
    public var isSuccess: Bool { failedCount == 0 }
}
```

## Entity Relationships

```
CheckReport (1) ──────< CanonicalResult (many)
                              │
                              ▼
                       CanonicalStatus (enum)

FixReport (1) ─────────< FixResult (many)
                              │
                              ▼
                         FixAction (enum)
```

## State Transitions

### Check Flow
```
HTML File → Parse → Find Canonical Tag → Compare to Expected → CanonicalStatus
                │                              │
                ▼                              ▼
           Parse Error              valid / mismatch / missing
                │
                ▼
         status = .error
```

### Fix Flow
```
CanonicalResult → Determine Action → Apply Fix → FixResult

if status == .missing:
    action = .added (insert canonical)
    
if status == .mismatch && --force:
    action = .updated (replace canonical)
    
if status == .mismatch && !--force:
    action = .skipped
    
if status == .valid:
    action = .skipped (already correct)
    
if status == .error:
    action = .failed (cannot fix)
```

## Data Volume Assumptions

| Metric | Expected Range |
|--------|----------------|
| Files per subdomain | 100-1000 |
| Total files (all sites) | 500-3000 |
| File size (HTML) | 5KB - 500KB |
| Canonical tag size | ~50-100 bytes |

Performance target: Process 1000 files in < 5 seconds.
