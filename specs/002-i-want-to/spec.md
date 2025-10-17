# Feature Specification: LLM-Optimized Markdown Documentation Subdomain

**Feature Branch**: `002-i-want-to`  
**Created**: 2025-10-16  
**Status**: Draft  
**Input**: User description: "I want to add a new subdomain for llms, md.21.dev, to read markdown file versions of my package documentation."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - LLM Accesses Structured Markdown API Documentation (Priority: P1)

As a Large Language Model (LLM) or AI agent, I want to retrieve API documentation for the swift-secp256k1 library in structured markdown format from md.21.dev, so that I can parse, understand, and provide accurate information about cryptographic functions to end users.

**Why this priority**: This is the core value proposition - enabling AI systems to access machine-readable documentation. Without this, LLMs cannot effectively assist users with swift-secp256k1 API questions.

**Independent Test**: Can be fully tested by fetching markdown files from md.21.dev programmatically, parsing them, and verifying all public API symbols (types, functions, properties) from both P256K and ZKP targets are present with complete documentation.

**Acceptance Scenarios**:

1. **Given** an LLM needs information about swift-secp256k1 APIs, **When** it requests documentation from md.21.dev, **Then** it receives markdown files with structured API information (symbol names, parameters, return types, descriptions).
2. **Given** an LLM is parsing P256K target documentation, **When** it reads the markdown format, **Then** it can extract all public types, functions, and their documentation without HTML parsing or JavaScript execution.
3. **Given** an LLM needs source code context, **When** it encounters a documented symbol in markdown, **Then** it finds links to exact source file locations in the swift-secp256k1 GitHub repository.
4. **Given** an LLM is indexing documentation, **When** it traverses the markdown file structure, **Then** it discovers all documented symbols across both P256K and ZKP targets through a consistent, predictable file hierarchy.

---

### User Story 2 - Automatic Documentation Updates (Priority: P2)

As a documentation maintainer, I want markdown documentation at md.21.dev to automatically regenerate and redeploy when swift-secp256k1 releases a new version, so that LLMs always reference current API information without manual intervention.

**Why this priority**: Keeps LLM-accessible documentation synchronized with library releases, preventing AI systems from providing outdated information to users. Essential for maintenance efficiency and accuracy.

**Independent Test**: Can be tested by triggering a package version update, verifying the documentation regeneration workflow executes automatically, and confirming md.21.dev serves the updated markdown with new API changes.

**Acceptance Scenarios**:

1. **Given** swift-secp256k1 releases version 0.22.0, **When** the package dependency is updated, **Then** the markdown documentation regeneration workflow automatically triggers.
2. **Given** a pull request updates Package.resolved with a new swift-secp256k1 version, **When** the PR is opened, **Then** the CI system generates test markdown documentation to verify no breaking changes in export format.
3. **Given** test documentation generation succeeds, **When** the PR is merged to main, **Then** final markdown documentation is generated and deployed to md.21.dev within 15 minutes.
4. **Given** documentation generation fails during PR validation, **When** a reviewer examines CI logs, **Then** they see clear error messages indicating what went wrong (missing symbols, export errors, archive corruption).

---

### User Story 3 - Preview Documentation Before Production Deployment (Priority: P3)

As a code reviewer, I want to preview generated markdown documentation in pull requests before merging, so that I can verify export quality, completeness, and format correctness before LLMs consume it.

**Why this priority**: Quality assurance step that prevents malformed or incomplete markdown from reaching production where LLMs would consume it. Lower priority than core generation but important for reliability.

**Independent Test**: Can be tested by creating a test PR that updates swift-secp256k1, verifying CI generates preview markdown documentation, and confirming the preview is accessible for manual inspection.

**Acceptance Scenarios**:

1. **Given** a PR updates swift-secp256k1 version, **When** CI completes markdown documentation generation, **Then** a preview URL is posted in PR comments linking to the generated markdown files.
2. **Given** a reviewer has a preview URL, **When** they inspect the markdown files, **Then** they can verify symbol completeness, proper markdown formatting, working source links, and correct target organization.
3. **Given** the preview documentation looks correct, **When** the PR is merged, **Then** the same markdown content is deployed to production md.21.dev.
4. **Given** the test generation identifies format issues, **When** a reviewer examines the PR, **Then** they see a clear failure message explaining what needs fixing before merge.

---

### Edge Cases

