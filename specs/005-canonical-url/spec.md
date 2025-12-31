# Feature Specification: Canonical URL Management

**Feature Branch**: `005-canonical-url`  
**Created**: 2025-12-29  
**Status**: Draft  
**Input**: User description: "Provide type-safe CLI tooling to check and fix canonical URL `<link rel="canonical">` tags across all generated HTML output, ensuring proper SEO and preventing duplicate content issues across subdomains"

## Clarifications

### Session 2025-12-30

- Q: Should the check command support structured output (e.g., JSON) for CI, or is human-readable output sufficient? → A: Human-readable only; CI relies on exit codes (matches existing `util` commands)
- Q: Should `util canonical fix` support a `--dry-run` mode to preview changes without modifying files? → A: Yes, add `--dry-run` flag (matches existing CLI pattern)

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Audit Canonical URLs Before Deployment (Priority: P1)

A developer wants to verify that all HTML pages in a generated site have correct canonical URLs before deploying to production. They run a check command that scans all HTML files and reports which pages are missing canonical tags, which have correct ones, and which have mismatches.

**Why this priority**: Preventing SEO issues is critical—missing or incorrect canonicals cause duplicate content penalties. This is the primary use case and must work before any fixing capability.

**Independent Test**: Can be fully tested by running `util canonical check` against a test directory with mixed canonical states and verifying the output report is accurate.

**Acceptance Scenarios**:

1. **Given** a directory with HTML files (some with canonicals, some without), **When** running `util canonical check --path ./output --base-url https://21.dev`, **Then** the output displays categorized results: ✅ Valid, ⚠️ Mismatch, ❌ Missing with file paths and URLs.
2. **Given** a directory where all HTML files have correct canonicals, **When** running `util canonical check`, **Then** the command exits with code 0 and reports all files valid.
3. **Given** a directory with missing canonicals, **When** running `util canonical check`, **Then** the command exits with non-zero code suitable for CI failure.

---

### User Story 2 - Add Missing Canonical URLs (Priority: P2)

A developer discovers missing canonical tags after running the check command. They want to automatically add canonical tags to all HTML files that are missing them, without modifying files that already have (potentially intentional) canonical overrides.

**Why this priority**: After detecting issues, the natural next step is remediation. Adding missing canonicals is the safest fix operation since it doesn't overwrite existing values.

**Independent Test**: Can be tested by running `util canonical fix` on a directory with missing canonicals and verifying tags are correctly inserted into HTML `<head>` sections.

**Acceptance Scenarios**:

1. **Given** HTML files missing `<link rel="canonical">` tags, **When** running `util canonical fix --path ./output --base-url https://21.dev`, **Then** canonical tags are inserted into the `<head>` section of each file with URLs derived from file paths.
2. **Given** an HTML file with an existing canonical tag (different from expected), **When** running `util canonical fix` (without `--force`), **Then** the file is NOT modified and a warning is logged.
3. **Given** `index.html` at path `./output/docs/index.html`, **When** canonical is derived, **Then** the URL is `https://21.dev/docs/` (trailing slash, no `index.html`).

---

### User Story 3 - Force Update All Canonicals (Priority: P3)

A developer needs to ensure all canonicals are consistent after a domain migration or URL structure change. They want to overwrite ALL existing canonicals to match the derived URLs, replacing any existing values.

**Why this priority**: This is a destructive operation that should be used rarely (domain migrations, major restructuring). Lower priority because it's a power-user feature.

**Independent Test**: Can be tested by running `util canonical fix --force` on files with intentionally wrong canonicals and verifying all are overwritten.

**Acceptance Scenarios**:

1. **Given** HTML files with existing canonical tags pointing to old domain, **When** running `util canonical fix --path ./output --base-url https://new-domain.dev --force`, **Then** all canonical tags are updated to new domain URLs.
2. **Given** a mix of correct and incorrect canonicals, **When** running `util canonical fix --force`, **Then** ALL files are updated regardless of existing state.

---

### User Story 4 - CI Pipeline Integration (Priority: P2)

A CI pipeline needs to automatically validate canonical URLs as part of the build process. The check command should integrate with standard CI exit code conventions and provide machine-readable output.

**Why this priority**: Automation is essential for maintaining SEO hygiene at scale. Same priority as fixing since both are core workflow needs.

**Independent Test**: Can be tested by running check command in a CI-like environment and verifying exit codes match expected values for pass/fail scenarios.

**Acceptance Scenarios**:

1. **Given** a GitHub Actions workflow step running `util canonical check`, **When** missing canonicals are detected, **Then** the step fails with non-zero exit code.
2. **Given** all canonicals are valid, **When** check runs in CI, **Then** exit code is 0 and workflow continues.

