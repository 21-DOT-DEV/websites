# Util CLI Architecture

**Purpose**: Documents the library + executable pattern for the util CLI tool  
**Updated**: 2026-01-04  
**Related**: See subtree project for similar pattern

## Architecture Pattern

The util CLI follows the **library + executable** pattern, separating business logic from CLI concerns:

```
Sources/
├── UtilLib/              # Library (all business logic)
│   ├── Canonical/        # Canonical URL utilities
│   ├── Headers/          # Headers validation
│   ├── Sitemap/          # Sitemap generation
│   └── State/            # State management
└── util/                 # Executable (CLI wrapper)
    ├── Util.swift        # Entry point, ArgumentParser commands
    └── Commands/         # Command implementations
```

## Key Design Decision: ArgumentParser Placement

**ArgumentParser stays in the util executable, NOT in UtilLib.**

**Rationale**: UtilLib is consumed programmatically by multiple targets:
- `21-dev` (main site generator)
- `DesignSystem` (component library)
- `IntegrationTests` (site integration tests)
- `DesignSystemTests` (component tests)

These consumers need lightweight utilities for sitemap generation, canonical URLs, headers validation, and state management. They do **not** need CLI argument parsing overhead.

**This differs from the subtree pattern**, where SubtreeLib is only used for testing and can include ArgumentParser without bloating other consumers.

## Testing Architecture

### UtilLibTests: Unit Testing

**Location**: `Tests/UtilLibTests/`  
**Purpose**: Test library internals directly  
**Access**: Uses `@testable import UtilLib` for internal API access  
**Dependencies**: Only UtilLib

**Example**:
```swift
import Testing
@testable import UtilLib

@Suite("CanonicalChecker Tests")
struct CanonicalCheckerTests {
    @Test("Check detects missing canonical tags")
    func testMissingCanonical() async throws {
        let checker = CanonicalChecker()
        let result = await checker.check(/* ... */)
        #expect(result.status == .missing)
    }
}
```

**When to use**: Testing business logic, data models, utilities, algorithms.

### UtilIntegrationTests: Black-Box Testing

**Location**: `Tests/UtilIntegrationTests/`  
**Purpose**: Test CLI end-to-end via subprocess execution  
**Access**: **Zero dependency on UtilLib or util executable**  
**Dependencies**: Only `swift-subprocess`  
**Tool**: TestHarness for CLI execution

**Example**:
```swift
import Testing
import Subprocess
import System

@Suite("Canonical CLI Tests")
struct CanonicalCLITests {
    let harness = TestHarness()
    
    @Test("canonical check requires --base-url")
    func testRequiresBaseURL() async throws {
        let result = try await harness.run(
            arguments: ["canonical", "check", "--path", "/tmp"]
        )
        #expect(result.exitCode != 0)
        #expect(result.stderr.contains("base-url"))
    }
}
```

**When to use**: Testing CLI behavior, argument validation, output formatting, exit codes.

## TestHarness Utility

**Location**: `Tests/UtilIntegrationTests/TestHarness.swift`  
**Purpose**: Execute CLI commands and capture results

**API**:
```swift
struct TestHarness {
    let executablePath: FilePath
    
    init() // Uses .build/debug/util
    init(executablePath: String) // Custom path
    
    func run(
        arguments: [String],
        workingDirectory: FilePath? = nil
    ) async throws -> CommandResult
}

struct CommandResult {
    let stdout: String
    let stderr: String
    let exitCode: Int
    var succeeded: Bool { exitCode == 0 }
}
```

**Implementation notes**:
- Uses `System.FilePath` (compatible with swift-subprocess)
- Executes via `Subprocess.run(.path(executablePath), ...)`
- Captures stdout/stderr with 65KB limits
- Returns structured result for assertions

## Package.swift Structure

```swift
.target(
    name: "UtilLib",
    dependencies: [
        .product(name: "Subprocess", package: "swift-subprocess"),
        .product(name: "SwiftSoup", package: "SwiftSoup")
    ]
    // Note: NO ArgumentParser dependency
),
.executableTarget(
    name: "util",
    dependencies: [
        .target(name: "UtilLib"),
        .product(name: "ArgumentParser", package: "swift-argument-parser")
    ]
),
.testTarget(
    name: "UtilLibTests",
    dependencies: ["UtilLib"]
),
.testTarget(
    name: "UtilIntegrationTests",
    dependencies: [
        .product(name: "Subprocess", package: "swift-subprocess")
    ]
    // Note: NO UtilLib, NO util, NO TestUtils
)
```

## Migration Summary

**From**:
- `Utilities` target with mixed CLI + library code
- `UtilitiesTests` with `@testable import Utilities`
- `UtilitiesCLITests` depending on both Utilities and util

**To**:
- `UtilLib` target with pure business logic
- `util` executable with ArgumentParser + commands
- `UtilLibTests` with `@testable import UtilLib`
- `UtilIntegrationTests` with zero coupling (TestHarness only)

**Benefits**:
- Clear separation: library logic vs CLI concerns
- Lightweight UtilLib for programmatic consumers
- Proper black-box integration testing
- Reusable pattern for future CLI tools

## Related Patterns

See **subtree** project (`/Users/csjones/Developer/subtree/`) for similar architecture with these differences:
- **subtree**: ArgumentParser in SubtreeLib (no programmatic consumers)
- **websites**: ArgumentParser in util (multiple programmatic consumers)
