# Feature Specification: Util CLI Architecture Alignment

**Feature Branch**: `006-util-lib-executable`  
**Created**: 2026-01-03  
**Status**: Draft  
**Input**: Align the util CLI architecture with industry-standard library + executable pattern, improving testability by separating unit tests (library internals) from integration tests (black-box CLI execution)

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Library + Executable Separation (Priority: P1)

As a developer working on the util CLI, I need the business logic separated from the executable wrapper so that I can write focused unit tests against library internals without executing the full CLI binary.

**Why this priority**: Foundation for all other improvements. Industry-standard pattern that enables proper testing architecture and future programmatic use of utilities.

**Independent Test**: Can be fully tested by verifying Package.swift structure shows UtilLib library target separate from util executable target, and that util executable has only a thin wrapper calling UtilLib.

**Acceptance Scenarios**:

1. **Given** the current Utilities executable target, **When** I refactor to library + executable pattern, **Then** Package.swift contains UtilLib library target with all business logic and util executable target with minimal wrapper code
2. **Given** the new UtilLib library, **When** I examine the util executable, **Then** it contains only an entry point that calls UtilLib.main() (similar to subtree pattern)
3. **Given** the refactored structure, **When** I run swift build, **Then** both library and executable compile successfully with no errors

---

### User Story 2 - Unit Test Migration (Priority: P1)

As a developer writing unit tests, I need tests organized in UtilLibTests with @testable import access so that I can test library internals directly without CLI overhead.

**Why this priority**: Core testing capability. Must happen alongside architectural changes to maintain test coverage during migration.

**Independent Test**: Can be fully tested by verifying UtilLibTests target exists with @testable import UtilLib and all original unit tests pass in new location.

**Acceptance Scenarios**:

1. **Given** existing UtilitiesTests, **When** I migrate to UtilLibTests, **Then** all test files are moved to Tests/UtilLibTests/ directory
2. **Given** migrated unit tests, **When** I run swift test, **Then** all original unit tests pass in UtilLibTests target
3. **Given** UtilLibTests target, **When** I examine test imports, **Then** tests use @testable import UtilLib for internal access
4. **Given** the migration, **When** I check test coverage, **Then** baseline coverage percentage is maintained or improved

---

### User Story 3 - Integration Test Architecture (Priority: P2)

As a developer writing integration tests, I need black-box CLI tests in UtilIntegrationTests that execute the actual binary via subprocess so that I can verify end-to-end CLI behavior without coupling to internal implementation.

**Why this priority**: Completes testing architecture. Enables true black-box testing but depends on P1 (library separation) being complete first.

**Independent Test**: Can be fully tested by verifying UtilIntegrationTests has zero dependency on UtilLib and successfully executes CLI commands via TestHarness.

**Acceptance Scenarios**:

1. **Given** existing UtilitiesCLITests, **When** I migrate to UtilIntegrationTests, **Then** all test files are moved to Tests/UtilIntegrationTests/ directory
2. **Given** UtilIntegrationTests target, **When** I examine Package.swift dependencies, **Then** UtilIntegrationTests has no dependency on UtilLib
3. **Given** UtilIntegrationTests, **When** I examine test code, **Then** no test files contain import UtilLib statements
4. **Given** migrated integration tests, **When** I run swift test, **Then** all original integration tests pass in UtilIntegrationTests target

---

### User Story 4 - TestHarness Implementation (Priority: P2)

As a developer writing integration tests, I need a TestHarness utility that executes CLI commands and captures stdout/stderr/exit codes so that I can write black-box assertions without manual subprocess management.

**Why this priority**: Enables clean integration test implementation. Must happen with P2 (integration test architecture) to provide testing utilities.

**Independent Test**: Can be fully tested by creating a sample integration test that uses TestHarness to run a CLI command and assert on output.

**Acceptance Scenarios**:

