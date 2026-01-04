# Data Model: Util CLI Architecture Alignment

**Feature**: 006-util-lib-executable  
**Date**: 2026-01-04  
**Purpose**: Define structural changes to Package.swift and test architecture

---

## Package.swift Target Definitions

### Current Structure (Before Refactor)

```swift
.target(
    name: "Utilities",
    dependencies: [
        .product(name: "Subprocess", package: "swift-subprocess"),
        .product(name: "SwiftSoup", package: "SwiftSoup")
    ]
),
.executableTarget(
    name: "util",
    dependencies: [
        .target(name: "Utilities"),
        .product(name: "ArgumentParser", package: "swift-argument-parser")
    ]
),
.testTarget(
    name: "UtilitiesTests",
    dependencies: ["Utilities"]
),
.testTarget(
    name: "UtilitiesCLITests",
    dependencies: [
        "Utilities",
        "util",
        "TestUtils",
        .product(name: "Subprocess", package: "swift-subprocess")
    ]
)
```

### Target Structure (After Refactor)

```swift
.target(
    name: "UtilLib",  // RENAMED from Utilities
    dependencies: [
        .product(name: "Subprocess", package: "swift-subprocess"),
        .product(name: "SwiftSoup", package: "SwiftSoup")
    ]
    // NO ArgumentParser - keeps library lightweight
),
.executableTarget(
    name: "util",  // unchanged
    dependencies: [
        .target(name: "UtilLib"),  // UPDATED dependency
        .product(name: "ArgumentParser", package: "swift-argument-parser")
    ]
),
.testTarget(
    name: "UtilLibTests",  // RENAMED from UtilitiesTests
    dependencies: ["UtilLib"]  // UPDATED dependency
),
.testTarget(
    name: "UtilIntegrationTests",  // RENAMED from UtilitiesCLITests
    dependencies: [
        .product(name: "Subprocess", package: "swift-subprocess")
        // REMOVED: UtilLib, util, TestUtils
    ]
)
```

### Changes Summary

| Aspect | Before | After | Rationale |
|--------|--------|-------|-----------|
| Library target name | Utilities | UtilLib | Consistent naming (util CLI → UtilLib library) |
| Library directory | Sources/Utilities/ | Sources/UtilLib/ | Matches target name (SPM convention) |
| Unit test target | UtilitiesTests | UtilLibTests | Follows library rename |
| Unit test directory | Tests/UtilitiesTests/ | Tests/UtilLibTests/ | Matches target name |
| Integration test target | UtilitiesCLITests | UtilIntegrationTests | Clearer purpose (black-box CLI testing) |
| Integration test directory | Tests/UtilitiesCLITests/ | Tests/UtilIntegrationTests/ | Matches target name |
| Integration test deps | [UtilLib, util, TestUtils, Subprocess] | [Subprocess only] | Pure black-box (zero coupling) |
| ArgumentParser location | util executable | util executable (unchanged) | Keeps UtilLib lightweight |

---

## TestHarness API Structure

### CommandResult Data Model

```swift
/// Result of a CLI command execution
struct CommandResult {
    /// Standard output captured from command
    let stdout: String
    
    /// Standard error output captured from command
    let stderr: String
    
    /// Exit code from command execution
    let exitCode: Int
    
    /// Convenience property: true if exitCode == 0
    var succeeded: Bool {
        exitCode == 0
    }
}
```

**Properties**:
- `stdout`: Complete stdout output as String (limit: 65536 bytes)
- `stderr`: Complete stderr output as String (limit: 65536 bytes)
- `exitCode`: Integer exit code (0 = success, non-zero = error)
- `succeeded`: Computed property for quick success checks

### TestHarness Data Model

```swift
/// Test harness for executing util CLI in integration tests
struct TestHarness {
    /// Path to the util executable
    let executablePath: String
    
    /// Initialize with default debug build path
    init() {
        let currentDirectory = FileManager.default.currentDirectoryPath
        self.executablePath = "\(currentDirectory)/.build/debug/util"
    }
    
    /// Initialize with custom executable path
    init(executablePath: String) {
        self.executablePath = executablePath
    }
    
    /// Run CLI command with given arguments
    /// - Parameters:
    ///   - arguments: Command-line arguments to pass to util
    ///   - workingDirectory: Optional working directory for command
    /// - Returns: CommandResult with stdout, stderr, and exit code
    /// - Throws: If subprocess execution fails
    func run(arguments: [String], workingDirectory: String? = nil) async throws -> CommandResult
}
```

**Properties**:
- `executablePath`: String path to util binary (default: `.build/debug/util`)

