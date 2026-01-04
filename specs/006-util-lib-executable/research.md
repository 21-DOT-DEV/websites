# Research: Util CLI Architecture Alignment

**Feature**: 006-util-lib-executable  
**Date**: 2026-01-04  
**Purpose**: Resolve unknowns and establish patterns before implementation

---

## 1. TestHarness Implementation Pattern

### Source Analysis: subtree/Tests/IntegrationTests/TestHarness.swift

**Reusable Patterns Identified**:

1. **CommandResult Structure**
   ```swift
   struct CommandResult {
       let stdout: String
       let stderr: String
       let exitCode: Int
       
       var succeeded: Bool { exitCode == 0 }
   }
   ```

2. **TestHarness Core API**
   ```swift
   struct TestHarness {
       let executablePath: FilePath
       
       init() {
           let currentDirectory = FilePath(FileManager.default.currentDirectoryPath)
           self.executablePath = currentDirectory.appending(".build/debug/subtree")
       }
       
       func run(arguments: [String], workingDirectory: FilePath? = nil) async throws -> CommandResult
   }
   ```

3. **Subprocess Execution Pattern**
   - Uses `Subprocess.run(.path(executablePath), arguments:, workingDirectory:, output:, error:)`
   - Captures stdout/stderr with 65536 byte limit
   - Handles termination status: `.exited(code)` → exitCode

4. **Error Handling**
   - subprocess failures surface as thrown errors
   - Non-zero exit codes captured in CommandResult.exitCode
   - Custom TestError enum for git operations (not needed for util)

### macOS-Specific Adaptations for util

**Differences from subtree**:

| Aspect | subtree | util (this feature) |
|--------|---------|---------------------|
| Path handling | SystemPackage (FilePath) | Foundation (URL/String) |
| Platform | macOS 13+ (cross-platform) | macOS 15+ (macOS-only) |
| Binary name | `.build/debug/subtree` | `.build/debug/util` |
| Git helpers | Included (verifyCommitExists, runGit) | Not needed |

**Adaptation Strategy**:
- Replace `FilePath` with `String` for paths
- Use `FileManager.default.currentDirectoryPath` → String concatenation
- Remove SystemPackage import entirely
- Keep async/await pattern unchanged
- Keep CommandResult structure unchanged
- Remove git-specific helper methods

---

## 2. Commit Strategy

### Logical Commit Boundaries

**Milestone-Based Commits** (4-6 total, per clarification Q5):

1. **Documentation** (~30 min)
   - Add architecture guide to `.windsurf/rules/`
   - Explain library+executable pattern
   - Document ArgumentParser placement rationale
   - **Validation**: Documentation review, all existing tests pass

2. **TestHarness Foundation** (~1 hour)
   - Create `Tests/UtilIntegrationTests/TestHarness.swift` (adapted from subtree)
   - Implement CommandResult struct
   - Implement run(arguments:) method
   - Write TestHarness validation tests
   - **Validation**: `swift test --filter TestHarness`, existing tests unchanged

3. **Library Rename + Consumer Updates (ATOMIC)** (~2 hours)
   - Move `Sources/Utilities/` → `Sources/UtilLib/`
   - Update `Package.swift`: Utilities → UtilLib, UtilitiesTests → UtilLibTests
   - Update util dependency: Utilities → UtilLib
   - Update 4 consumers: 21-dev, DesignSystem, IntegrationTests, DesignSystemTests
   - Update test imports: `import Utilities` → `import UtilLib`
   - **Validation**: `swift build`, `swift test` (all existing tests pass)

4. **Integration Test Migration** (~1.5 hours)
   - Move `Tests/UtilitiesCLITests/` → `Tests/UtilIntegrationTests/`
   - Update `Package.swift`: UtilitiesCLITests → UtilIntegrationTests
   - Remove UtilLib, util, TestUtils dependencies
   - Add only Subprocess dependency
   - Migrate tests to use TestHarness
   - Remove all `import Utilities`, `import util` statements
   - **Validation**: `swift test --filter UtilIntegrationTests` (black-box tests pass)

5. **CI Validation** (~30 min)
   - Run all CI workflows
   - Update any CI references to old target names (if any)
   - Verify all 32 functional requirements satisfied
   - **Validation**: CI green, feature complete

### Test-Passing Checkpoints (per clarification Q2)

**Commit 1 (Documentation)**:
- Validation: All existing tests still pass
- No code changes, zero risk

**Commit 2 (TestHarness)**:
- Validation: TestHarness tests pass, existing tests unchanged
- TestHarness isolated, doesn't affect existing code

**Commit 3 (Library Rename - ATOMIC)**:
- Validation: ALL tests pass (unit + integration)
- Swift build succeeds for all targets
- All 4 consumers compile successfully
- Most critical commit - must be atomic to avoid broken state

**Commit 4 (Integration Test Migration)**:
- Validation: ALL tests pass (unit tests unchanged, integration tests via TestHarness)
- Zero coupling to UtilLib/util verified

