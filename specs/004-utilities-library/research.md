# Research: Utilities Library Extraction

**Feature**: 004-utilities-library  
**Date**: 2025-12-15  
**Status**: Complete

## Research Tasks

### 1. Swift ArgumentParser Best Practices

**Decision**: Use swift-argument-parser with nested subcommand structure

**Rationale**:
- Apple's official CLI library, actively maintained
- Automatic `--help` generation for all commands
- Type-safe argument parsing with validation
- Supports nested subcommands (e.g., `util sitemap generate`)
- Built-in support for async commands via `AsyncParsableCommand`

**Alternatives Considered**:
- **Manual CommandLine.arguments parsing**: Rejected — error-prone, no help generation, violates KISS
- **swift-sh scripting**: Rejected — not suitable for complex subcommand structure
- **Vapor's ConsoleKit**: Rejected — heavier dependency, designed for server apps

**Implementation Pattern**:
```swift
@main
struct Util: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "util",
        abstract: "CLI utilities for 21.dev websites",
        subcommands: [Sitemap.self, Headers.self, State.self]
    )
}
```

### 2. Library + Executable Pattern in SPM

**Decision**: Separate `Utilities` library target and `util` executable target

**Rationale**:
- Library can be consumed by multiple targets (CLI, tests, DesignSystem re-export)
- Executable stays thin (argument parsing + calling library APIs)
- Follows Swift community conventions (swift-format, swift-lint use this pattern)
- Enables unit testing of library without process invocation

**Package.swift Structure**:
```swift
.target(
    name: "Utilities",
    dependencies: [
        .product(name: "Subprocess", package: "swift-subprocess")
    ]
),
.executableTarget(
    name: "util",
    dependencies: [
        .target(name: "Utilities"),
        .product(name: "ArgumentParser", package: "swift-argument-parser")
    ]
)
```

### 3. Backward Compatibility via Re-exports

**Decision**: DesignSystem re-exports Utilities APIs with deprecation warnings

**Rationale**:
- Existing code continues to work without changes
- Deprecation warnings guide migration
- Clean break in future release after consumers migrate

**Implementation Pattern**:
```swift
// In Sources/DesignSystem/Utilities/SitemapUtilities.swift
@_exported import Utilities

@available(*, deprecated, message: "Import Utilities directly instead of DesignSystem")
public typealias SitemapEntry = Utilities.SitemapEntry
```

**Alternative Considered**:
- **Immediate breaking change**: Rejected — violates backward compatibility requirement (FR-004)
- **Duplicate code**: Rejected — violates DRY, constitution Principle IV

### 4. Headers Validation Strategy

**Decision**: Build fresh implementation based on Cloudflare _headers format

**Rationale**:
- No existing HeadersValidator code to migrate
- Cloudflare _headers format is well-documented
- Can leverage existing specs/002-cloudflare-headers knowledge

**Validation Rules** (from Cloudflare docs):
- File must be valid text format
- Headers follow `path\n  header: value` format
- Security headers required for prod (CSP, X-Frame-Options, etc.)
- Dev environment may have relaxed rules

### 5. CLI Integration Testing Approach

**Decision**: Process invocation tests using swift-subprocess

**Rationale**:
- Tests CLI end-to-end including argument parsing
- Validates exit codes and output format
- Can run in CI without special setup

**Implementation Pattern**:
```swift
@Test func sitemapGenerateHelp() async throws {
    let result = try await Subprocess.run(
        .path("/path/to/.build/debug/util"),
        arguments: ["sitemap", "generate", "--help"]
    )
    #expect(result.terminationStatus == .exited(0))
    #expect(result.standardOutput?.contains("--site") == true)
}
```

### 6. State File JSON Schema

**Decision**: Simple JSON structure with version and timestamps

**Rationale**:
- Human-readable for debugging
- Easy to parse with Codable
- Matches existing `Resources/sitemap-state.json` format

**Schema**:
```json
{
  "package_version": "0.21.1",
  "generated_date": "2025-12-15T08:30:00Z",
  "subdomains": {
    "docs-21-dev": { "lastmod": "2025-12-15T08:30:00Z" },
    "md-21-dev": { "lastmod": "2025-12-15T08:30:00Z" }
  }
}
```

## Resolved Clarifications

All NEEDS CLARIFICATION items from Technical Context have been resolved:

| Item | Resolution |
|------|------------|
| ArgumentParser dependency | Approved — build-time tooling exception |
| Testing strategy | Unit tests for library + integration tests for CLI |
| Workflow migration scope | Deferred to Feature 2 |
| HeadersValidator source | New implementation (no existing code) |
| Backward compatibility | Re-exports with deprecation warnings |

## Dependencies Confirmed

| Dependency | Version | Purpose | Status |
|------------|---------|---------|--------|
| swift-subprocess | 0.2.1 | Process execution for git, CLI tests | Already in Package.swift |
| swift-argument-parser | latest | CLI argument parsing | NEW — add to Package.swift |
| swift-testing | latest | Unit and integration tests | Already available |
