# Quickstart: Unified PR Deployment Comments

**Feature**: 007-pr-deployment-comments  
**Date**: 2026-01-04

## Overview

This feature adds a `comment` subcommand to the `util` CLI that posts unified deployment comments on GitHub PRs, aggregating multiple subdomain deployments into a single comment.

## Prerequisites

- Swift 6.1+
- GitHub CLI (`gh`) installed and authenticated
- Repository with GitHub Actions workflows

## Local Development

### 1. Build the util CLI

```bash
cd /Users/csjones/Developer/websites
nocorrect swift build
```

### 2. Run Tests

```bash
nocorrect swift test --filter UtilLibTests
```

### 3. Test Locally (requires gh auth)

```bash
# Ensure you're authenticated
gh auth status

# Test with a real PR (use a test PR)
swift run util comment \
  --pr 123 \
  --project 21-dev \
  --status success \
  --preview-url "https://test.pages.dev" \
  --alias-url "https://preview.21.dev" \
  --commit "$(git rev-parse HEAD)" \
  --run-url "https://github.com/21-DOT-DEV/websites/actions/runs/1"
```

## Files to Create/Modify

### New Files

| File | Purpose |
|------|---------|
| `Sources/UtilLib/Models/DeploymentComment.swift` | Data models (DeploymentEntry, CommentState) |
| `Sources/UtilLib/Services/CommentService.swift` | gh CLI invocation, state parsing, markdown generation |
| `Sources/util/Commands/CommentCommand.swift` | ArgumentParser command wrapper |
| `Tests/UtilLibTests/CommentServiceTests.swift` | Unit tests |

### Modified Files

| File | Change |
|------|--------|
| `Sources/util/Util.swift` | Add `CommentCommand.self` to subcommands |
| `.github/workflows/deploy-cloudflare.yml` | Replace bash comment logic with `swift run util comment` |

## Implementation Order

1. **Models** (`DeploymentComment.swift`)
   - `DeploymentStatus` enum
   - `DeploymentEntry` struct
   - `CommentState` struct

2. **Service** (`CommentService.swift`)
   - `fetchExistingComments(pr:)` → calls `gh issue view`
   - `parseCommentState(from:)` → extracts JSON from marker
   - `mergeDeployment(_:into:)` → updates state
   - `generateCommentBody(from:)` → renders markdown
   - `postComment(pr:body:)` → calls `gh issue comment`

3. **Command** (`CommentCommand.swift`)
   - Argument parsing
   - Orchestrates service calls
   - Error handling and exit codes

4. **Tests** (`CommentServiceTests.swift`)
   - Test JSON parsing
   - Test markdown generation
   - Test state merging
   - Mock gh CLI responses

5. **Workflow Update** (`deploy-cloudflare.yml`)
   - Remove bash comment generation
   - Add `swift run util comment` call

## Testing Strategy

### Unit Tests (mocked gh CLI)

```swift
@Test func parseCommentState_extractsJSON() {
    let body = """
    <!-- util-deployments:{"deployments":{"21-dev":{"status":"success"}}} -->
    ### Deployment Preview
    """
    let state = CommentService.parseCommentState(from: body)
    #expect(state?.deployments["21-dev"]?.status == .success)
}

@Test func generateCommentBody_formatsTable() {
    let state = CommentState(...)
    let body = CommentService.generateCommentBody(from: state)
    #expect(body.contains("| 21.dev |"))
}
```

### Integration Test (manual)

1. Create a test PR
2. Run `swift run util comment` with test data
3. Verify comment appears on PR
4. Run again with different project
5. Verify comment updates (not duplicates)

## Success Criteria Verification

| Criterion | How to Verify |
|-----------|---------------|
| SC-001: All 3 subdomains in one comment | Run command 3x with different projects, check PR |
| SC-002: Updates only specific row | Run command twice for same project, verify merge |
| SC-003: < 5 seconds | Time the command execution |
| SC-004: Last write wins | Run concurrent commands, verify no data loss |
| SC-005: Simplified YAML | Compare before/after workflow file |
