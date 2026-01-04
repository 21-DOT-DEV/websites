# Contract: TestHarness

**Feature**: 006-util-lib-executable  
**Component**: Tests/UtilIntegrationTests/TestHarness.swift  
**Purpose**: CLI execution utility for black-box integration testing

---

## API Contract

### CommandResult

**Type**: Struct

**Purpose**: Captures result of CLI command execution

**Properties**:

| Property | Type | Description | Constraints |
|----------|------|-------------|-------------|
| `stdout` | `String` | Standard output from command | Max 65536 bytes captured |
| `stderr` | `String` | Standard error output from command | Max 65536 bytes captured |
| `exitCode` | `Int` | Exit code from command execution | 0 = success, non-zero = error |
| `succeeded` | `Bool` | Computed property | Returns `exitCode == 0` |

**Initialization**: Not directly initialized (returned by TestHarness.run())

---

### TestHarness

**Type**: Struct

**Purpose**: Execute util CLI binary and capture results

**Properties**:

| Property | Type | Description | Default |
|----------|------|-------------|---------|
| `executablePath` | `String` | Path to util binary | `.build/debug/util` (relative to repo root) |

**Initializers**:

#### `init()`

Default initializer using debug build path.

```swift
init()
```

**Behavior**:
- Uses `FileManager.default.currentDirectoryPath` to get repo root
- Constructs path: `{currentDirectory}/.build/debug/util`
- Assumes working directory is repository root when tests run

**Postconditions**:
- `executablePath` set to `.build/debug/util` relative to current directory

---

#### `init(executablePath:)`

Custom initializer for special test scenarios.

```swift
init(executablePath: String)
```

**Parameters**:
- `executablePath`: Absolute or relative path to util binary

**Use Cases**:
- Testing release builds (`.build/release/util`)
- Testing custom binary locations
- CI environments with non-standard paths

**Postconditions**:
- `executablePath` set to provided value

---

### run(arguments:workingDirectory:)

**Signature**:

```swift
func run(
    arguments: [String],
    workingDirectory: String? = nil
) async throws -> CommandResult
```

**Purpose**: Execute util CLI with given arguments and capture output

**Parameters**:

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `arguments` | `[String]` | Yes | Command-line arguments (e.g., `["canonical", "check"]`) |
| `workingDirectory` | `String?` | No | Working directory for command execution (default: nil = use current) |

**Returns**: `CommandResult` with stdout, stderr, and exitCode

**Throws**: 
- If subprocess fails to execute (binary not found, permission denied, etc.)
- Does NOT throw for non-zero exit codes (captured in CommandResult.exitCode)

**Behavior**:

1. **Subprocess Execution**:
   - Executes util binary at `executablePath`
   - Passes `arguments` array to CLI
   - Sets working directory if provided
   - Captures stdout with 65536 byte limit
   - Captures stderr with 65536 byte limit

2. **Exit Code Extraction**:
   - Reads termination status from subprocess result
   - If `.exited(code)`: uses code value
   - Otherwise: returns -1 (non-standard termination)

3. **Result Construction**:
   - Creates CommandResult with captured stdout, stderr, exitCode
   - Empty strings if no output captured

**Preconditions**:
- util binary must exist at `executablePath`
- util binary must have execute permissions
- Arguments must be valid for util CLI

**Postconditions**:
- CommandResult contains complete stdout/stderr (up to limits)
- CommandResult.exitCode reflects actual exit status
- Subprocess terminates (no hanging processes)

---

## Usage Examples

### Basic Command Execution

```swift
let harness = TestHarness()
let result = try await harness.run(arguments: ["--version"])

#expect(result.exitCode == 0)
#expect(result.stdout.contains("0.1.0"))
```

### Validating Error Cases

```swift
let harness = TestHarness()
let result = try await harness.run(arguments: ["invalid-command"])

#expect(result.exitCode != 0)
#expect(result.stderr.contains("Error") || result.stderr.contains("Unknown"))
```

### Command with Subcommands

```swift
let harness = TestHarness()
let result = try await harness.run(arguments: ["canonical", "check"])

#expect(result.succeeded)  // Uses computed property
#expect(result.stdout.contains("✅"))
```

### Custom Working Directory