- What happens when DocC4LLM export produces invalid markdown (malformed tables, broken links)? Documentation generation should fail with clear error message pointing to the problematic symbol or file.
- What happens when the swift-secp256k1 repository is unavailable during archive generation? Documentation should still generate but source links may be missing or broken (workflow should warn but not fail).
- What happens if DocC4LLM tool is not available in CI environment (not in Package.swift or build fails)? Workflow should fail immediately with clear error message indicating DocC4LLM dependency issue.
- What happens when multiple Dependabot PRs update different packages simultaneously? Only PRs touching swift-secp256k1 should trigger markdown documentation regeneration (path filtering prevents unnecessary runs).
- What happens when markdown output size exceeds Cloudflare Pages limits? Documentation generation should fail with size metrics and suggestions to split content.
- What happens if DocC archive generation succeeds but markdown export fails? CI should fail the workflow with export error details; .doccarchive remains in workspace for inspection but is auto-cleaned after job completion.
- What happens if markdown filenames contain special characters that cause artifact upload issues? System should fallback to zipping markdown directory before upload (consistent with docs.21.dev approach for path issues).
- What happens when reusable workflow (deploy-cloudflare.yml) receives markdown artifact but expects different structure? Artifact extraction logic should handle both zipped and directory artifacts (already implemented in docs.21.dev workflow).
- What happens if the awk split command fails or produces incomplete files? CI should validate expected file count (2,500+ individual files) and fail with diagnostic output if split is incomplete.
- What happens if DocC4LLM changes delimiter format in future versions? Split logic should detect format and fail gracefully with clear error message if delimiters are missing or changed.

## Requirements *(mandatory)*

### Functional Requirements

**Documentation Generation**:
- **FR-001**: System MUST generate DocC archive for exactly two targets from swift-secp256k1 package: P256K and ZKP.
- **FR-002**: System MUST use combined documentation feature to merge both targets into a unified archive.
- **FR-003**: System MUST export DocC archive to markdown format using DocC4LLM tool.
- **FR-004**: System MUST document only symbols with `public` access modifier (excludes internal, private, package, @usableFromInline).
- **FR-005**: System MUST include source code links in markdown pointing to exact file and line numbers in swift-secp256k1 GitHub repository.

**Hosting & Deployment**:
- **FR-006**: Markdown documentation MUST be accessible at md.21.dev subdomain exclusively.
- **FR-007**: System MUST deploy to a separate Cloudflare Pages project (not part of main 21.dev or docs.21.dev sites).
- **FR-008**: Documentation MUST be pure static markdown and HTML files with no runtime dependencies.
- **FR-009**: System MUST configure Cloudflare Pages project to use md.21.dev as custom domain.
- **FR-010**: Documentation MUST be publicly accessible without authentication to enable LLM access.

**CI/CD & Automation**:
- **FR-011**: System MUST detect dependency updates that affect swift-secp256k1 package version.
- **FR-012**: System MUST run test markdown documentation generation on all PRs affecting swift-secp256k1.
- **FR-013**: Test documentation builds MUST fail the PR if generation or export encounters errors.
- **FR-014**: System MUST generate and deploy final markdown documentation automatically after PR merge to main branch, using `github.event.pull_request.merged == true` to distinguish merged PRs from closed/abandoned PRs.
- **FR-015**: CI MUST trigger on the same events as docs.21.dev workflow: PR changes to Package.swift/Package.resolved, and manual workflow_dispatch.
- **FR-016**: System MUST preserve existing CI workflows for docs.21.dev and 21.dev sites (no interference).
- **FR-017**: Documentation generation MUST use Package.resolved to ensure exact dependency versions match PR testing.
- **FR-018**: Preview documentation MUST deploy to Cloudflare preview URLs with URL posted in PR comments.
- **FR-019**: Build artifacts MUST retain 1-day retention for passing between CI jobs.
- **FR-032**: System MUST follow reusable workflow pattern: create dedicated generate-markdown.yml workflow, reuse existing deploy-cloudflare.yml, and orchestrate via MD-21-DEV.yml (mirrors docs.21.dev architecture).
- **FR-033**: System MUST zip markdown output directory before artifact upload (matching generate-docc.yml pattern to avoid GitHub Actions path validation issues). Zip MUST be created from inside the directory to prevent double-nesting. Original directory MUST be removed after zipping to save space.
- **FR-034**: DocC4LLM MUST be temporarily added to Package.swift as executable product and invoked via complete command: `swift run docc4llm export Archives/md-21-dev.doccarchive --format markdown --output-path md-21-dev-concatenated.md` until Swift plugin migration is complete.
- **FR-035**: System MUST generate DocC archive to ./Archives/md-21-dev.doccarchive and export markdown to ./Websites/md-21-dev/ (archive auto-cleaned by CI workspace cleanup).
- **FR-036**: System MUST split DocC4LLM monolithic markdown output into individual per-symbol files organized by target directory (p256k/, zkp/) using delimiter markers (`=== START FILE:` / `=== END FILE ===`). Path transformation MUST strip `data/documentation/` prefix and replace any file extension with `.md` to produce final paths matching pattern `{target}/{symbol}.md`.
- **FR-037**: System MUST validate DocC4LLM output format before splitting by checking delimiter marker counts: START markers (`=== START FILE:`) and END markers (`=== END FILE ===`) must both be >0 AND must have matching counts, failing with clear error message showing both counts if validation fails.
- **FR-038**: System MUST monitor documentation size (file count and total MB) and log warnings if approaching Cloudflare Pages limits (warn at 15,000 files or 20MB) without failing the workflow.
- **FR-039**: DocC4LLM version MUST be pinned to exact version in Package.swift (e.g., `.exact("1.0.0")`) to ensure reproducible builds and prevent unexpected format changes.
- **FR-042**: MD-21-DEV.yml orchestrator workflow MUST pass documentation targets as input parameter `targets: "P256K ZKP"` to generate-markdown.yml reusable workflow, which uses the target names directly without modification.
- **FR-043**: generate-markdown.yml MUST output artifact-name via job outputs, and MD-21-DEV.yml MUST pass it to deploy-cloudflare.yml using `${{ needs.generate.outputs.artifact-name }}` expression (matching docs-21-dev artifact passing pattern).
- **FR-044**: MD-21-DEV.yml deploy job MUST declare `needs: generate` dependency to ensure sequential execution (matching DOCS-21-DEV.yml pattern); deploy job automatically skipped if generate job fails.