1. **Given** the need for CLI execution, **When** I implement TestHarness, **Then** it provides a run() method accepting command arguments and returning CommandResult
2. **Given** TestHarness.run(), **When** I execute a CLI command, **Then** CommandResult contains stdout, stderr, and exitCode properties
3. **Given** TestHarness implementation, **When** I examine dependencies, **Then** it uses swift-subprocess package for process execution
4. **Given** TestHarness, **When** I use it in integration tests, **Then** tests can assert on stdout/stderr/exitCode without subprocess boilerplate
5. **Given** TestHarness location, **When** I examine file structure, **Then** TestHarness.swift exists inline in Tests/UtilIntegrationTests/ directory

---

### User Story 5 - Documentation & CI Validation (Priority: P3)

As a developer onboarding to the project or maintaining the architecture, I need updated documentation explaining the library + executable pattern and all CI workflows passing so that I understand when to use unit vs integration tests and have confidence in production readiness.

**Why this priority**: Knowledge transfer and production validation. Lower priority since it doesn't affect functionality but critical for maintainability.

**Independent Test**: Can be fully tested by verifying architecture documentation exists explaining the pattern and all CI workflows show passing status.

**Acceptance Scenarios**:

1. **Given** the architectural changes, **When** I create documentation, **Then** it explains library + executable pattern and when to use unit vs integration tests
2. **Given** the migration complete, **When** I run all CI workflows, **Then** every workflow passes without modification or with documented updates
3. **Given** updated documentation, **When** new developers read it, **Then** they understand where to place new tests (UtilLibTests for logic, UtilIntegrationTests for CLI behavior)

---

### Edge Cases

- What happens when tests depend on both library internals AND CLI output? (Solution: Split into separate unit test for logic validation and integration test for CLI behavior validation)
- How does the system handle subprocess failures in integration tests? (Solution: TestHarness captures and surfaces errors via CommandResult.exitCode and stderr)
- What happens if migration introduces test failures? (Solution: Fix failures before completing migration - all tests must pass as success criterion)
- How does the architecture handle future CLI tools in the repository? (Solution: Pattern is reusable - each CLI gets its own Lib + executable + test structure)

## Requirements *(mandatory)*

### Functional Requirements

#### Architecture & Structure

- **FR-001**: Package.swift MUST rename Utilities target to UtilLib library target (directory renamed from Sources/Utilities/ to Sources/UtilLib/)
- **FR-002**: UtilLib library target MUST maintain current dependencies: Subprocess, SwiftSoup (NO ArgumentParser to keep library lightweight)
- **FR-003**: util executable target MUST keep ArgumentParser dependency (Commands and CLI logic remain in util)
- **FR-004**: util executable target MUST depend on UtilLib library target
- **FR-005**: All consumer targets MUST be updated atomically in same commit: 21-dev, DesignSystem, IntegrationTests, DesignSystemTests (import UtilLib instead of Utilities)

#### Unit Testing

- **FR-006**: Package.swift MUST rename UtilitiesTests to UtilLibTests test target
- **FR-007**: UtilLibTests target MUST depend on UtilLib library target
- **FR-008**: UtilLibTests test files MUST use @testable import UtilLib for accessing internal APIs
- **FR-009**: All test files currently in Tests/UtilitiesTests/ MUST be migrated to Tests/UtilLibTests/ directory
- **FR-010**: All migrated unit tests MUST pass in UtilLibTests target

#### Integration Testing

- **FR-011**: Package.swift MUST rename UtilitiesCLITests to UtilIntegrationTests test target
- **FR-012**: UtilIntegrationTests target MUST NOT have any dependency on UtilLib library target
- **FR-013**: UtilIntegrationTests target MUST NOT have any dependency on util executable target (tests execute binary via path)
- **FR-014**: UtilIntegrationTests target MUST depend only on swift-subprocess package for CLI execution
- **FR-015**: UtilIntegrationTests target MAY include dependencies for output validation (e.g., SwiftSoup for HTML parsing) but MUST NOT import UtilLib or util
- **FR-016**: All test files currently in Tests/UtilitiesCLITests/ MUST be migrated to Tests/UtilIntegrationTests/ directory
- **FR-017**: All migrated integration tests MUST pass in UtilIntegrationTests target
- **FR-018**: Integration test files MUST NOT contain any import UtilLib or import util statements