**Methods**:
- `init()`: Default initializer uses `.build/debug/util`
- `init(executablePath:)`: Custom path for special test scenarios
- `run(arguments:workingDirectory:)`: Executes CLI and returns result

**Error Handling**:
- Throws if subprocess fails to execute (binary not found, permission denied)
- Non-zero exit codes returned in CommandResult (not thrown)

---

## Import Graph Changes

### Consumer Dependencies (Before)

```
21-dev → Utilities
DesignSystem → Utilities
IntegrationTests → Utilities
DesignSystemTests → Utilities
util → Utilities + ArgumentParser
UtilitiesTests → Utilities
UtilitiesCLITests → Utilities + util + TestUtils + Subprocess
```

### Consumer Dependencies (After)

```
21-dev → UtilLib
DesignSystem → UtilLib
IntegrationTests → UtilLib
DesignSystemTests → UtilLib
util → UtilLib + ArgumentParser
UtilLibTests → UtilLib
UtilIntegrationTests → Subprocess (only)
```

### Import Statement Changes

**All Consumers** (21-dev, DesignSystem, IntegrationTests, DesignSystemTests):
```swift
// Before
import Utilities

// After
import UtilLib
```

**UtilLibTests**:
```swift
// Before
@testable import Utilities

// After
@testable import UtilLib
```

**UtilIntegrationTests**:
```swift
// Before
import Utilities  // REMOVED
import util       // REMOVED
import TestUtils  // REMOVED
import Subprocess

// After
import Subprocess  // Only dependency
// TestHarness inline in same target (no import needed)
```

---

## Directory Structure Changes

### File Moves

| Before | After | Method |
|--------|-------|--------|
| Sources/Utilities/ | Sources/UtilLib/ | `git mv` (preserves history) |
| Tests/UtilitiesTests/ | Tests/UtilLibTests/ | `git mv` (preserves history) |
| Tests/UtilitiesCLITests/ | Tests/UtilIntegrationTests/ | `git mv` (preserves history) |

### New Files

| Path | Purpose |
|------|---------|
| Tests/UtilIntegrationTests/TestHarness.swift | CLI execution utility (adapted from subtree) |
| .windsurf/rules/util-architecture.md | Architecture documentation |

### Unchanged Files

- `Sources/util/` - CLI executable (no file changes, only Package.swift dependency update)
- All existing test files (only directory moves + import updates)
- All business logic in UtilLib subdirectories (Canonical/, Headers/, etc.)

---

## Test Architecture Model

### UtilLibTests (Unit Tests)

**Purpose**: Test business logic in isolation

**Structure**:
```
Tests/UtilLibTests/
├── [existing test files]
└── [test imports updated to @testable import UtilLib]
```

**Dependencies**: UtilLib only
**Access**: `@testable import` for internal API testing
**Execution**: Direct function calls, no subprocess

### UtilIntegrationTests (Black-Box CLI Tests)

**Purpose**: Test end-to-end CLI behavior

**Structure**:
```
Tests/UtilIntegrationTests/
├── TestHarness.swift           # NEW: CLI execution utility
└── [existing test files]       # Updated to use TestHarness
```

**Dependencies**: Subprocess only (zero coupling to UtilLib/util)
**Access**: Black-box via TestHarness.run()
**Execution**: Subprocess executing `.build/debug/util`

**Test Pattern**:
```swift
@Test("util canonical check validates URLs")
func testCanonicalCheck() async throws {
    let harness = TestHarness()
    let result = try await harness.run(arguments: ["canonical", "check"])
    
    #expect(result.exitCode == 0)
    #expect(result.stdout.contains("✅"))
}
```

---

## Validation Checklist

After applying data model changes:

- [ ] Package.swift defines UtilLib, UtilLibTests, UtilIntegrationTests targets
- [ ] UtilLib dependencies: Subprocess + SwiftSoup (NO ArgumentParser)
- [ ] UtilIntegrationTests dependencies: Subprocess only (NO UtilLib, util, TestUtils)
- [ ] Sources/UtilLib/ directory exists with all business logic
- [ ] Tests/UtilLibTests/ directory exists with unit tests
- [ ] Tests/UtilIntegrationTests/ directory exists with TestHarness + integration tests
- [ ] All 4 consumers import UtilLib (21-dev, DesignSystem, IntegrationTests, DesignSystemTests)
- [ ] util executable depends on UtilLib + ArgumentParser
- [ ] All tests pass: `swift test`
- [ ] All targets compile: `swift build`

---

## Data Model Complete

All structural changes defined for:
- ✅ Package.swift target definitions
- ✅ TestHarness API structure
- ✅ Import graph changes
- ✅ Directory structure changes
- ✅ Test architecture model

**Ready for**: Contract definitions (contracts/TestHarness.md)