**Quality & Validation**:
- **FR-020**: Generated markdown MUST maintain proper formatting (valid markdown syntax, tables, links).
- **FR-021**: All source code links MUST point to correct file and line number in swift-secp256k1 repository.
- **FR-022**: System MUST log errors with actionable context when generation or export fails (step name, error type, affected paths).
- **FR-023**: Preview deployments MUST be validated by reviewers before PR merge to catch formatting or export issues.
- **FR-024**: Production documentation rollback MUST be available via Cloudflare Pages deployment history UI.

**LLM Optimization**:
- **FR-025**: Markdown output MUST be optimized for machine parsing (consistent structure, predictable hierarchy, no dynamic content).
- **FR-026**: File organization MUST follow a shallow two-level hierarchy (target/symbol.md) with individual markdown files per documented symbol to simplify LLM navigation and enable direct symbol access.
- **FR-027**: Each documented symbol MUST be reachable through predictable file paths following the pattern: {target}/{symbol-name}.md (e.g., p256k/int128.md).
- **FR-028**: Markdown MUST NOT include unnecessary styling, scripts, or UI elements (optimized for content extraction, not human browsing).
- **FR-040**: LLM discovery MUST rely on external index files (llms.txt at 21.dev following llms.txt standard, agents.md in swift-secp256k1 repository) rather than generating indexes within md.21.dev.
- **FR-041**: md.21.dev MUST include a root index.md file explaining the documentation structure for human visitors who accidentally browse the site.

**Constitutional Compliance**:
- **FR-029**: DocC4LLM MUST be added as an approved dependency in the project constitution (requires amendment).
- **FR-030**: Constitution MUST document the planned future migration to DocC4LLM as a Swift plugin for build-time-only dependency.
- **FR-031**: Documentation-only workflow targets MAY use external tools for export without violating zero-dependency principle for runtime code.

### Assumptions

- swift-secp256k1 package maintainers write documentation comments for public APIs.
- DocC4LLM tool produces valid markdown output from .doccarchive format.
- DocC4LLM is compatible with DocC archives generated by swift-docc-plugin 1.4.5+.
- DocC4LLM can be added to Package.swift as an executable product and invoked via `swift run docc4llm`.
- DocC4LLM exports all documentation as a single concatenated markdown file with delimiter markers (`=== START FILE:` / `=== END FILE ===`), requiring post-processing to split into individual files.
- The awk-based splitting process preserves directory structure encoded in file paths within the concatenated output.
- Cloudflare Pages account has capacity for an additional project (md-21-dev).
- GitHub Actions runner has sufficient disk space for DocC archive and markdown output (estimated 100-500MB total, cleaned automatically).
- swift-secp256k1 will remain the only documented package for md.21.dev in near term.
- Package.resolved file is committed to repository and kept up-to-date by Dependabot.
- DocC4LLM will eventually be converted to a Swift plugin, but starts as Package.swift executable dependency.
- LLMs will primarily access documentation via HTTP requests to static markdown files (no special API needed).
- Markdown files will not have filename path issues like DocC HTML output (colons in filenames), but zipping strategy is available as fallback if needed.
- CI workspace cleanup automatically removes ./Archives/ directory after workflow completion (no explicit deletion needed).
- Reusable workflow pattern from docs.21.dev (generate + deploy separation) applies cleanly to markdown generation workflow.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Markdown documentation loads at md.21.dev and contains complete API information for both P256K and ZKP targets accessible via standard HTTP requests.
- **SC-002**: All public APIs from P256K and ZKP appear in markdown format with complete signatures, parameter descriptions, and return type documentation.
- **SC-003**: Source code links in markdown navigate to correct file and line in swift-secp256k1 GitHub repository for 100% of documented symbols.
- **SC-004**: When swift-secp256k1 version is updated in Package.swift, markdown documentation regenerates and deploys to md.21.dev within 15 minutes of PR merge.
- **SC-005**: Documentation generation and markdown export complete within 15 minutes total on CI runners.
- **SC-006**: Markdown documentation remains synchronized with swift-secp256k1 releases with zero manual intervention after initial setup.
- **SC-007**: CI failures provide error messages clear enough to diagnose issues within 5 minutes. Errors must identify which pipeline stage failed (DocC generation, markdown export, file split, validation) and provide relevant file paths or commands.
- **SC-008**: Markdown files are valid according to CommonMark specification and parse correctly in standard markdown parsers.
- **SC-009**: LLM agents can successfully extract API information from md.21.dev markdown files without requiring HTML parsing or JavaScript execution.
- **SC-010**: Markdown documentation at md.21.dev MUST be organized as individual per-symbol files (2,500+ files) accessible via predictable paths (e.g., md.21.dev/p256k/int128.md), not as a single monolithic file.