```swift
let harness = TestHarness()
let tempDir = "/tmp/test-repo"
let result = try await harness.run(
    arguments: ["sitemap", "generate"],
    workingDirectory: tempDir
)

#expect(result.exitCode == 0)
```

### Custom Binary Path

```swift
let harness = TestHarness(executablePath: ".build/release/util")
let result = try await harness.run(arguments: ["--help"])

#expect(result.succeeded)
```

---

## Error Handling Contract

### Errors That Throw

**Scenario**: Binary not found
- **Condition**: `executablePath` doesn't exist
- **Behavior**: `run()` throws error
- **Test Strategy**: Validate error message contains path

**Scenario**: Permission denied
- **Condition**: Binary exists but not executable
- **Behavior**: `run()` throws error
- **Test Strategy**: Validate error indicates permission issue

**Scenario**: Subprocess execution failure
- **Condition**: System cannot spawn process
- **Behavior**: `run()` throws error
- **Test Strategy**: Handle gracefully in tests

### Errors That Don't Throw

**Scenario**: Non-zero exit code
- **Condition**: Command fails (e.g., invalid arguments)
- **Behavior**: Returns CommandResult with exitCode != 0
- **Test Strategy**: Assert on `result.exitCode` and `result.stderr`

**Scenario**: Empty output
- **Condition**: Command produces no stdout/stderr
- **Behavior**: Returns CommandResult with empty strings
- **Test Strategy**: Assert `result.stdout == ""` and `result.stderr == ""`

**Scenario**: Output exceeds limit
- **Condition**: Command produces >65536 bytes
- **Behavior**: Truncates at limit, returns what was captured
- **Test Strategy**: Not typically tested (util CLI outputs are small)

---

## Implementation Requirements

### Dependencies

```swift
import Foundation       // For FileManager, String
import Subprocess       // For Subprocess.run()
import Testing          // For @Test, #expect
```

**No SystemPackage**: Use Foundation types only (macOS-only CLI)

### Subprocess Configuration

```swift
let result = try await Subprocess.run(
    .at(executablePath),  // or .path() depending on Subprocess API
    arguments: .init(arguments),
    workingDirectory: workingDirectory,
    output: .string(limit: 65536),
    error: .string(limit: 65536)
)
```

### Exit Code Extraction

```swift
let exitCode: Int
if case .exited(let code) = result.terminationStatus {
    exitCode = Int(code)
} else {
    exitCode = -1  // Non-standard termination
}
```

---

## Testing Contract

### TestHarness Validation Tests

**Required Tests** (before using TestHarness in integration tests):

1. **Test basic execution**
   - Execute `util --version`
   - Verify exitCode == 0
   - Verify stdout contains version

2. **Test stdout capture**
   - Execute command with known output
   - Verify stdout matches expected

3. **Test stderr capture**
   - Execute command that prints to stderr
   - Verify stderr matches expected

4. **Test exit code handling**
   - Execute command with non-zero exit
   - Verify exitCode captured correctly

5. **Test argument passing**
   - Execute command with multiple arguments
   - Verify all arguments passed through

### Integration Test Pattern

All UtilIntegrationTests tests MUST:
- Use TestHarness for CLI execution (no direct imports)
- Assert on CommandResult properties
- Use async/await pattern
- Follow swift-testing conventions (@Test, #expect)

Example:
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

## Contract Validation Checklist

Implementation satisfies contract when:

- [ ] CommandResult struct with stdout, stderr, exitCode, succeeded properties
- [ ] TestHarness struct with executablePath property
- [ ] init() constructor using current directory + `.build/debug/util`
- [ ] init(executablePath:) constructor accepting custom path
- [ ] run(arguments:workingDirectory:) async method returning CommandResult
- [ ] Subprocess execution with 65536 byte output limits
- [ ] Exit code extraction from termination status
- [ ] Throws on subprocess execution failures
- [ ] Returns CommandResult (not throws) for non-zero exit codes
- [ ] TestHarness validation tests pass
- [ ] Integration tests successfully use TestHarness
- [ ] Zero coupling to UtilLib or util in integration tests

---

## Contract Complete

TestHarness contract defined for:
- ✅ CommandResult data structure
- ✅ TestHarness initialization
- ✅ run() method signature and behavior
- ✅ Error handling semantics
- ✅ Usage patterns
- ✅ Testing requirements

**Ready for**: Implementation (following TDD - tests first)