**Commit 5 (CI)**:
- Validation: CI workflows pass
- Production-ready

### Rollback Procedures

**If Commit 3 Fails** (library rename):
- `git reset --hard HEAD~1`
- Review Package.swift changes
- Check for missed consumer imports
- Retry with more careful import updates

**If Commit 4 Fails** (integration test migration):
- `git reset --hard HEAD~1`
- Review TestHarness usage in migrated tests
- Check for remaining `import Utilities` or `import util` statements
- Verify Subprocess dependency added to Package.swift

**General Strategy**:
- Each commit should be independently revertable
- Tests passing at every checkpoint enables bisect debugging
- Atomic commits prevent broken intermediate states

---

## 3. Documentation Structure

### Location Decision

**Chosen**: `.windsurf/rules/util-architecture.md`

**Rationale**:
- `.windsurf/rules/` is agent-specific context (already exists with 13 files)
- Architecture decisions belong with agent guidance
- Cross-references existing rules (01-stack-and-commands.md mentions util CLI)
- Alternative (`docs/architecture/`) would require new directory structure

### Content Outline

**File**: `.windsurf/rules/util-architecture.md`

```markdown
# Util CLI Architecture

## Library + Executable Pattern

### Structure
- UtilLib: Business logic library (Canonical/, Headers/, Sitemap/, State/, Shared/)
- util: CLI executable (Commands/ + ArgumentParser integration)

### Why ArgumentParser Stays in util Executable

**Decision**: ArgumentParser remains in util executable, NOT moved to UtilLib

**Rationale**:
- UtilLib consumed programmatically by 4 targets: 21-dev, DesignSystem, IntegrationTests, DesignSystemTests
- These consumers need business logic (sitemap generation, header validation) without CLI overhead
- Adding ArgumentParser to UtilLib creates transitive dependency bloat for non-CLI consumers
- Differs from subtree pattern where SubtreeLib is only used for testing

### When to Use UtilLibTests vs UtilIntegrationTests

**UtilLibTests** (Unit Tests):
- Test business logic in isolation
- Use @testable import UtilLib for internal access
- Fast execution, no subprocess overhead
- Examples: Canonical URL validation, sitemap generation logic, header parsing

**UtilIntegrationTests** (Black-Box CLI Tests):
- Test end-to-end CLI behavior
- Zero dependency on UtilLib or util executable
- Execute binary via TestHarness (.build/debug/util path)
- Validate stdout/stderr/exit codes
- Examples: CLI argument validation, command help text, error messages

### TestHarness Pattern

**Location**: Tests/UtilIntegrationTests/TestHarness.swift (inline)

**Usage**:
```swift
let harness = TestHarness()
let result = try await harness.run(arguments: ["canonical", "check"])
#expect(result.exitCode == 0)
#expect(result.stdout.contains("✅"))
```

**Pattern**: Adapted from subtree project with Foundation paths (macOS-only)
```

### Cross-References

Update existing rules to reference new architecture:
- `.windsurf/rules/01-stack-and-commands.md`: Link to util-architecture.md for CLI details
- `.windsurf/rules/10-swift-architecture.md`: Reference util as example of library+executable pattern

---

## 4. Differences from Subtree Pattern

### Key Architectural Difference

**subtree**: SubtreeLib contains ArgumentParser because library is ONLY used for testing
- No programmatic consumers
- CLI-focused design
- ArgumentParser in library is acceptable

**util (websites)**: UtilLib is consumed programmatically by multiple targets
- 21-dev imports UtilLib for sitemap generation
- DesignSystem imports UtilLib for utilities
- IntegrationTests imports UtilLib for test helpers
- DesignSystemTests imports UtilLib for shared utilities
- ArgumentParser in library would bloat all consumers

### Implementation Differences

| Aspect | subtree | util |
|--------|---------|------|
| ArgumentParser location | SubtreeLib (library) | util (executable only) |
| Path handling | SystemPackage (FilePath) | Foundation (String/URL) |
| Platform support | macOS 13+ (cross-platform intent) | macOS 15+ (macOS-only) |
| Library consumers | Tests only | 4 production targets |
| TestHarness | SystemPackage imports | Foundation only |

### Pattern Reusability

**For future CLI tools in websites monorepo**:

1. **If library has non-CLI consumers** → Follow util pattern (ArgumentParser in executable)
2. **If library only used for testing** → Follow subtree pattern (ArgumentParser in library)

**Decision criteria**: "Who imports the library?"
- Only tests? → ArgumentParser can go in library
- Production code? → ArgumentParser stays in executable

---

## Research Complete

All unknowns resolved:
- ✅ TestHarness implementation pattern documented
- ✅ Commit strategy with 4-6 logical commits defined
- ✅ Documentation structure chosen (.windsurf/rules/)
- ✅ Differences from subtree pattern explained

**Ready for Phase 1**: Design & Contracts