#### TestHarness Utility

- **FR-019**: UtilIntegrationTests MUST include a TestHarness utility for CLI execution
- **FR-020**: TestHarness MUST be located at Tests/UtilIntegrationTests/TestHarness.swift (inline, not a separate module)
- **FR-021**: TestHarness MUST provide a run() method accepting command arguments as [String]
- **FR-022**: TestHarness MUST return a CommandResult struct containing stdout: String, stderr: String, and exitCode: Int properties
- **FR-023**: TestHarness MUST use swift-subprocess package for process execution
- **FR-024**: TestHarness MUST support async/await execution pattern
- **FR-025**: TestHarness MUST use Foundation types (URL, String) for paths since CLI is macOS-only (no SystemPackage required)
- **FR-026**: TestHarness MUST execute util binary from .build/debug/util path (no import of util executable)

#### Quality & Validation

- **FR-027**: All existing tests (unit + integration) MUST pass after migration
- **FR-028**: Test coverage percentage MUST be maintained or improved after migration
- **FR-029**: Architecture documentation MUST be created explaining library + executable pattern adapted for websites
- **FR-030**: Architecture documentation MUST explain when to use UtilLibTests vs UtilIntegrationTests
- **FR-031**: Architecture documentation MUST explain why ArgumentParser stays in util (lightweight UtilLib for programmatic consumers)
- **FR-032**: All CI/CD workflows MUST pass after migration without modification or with documented updates

### Key Entities *(include if feature involves data)*

- **UtilLib**: Library target (renamed from Utilities) containing business logic utilities (sitemap, headers, canonical, state) - testable via @testable import - NO ArgumentParser dependency to stay lightweight for programmatic consumers
- **util**: Executable target containing ArgumentParser commands + entry point - depends on UtilLib + ArgumentParser
- **UtilLibTests**: Test target (renamed from UtilitiesTests) for unit testing library internals - uses @testable import UtilLib
- **UtilIntegrationTests**: Test target (renamed from UtilitiesCLITests) for black-box CLI testing - zero dependency on UtilLib or util executable, executes binary via path
- **TestHarness**: Helper utility for CLI execution and output capture - lives inline in UtilIntegrationTests, uses swift-subprocess
- **CommandResult**: Data structure capturing CLI execution results (stdout, stderr, exitCode)

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: UtilLibTests tests library internals via @testable import UtilLib (verifiable by examining test imports)
- **SC-002**: UtilIntegrationTests has zero dependency on UtilLib in Package.swift (verifiable by inspecting dependencies array)
- **SC-003**: TestHarness provides CLI execution with stdout/stderr/exit code capture (verifiable by running sample integration test)
- **SC-004**: All existing tests continue to pass after migration - 100% pass rate maintained (verifiable by swift test)
- **SC-005**: Clear separation exists: unit tests for logic, integration tests for CLI behavior (verifiable by examining test organization and documentation)
- **SC-006**: Architecture documentation explains pattern and test placement guidelines (verifiable by documentation review)
- **SC-007**: All CI/CD workflows pass after migration (verifiable by CI workflow status)
- **SC-008**: util executable contains minimal wrapper code (<10 lines calling UtilLib.main()) (verifiable by examining Sources/util/main.swift)

## Assumptions & Constraints

### Assumptions