---

### Edge Cases

| Edge Case | Resolution |
|-----------|------------|
| Malformed `<head>` or no `<head>` | Skip file with warning (FR-019) |
| Multiple `<link rel="canonical">` tags | Report as error, do not modify (FR-020) |
| Non-HTML files (`.htm`, `.xhtml`) | Ignored; only `.html` files scanned (FR-001) |
| Query parameters/fragments in existing URLs | Preserved during comparison; derived URLs never include them |
| `--base-url` without trailing slash | Normalized internally; both `/` and no-slash accepted |
| Symbolic links | Followed by default (standard FileManager behavior) |
| Large files (>10MB) or binary `.html` | SwiftSoup handles gracefully; skip with warning if parse fails (FR-018) |

## Requirements *(mandatory)*

### Functional Requirements

**Core Check Functionality**:
- **FR-001**: System MUST recursively scan all `.html` files in the specified directory path
- **FR-002**: System MUST detect presence/absence of `<link rel="canonical" href="...">` tags in HTML `<head>`
- **FR-003**: System MUST derive expected canonical URL from `base-url + relative file path`
- **FR-004**: System MUST normalize paths: `index.html` → `/`, trailing slashes consistent
- **FR-005**: System MUST categorize each file as: Valid (matches), Mismatch (differs), or Missing (no tag)
- **FR-006**: System MUST output human-readable report showing all categories with file paths and URLs
- **FR-007**: System MUST exit with code 0 when all canonicals are valid, non-zero otherwise

**Core Fix Functionality**:
- **FR-008**: System MUST insert `<link rel="canonical" href="...">` into `<head>` for files missing the tag
- **FR-009**: System MUST NOT modify files with existing canonical tags unless `--force` flag is provided
- **FR-010**: System MUST overwrite all existing canonical tags when `--force` flag is provided
- **FR-011**: System MUST preserve HTML file formatting and encoding when modifying files
- **FR-012**: System MUST report number of files modified, skipped, and errors

**CLI Interface**:
- **FR-013**: System MUST provide `util canonical check --path <dir> --base-url <url>` command
- **FR-014**: System MUST provide `util canonical fix --path <dir> --base-url <url>` command
- **FR-015**: System MUST support `--force` flag for fix command to enable overwrite mode
- **FR-016**: System MUST validate that `--path` exists and is a directory
- **FR-017**: System MUST validate that `--base-url` is a valid URL with scheme (http/https)
- **FR-022**: System MUST support `--verbose` / `-v` flag for detailed output (matches existing CLI patterns)
- **FR-023**: System MUST output human-readable results with emoji indicators (✅ ⚠️ ❌); no JSON output required
- **FR-024**: System MUST support `--dry-run` flag for fix command to preview changes without writing files

**Error Handling**:
- **FR-018**: System MUST skip and warn on files it cannot read or parse
- **FR-019**: System MUST handle HTML files without `<head>` section gracefully (skip with warning)
- **FR-020**: System MUST handle files with multiple canonical tags (report as error, do not modify)

**Performance**:
- **FR-021**: System MUST process directories with 1000+ HTML files in under 5 seconds on macOS-15 CI runner hardware

### Key Entities

- **CanonicalResult**: Represents the check result for a single HTML file (filePath, status, existingUrl, expectedUrl)
- **CanonicalStatus**: Enumeration of possible states (valid, mismatch, missing, error)
- **CheckReport**: Aggregate of all CanonicalResults with summary counts per status

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Check command accurately categorizes 100% of HTML files in test corpus (zero false positives/negatives)
- **SC-002**: Fix command successfully adds canonical tags to 100% of files missing them
- **SC-003**: Processing 1000 HTML files completes in under 5 seconds on standard CI hardware
- **SC-004**: CI integration detects and fails builds with missing canonicals (100% detection rate)
- **SC-005**: Fixed HTML files pass W3C HTML validation (no malformed output)
- **SC-006**: Command works identically across all three subdomains (21.dev, docs.21.dev, md.21.dev)
- **SC-007**: Zero SEO regressions after deployment (verified via Google Search Console)
- **SC-008**: Developer can audit and fix canonicals for entire site in under 30 seconds

## Assumptions

- HTML files use UTF-8 encoding (or encoding declared in file)
- The `<head>` section exists and is well-formed in target HTML files
- Base URL provided always includes scheme (http:// or https://)
- Relative paths from directory root map directly to URL paths
- DocC-generated HTML structure is compatible with standard `<head>` tag insertion
