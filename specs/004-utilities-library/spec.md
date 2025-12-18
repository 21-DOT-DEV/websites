# Feature Specification: Utilities Library Extraction

**Feature Branch**: `004-utilities-library`  
**Created**: 2025-12-14  
**Status**: Complete  
**Input**: Extract sitemap utilities and reusable workflow logic from DesignSystem into a dedicated Utilities library target with util CLI executable

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Generate Sitemap via CLI (Priority: P1)

A developer runs a single CLI command to generate a valid sitemap.xml for any subdomain (21.dev, docs.21.dev, md.21.dev) with correct URLs and lastmod dates.

**Why this priority**: Core functionality that replaces scattered bash scripts across multiple workflows. Enables consistent, testable sitemap generation.

**Independent Test**: Can be fully tested by running `swift run util sitemap generate --site 21-dev` and verifying output sitemap.xml contains all expected URLs with valid lastmod dates.

**Acceptance Scenarios**:

1. **Given** a built 21.dev site, **When** running `util sitemap generate --site 21-dev`, **Then** a valid sitemap.xml is generated at Websites/21-dev/sitemap.xml with all page URLs
2. **Given** generated DocC documentation, **When** running `util sitemap generate --site docs-21-dev`, **Then** a valid sitemap.xml is generated with all documentation URLs
3. **Given** generated markdown documentation, **When** running `util sitemap generate --site md-21-dev`, **Then** a valid sitemap.xml is generated with all markdown URLs
4. **Given** any subdomain, **When** running `util sitemap generate`, **Then** lastmod dates reflect git commit dates (21.dev) or package version dates (docs/md)

---

### User Story 2 - Validate Headers via CLI (Priority: P2)

A developer validates Cloudflare `_headers` files for correctness and environment-awareness before deployment.

**Why this priority**: Consolidates HeadersValidator into unified CLI. Prevents deployment of invalid headers configuration.

**Independent Test**: Can be fully tested by running `swift run util headers validate --site 21-dev --env prod` and receiving pass/fail with detailed error messages.

**Acceptance Scenarios**:

1. **Given** a valid _headers file, **When** running `util headers validate --site 21-dev --env prod`, **Then** command exits 0 with success message
2. **Given** an invalid _headers file, **When** running `util headers validate --site 21-dev --env prod`, **Then** command exits non-zero with specific validation errors
3. **Given** environment flag, **When** running validation, **Then** environment-specific rules are applied (prod vs dev)

---

### User Story 3 - Manage State Files via CLI (Priority: P3)

A developer manages package version state files used for lastmod tracking in docs/md sitemaps.

**Why this priority**: Centralizes state file logic currently duplicated in workflow bash scripts.

**Independent Test**: Can be fully tested by running `swift run util state update --package-version 1.2.3` and verifying state file is updated with new version and timestamp.

**Acceptance Scenarios**:

1. **Given** a state file exists, **When** running `util state update --package-version 1.2.3`, **Then** state file is updated with new version and ISO8601 timestamp
2. **Given** no state file exists, **When** running `util state update`, **Then** a new state file is created with current package version
3. **Given** a state file, **When** running `util state validate`, **Then** command reports whether state file is valid JSON with required fields

---

### User Story 4 - Validate Sitemap URLs (Priority: P4)

A developer validates that generated sitemap URLs are correct and accessible.

**Why this priority**: Catches URL errors before deployment. Lower priority as manual verification is currently possible.

**Independent Test**: Can be fully tested by running `swift run util sitemap validate --site 21-dev` and receiving pass/fail for URL validity.

**Acceptance Scenarios**:

1. **Given** a generated sitemap.xml, **When** running `util sitemap validate --site 21-dev`, **Then** all URLs are validated for correct format
2. **Given** a sitemap with malformed URLs, **When** running validation, **Then** specific invalid URLs are reported

---

### Edge Cases

- What happens when sitemap generation runs before site is built? → Clear error message indicating missing build output
- What happens when git history is unavailable for lastmod? → Falls back to current timestamp with warning
- What happens when state file is corrupted JSON? → Error message with instructions to regenerate
- What happens when unknown site name is provided? → Lists valid site names and exits with error

## Requirements *(mandatory)*

### Functional Requirements

