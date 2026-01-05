# Feature Specification: Unified PR Deployment Comments

**Feature Branch**: `007-pr-deployment-comments`  
**Created**: 2026-01-04  
**Status**: Draft  
**Input**: User description: "Refactor deploy-cloudflare.yml PR comment logic into a util CLI command that aggregates multiple subdomain deployments into a single unified comment"

## Clarifications

### Session 2026-01-04

- Q: What should happen when `gh` CLI is not available or not authenticated? → A: Exit immediately with error message and non-zero exit code
- Q: What output should the command produce during normal operation? → A: Minimal output (single success/failure line to stdout)
- Q: Should timestamps be displayed per subdomain in the comment? → A: No timestamp displayed (rely on GitHub's comment edit timestamp)

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Single Subdomain Deployment (Priority: P1)

A developer pushes changes that trigger a deployment for one subdomain (e.g., 21.dev). The workflow runs the util command to post a deployment comment on the PR showing the preview URL and status.

**Why this priority**: This is the baseline functionality—if a single deployment can't post a comment, nothing else works.

**Independent Test**: Can be fully tested by running `swift run util comment` with mock parameters and verifying the generated comment body format.

**Acceptance Scenarios**:

1. **Given** a PR with no existing deployment comment, **When** the util command runs with deployment data for 21-dev, **Then** a new comment is created with the deployment table showing one subdomain row.
2. **Given** a PR with no existing deployment comment, **When** the deployment fails, **Then** the comment shows ❌ status for that subdomain.

---

### User Story 2 - Multiple Subdomain Deployments (Priority: P1)

A developer pushes changes that trigger deployments for multiple subdomains (21.dev, docs.21.dev, md.21.dev). Each deployment workflow invokes the util command, and the PR comment aggregates all deployments into a single unified table.

**Why this priority**: This is the core value proposition—consolidating multiple deployment previews into one readable comment.

**Independent Test**: Can be tested by invoking the command multiple times with different project names and verifying the comment merges all deployments.

**Acceptance Scenarios**:

1. **Given** a PR with an existing deployment comment for 21-dev, **When** the util command runs with deployment data for docs-21-dev, **Then** the existing comment is updated to show both subdomains in the table.
2. **Given** a PR with deployment comments for all three subdomains, **When** any subdomain redeploys, **Then** only that subdomain's row is updated (preserving others).

---

### User Story 3 - Comment State Persistence (Priority: P2)

The deployment comment includes hidden metadata (HTML comment) containing structured JSON state, ensuring robust parsing when updating the comment.

**Why this priority**: Enables reliable comment updates without fragile markdown parsing.

**Independent Test**: Can be tested by verifying the generated comment body contains valid JSON in an HTML comment block.

**Acceptance Scenarios**:

1. **Given** a deployment comment with embedded JSON metadata, **When** the util command parses the existing comment, **Then** it correctly extracts all subdomain deployment data.
2. **Given** a comment without the expected metadata marker, **When** the util command runs, **Then** it treats it as a fresh comment (no crash or error).

---

### Edge Cases

- **gh CLI unavailable/unauthenticated**: Exit immediately with clear error message and non-zero exit code (see FR-014)
- **Concurrent deployments**: Last write wins—acceptable per SC-004; no locking mechanism needed
- **PR closed/merged during deployment**: gh CLI handles gracefully (comment still posts to closed PR); no special handling required
- **Extremely long preview URLs**: No truncation—URLs rendered as-is; GitHub's markdown handles display

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST provide a `comment` subcommand under the `util` CLI tool
- **FR-002**: System MUST accept the following flags: `--pr`, `--project`, `--status`, `--preview-url`, `--alias-url`, `--commit`, `--run-url`
- **FR-003**: System MUST use swift-subprocess to invoke the `gh` CLI for comment operations
- **FR-004**: System MUST use `gh issue comment --edit-last` to update existing comments, falling back to create if none exists
- **FR-005**: System MUST embed deployment state as JSON in a hidden HTML comment (e.g., `<!-- util-deployments:{...} -->`)
- **FR-006**: System MUST parse existing comment body to extract embedded JSON state before updating
- **FR-007**: System MUST merge new deployment data with existing state (keyed by project name)
- **FR-008**: System MUST generate a markdown table with per-subdomain rows (project, status, preview URL, alias URL)
- **FR-009**: System MUST display shared context (commit SHA, action run link) once in the comment header
- **FR-010**: System MUST support status values: `success` (✅), `failure` (❌), and optionally `pending` (⏳)
- **FR-011**: System MUST operate in the current repository context (no explicit `--repo` flag required)
- **FR-012**: System MUST exit with non-zero code if `gh` CLI invocation fails
- **FR-013**: System MUST handle missing or malformed embedded JSON gracefully (treat as empty state)
- **FR-014**: System MUST exit immediately with clear error message if `gh` CLI is unavailable or not authenticated
- **FR-015**: System MUST output a single success/failure line to stdout on completion (minimal verbosity)
- **FR-016**: System MUST NOT include per-subdomain timestamps (GitHub's comment edit timestamp suffices)

### Key Entities

- **DeploymentEntry**: Represents a single subdomain deployment (project name, status, preview URL, alias URL)
- **CommentState**: JSON structure embedded in HTML comment containing deployments dictionary, commit SHA, and run URL (serves as the aggregate container)

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: All three subdomains (21-dev, docs-21-dev, md-21-dev) can be displayed in a single PR comment
- **SC-002**: Running the command multiple times for the same project updates only that project's row
- **SC-003**: The util command completes in under 5 seconds for typical operations
- **SC-004**: Zero data loss when concurrent deployments update the comment (last write wins is acceptable)
- **SC-005**: The workflow YAML is simplified—comment generation logic moves from bash to Swift