1. **Existing test coverage is adequate**: Assume current UtilitiesTests and UtilitiesCLITests provide sufficient coverage to validate migration success
2. **Foundation sufficient for paths**: Since CLI is macOS-only, Foundation's URL and String types are adequate for path handling (no SystemPackage needed)
3. **swift-subprocess already available**: Assume swift-subprocess package is already in Package.swift dependencies (verified in clarification phase)
4. **Tests are independently runnable**: Assume existing tests don't have hidden dependencies on file locations that would break during migration
5. **CI uses swift test**: Assume CI workflows run tests via swift test command (standard SPM pattern)

### Constraints

1. **macOS-only target**: CLI only needs to work on macOS 15+, simplifying path handling and dependency choices
2. **Zero breaking changes to CLI behavior**: Architecture changes must be transparent to end users - CLI functionality unchanged
3. **Follow subtree pattern**: Must match proven architecture from subtree project for consistency and maintainability
4. **Inline TestHarness**: TestHarness must live in UtilIntegrationTests directory, not as separate shared module
5. **Full migration required**: Partial migration not acceptable - all tests must move to new structure

### Dependencies

- **swift-subprocess 0.2.1**: For CLI execution in integration tests (already in Package.swift)
- **Swift Testing**: Built into Swift 6.1 toolchain (no package dependency)
- **Existing Utilities target**: Source of all business logic to be extracted into UtilLib

## Out of Scope

The following are explicitly NOT part of this feature:

1. **Shared TestHarness module**: TestHarness will not be extracted to a shared library - each CLI maintains its own inline version
2. **SystemPackage dependency**: Will not use SystemPackage since macOS-only CLI can use Foundation for paths
3. **New CLI features**: Focus is architecture alignment only - no new commands or functionality
4. **Performance optimization**: If test suite execution time doesn't regress, optimization is not required
5. **Test expansion**: Only migrating existing tests - new test coverage is out of scope
6. **Multi-platform support**: Linux/Windows support remains out of scope (macOS-only)

## Clarifications

### Session 2026-01-03

- Q: Where should ArgumentParser dependency live after refactor? → A: Keep ArgumentParser in util executable only (Option A). Rationale: Utilities is consumed programmatically by other targets (21-dev, DesignSystem, IntegrationTests) that don't need CLI overhead. Keeping Utilities lightweight prevents transitive ArgumentParser bloat for non-CLI consumers.
- Q: Given library+executable separation already exists, what needs refactoring? → A: Full refactor including renaming Utilities→UtilLib (Option A). Rationale: Establishes consistent naming convention (util CLI → UtilLib library) matching subtree pattern, even though current structure is architecturally sound.
- Q: How to handle updating consumer targets when renaming Utilities→UtilLib? → A: Atomic update in same PR (Option A). Update all 4 consumers (21-dev, DesignSystem, IntegrationTests, DesignSystemTests) simultaneously in one commit. Mono-repo advantage - no broken intermediate states.
- Q: Should UtilIntegrationTests remove util executable dependency? → A: Yes, remove both UtilLib and util executable dependencies (Option A). Pure black-box testing via TestHarness executing `.build/debug/util` binary path. Only depends on Subprocess for process execution (plus output parsers like SwiftSoup if needed for validation).
- Q: Should directory structure match target name? → A: Yes, rename Sources/Utilities/ to Sources/UtilLib/ (Option A). Matches Swift Package Manager convention where directory name matches target name. Prevents confusion and aligns with subtree pattern (Sources/SubtreeLib/).

## Notes

- This feature follows the library + executable pattern but adapted for websites architecture where Utilities has non-CLI consumers
- Unlike subtree (where SubtreeLib is only used for testing), Utilities is a programmatic library used across multiple targets
- ArgumentParser and Commands remain in util executable to keep Utilities lightweight
- TestUtils target remains unchanged - it's specifically for DesignSystem HTML rendering tests and unrelated to util CLI testing
- UtilIntegrationTests uses its own inline TestHarness (not TestUtils)
- Migration is atomic - either all components migrate successfully or none do (rollback on failure)