#### Library Target
- **FR-001**: System MUST create `Utilities` library target at `Sources/Utilities/` as peer to DesignSystem
- **FR-002**: System MUST migrate all sitemap-related utilities from DesignSystem to Utilities library
- **FR-003**: System MUST expose public APIs for sitemap generation, URL discovery, lastmod tracking
- **FR-004**: System MUST maintain 100% backward compatibility with existing sitemap tests
- **FR-004a**: ~~System MUST initially re-export Utilities APIs from DesignSystem for backward compatibility~~ **SUPERSEDED** — Direct migration chosen (mono-repo)
- **FR-004b**: ~~System MUST mark re-exported APIs as deprecated with migration guidance~~ **SUPERSEDED**
- **FR-004c**: ~~System MUST remove re-exports in a future release after consumers migrate to `import Utilities`~~ **SUPERSEDED** — Removed immediately

#### CLI Executable
- **FR-005**: System MUST create `util` executable target depending on Utilities library
- **FR-006**: System MUST implement subcommand-based CLI structure using Swift ArgumentParser
- **FR-007**: System MUST provide `sitemap` subcommand with `generate` and `validate` actions
- **FR-008**: System MUST provide `headers` subcommand with `validate` action (new implementation)
- **FR-009**: System MUST provide `state` subcommand with `update` and `validate` actions
- **FR-010**: System MUST support `--site` flag accepting: 21-dev, docs-21-dev, md-21-dev
- **FR-011**: System MUST support `--env` flag for headers commands accepting: prod, dev

#### Sitemap Generation
- **FR-012**: System MUST generate valid XML sitemap following sitemap protocol 0.9
- **FR-013**: System MUST discover URLs from built site output directories
- **FR-014**: System MUST compute lastmod from git commit history for 21.dev pages
- **FR-015**: System MUST compute lastmod from package version state for docs/md pages
- **FR-016**: System MUST output sitemap to `Websites/<site>/sitemap.xml`

#### State Management
- **FR-017**: System MUST read/write state from `Resources/sitemap-state.json`
- **FR-018**: System MUST track package version and generated date per subdomain
- **FR-019**: System MUST use ISO8601 format for all timestamps

#### Error Handling
- **FR-020**: System MUST exit with non-zero code on any validation failure
- **FR-021**: System MUST provide actionable error messages with context
- **FR-022**: System MUST support `--verbose` flag for detailed output
- **FR-023**: System MUST ensure all commands are idempotent (safe to re-run with identical results)

### Key Entities

- **SitemapEntry**: URL, lastmod date
- **SiteConfiguration**: Site name, output directory, URL discovery strategy, lastmod strategy
- **StateFile**: Package version, generated date, subdomain mappings
- **ValidationResult**: Pass/fail status, error messages, warnings

## Clarifications

### Session 2025-12-15

- Q: After migration, how should existing consumers access the moved utilities? → A: Gradual migration — start with re-exports from DesignSystem for backward compatibility, end with breaking change requiring `import Utilities`
- Q: Which sitemap XML elements should be included for each URL entry? → A: Minimal — `<loc>` and `<lastmod>` only (changefreq/priority deferred to backlog)
- Q: Should CLI commands be safe to re-run multiple times with the same result? → A: Fully idempotent — re-running any command produces identical output; overwrites are safe
- Q: What is the current state of HeadersValidator? → A: Not yet implemented — build fresh as part of `util headers` subcommand
- Q: Where are the existing sitemap utilities located? → A: `Sources/DesignSystem/Utilities/` plus inline bash in `generate-docc.yml` (L145-204) and `generate-markdown.yml` (L245-302) to consolidate

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: `Utilities` library target compiles and exports all migrated APIs
- **SC-002**: `util` CLI executes all subcommands without runtime errors
- **SC-003**: All 18+ existing sitemap utility tests pass after migration
- **SC-004**: Sitemap generation completes in under 2 seconds for all subdomains combined
- **SC-005**: Build time remains under 2 minutes (no performance regression from baseline)
- **SC-006**: Zero code duplication between Utilities library and DesignSystem
- **SC-007**: CLI provides helpful `--help` output for all commands and subcommands
- **SC-008**: HeadersValidator functionality fully migrated to `util headers` subcommand