## Clarifications

### Session 2025-10-16

- Q: How should DocC4LLM versions be managed in Package.swift to ensure reproducible builds? → A: Pin to specific version (e.g., `.exact("1.0.0")`) and manually update when needed (test in preview first)
- Q: What file naming convention should the exported markdown use for individual API symbols? → A: Accept DocC4LLM's concatenated output, then split it using delimiter markers into individual symbol files organized by target (target/symbol-name.md pattern)
- Q: Should the system add validation to detect DocC4LLM format changes? → A: Add format validation before splitting (grep for delimiters, fail if missing or count mismatch)
- Q: Should the system proactively monitor documentation size and warn before hitting Cloudflare limits? → A: Monitor but never fail workflow (log warnings only, manual intervention if needed)
- Q: Should md.21.dev generate index files for LLM discovery? → A: Rely on external indexes only (llms.txt at 21.dev, agents.md in swift-secp256k1 repo) while including a root index.md for human visitors
- Q: What level of detail should CI logs capture during the documentation generation pipeline? → A: Minimal logging - only errors and final status (aligned with FR-022 and SC-007 requirements for actionable error context)
- Q: What exact validation rules should be applied to DocC4LLM delimiter markers before splitting? → A: Both counts >0 AND START count == END count (fail if either count is zero OR if counts don't match)
- Q: How should the workflow detect merged vs abandoned PRs for production deployment? → A: Use github.event.pull_request.merged == true (GitHub's built-in merged flag)
- Q: What are the complete command arguments for DocC4LLM export? → A: swift run docc4llm export Archives/md-21-dev.doccarchive --format markdown --output-path md-21-dev-concatenated.md
- Q: How should documentation targets be passed between orchestrator and reusable workflows? → A: MD-21-DEV.yml passes targets: "P256K ZKP" as input parameter; generate-markdown.yml uses target names directly without modification (swift-secp256k1 targets are named P256K and ZKP, not docs-21-dev-P256K)
- Q: What path transformations should awk apply when splitting files? → A: Strip `data/documentation/` prefix from paths AND ensure all output files use `.md` extension (replace any extension like .json with .md)
- Q: What artifact naming pattern should be used for passing between jobs? → A: Match existing docs-21-dev pattern - generate-markdown.yml outputs artifact-name, MD-21-DEV.yml passes it via needs.generate.outputs.artifact-name (no SHA suffix needed, artifacts scoped per workflow run)
- Q: How should job dependencies be specified in MD-21-DEV.yml? → A: Deploy job uses `needs: generate` for sequential dependency (matching DOCS-21-DEV.yml pattern); deploy automatically skipped if generate fails
- Q: Should markdown directory be zipped before artifact upload? → A: Always zip preemptively (matching generate-docc.yml pattern) - consistent approach, avoids path validation issues, zip from inside directory to prevent nesting

## Future Considerations

**Multi-Package Documentation**: Current implementation focuses on swift-secp256k1. When adding documentation for additional packages, the system may need:
- Per-package subdirectories within md.21.dev
- Aggregated index listing all documented packages
- Cross-package search or navigation

**DocC4LLM Swift Plugin Migration**: Once DocC4LLM is converted to a Swift package plugin:
- Remove external tool dependency from CI workflow
- Integrate as build-time-only plugin in Package.swift
- Update constitution to reflect plugin status (no longer external tool)
- Maintain backward compatibility with existing markdown structure

**LLM-Specific Optimizations**: Future enhancements may include:
- JSON or structured format alongside markdown for easier parsing
- Embeddings or semantic search index for LLM retrieval
- API usage examples in machine-readable format
- Versioned documentation (multiple swift-secp256k1 versions accessible simultaneously)
