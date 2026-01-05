# Research: Unified PR Deployment Comments

**Feature**: 007-pr-deployment-comments  
**Date**: 2026-01-04

## Research Tasks

### 1. gh CLI Comment Operations

**Task**: Determine best approach for reading and writing PR comments via gh CLI.

**Decision**: Use `gh issue view` for reading, `gh issue comment` for writing.

**Rationale**: 
- `gh issue view {pr} --comments --json comments` returns structured JSON with all comments
- `gh issue comment {pr} --edit-last --body "..."` handles upsert logic
- Both commands work with PR numbers (PRs are issues in GitHub API)
- GITHUB_TOKEN authentication is automatic in Actions

**Alternatives Considered**:
- `gh api` direct calls: More complex, requires pagination handling
- GraphQL mutations: Overkill for this use case

### 2. Comment Body Structure

**Task**: Define the comment body format with embedded JSON state.

**Decision**: Hidden HTML comment at start, followed by visible markdown.

**Rationale**:
```markdown
<!-- util-deployments:{"21-dev":{"status":"success","previewUrl":"...","aliasUrl":"..."}} -->
### Deployment Preview 🚀
**Commit**: abc1234 | **Run**: [View Logs](...)

| Subdomain | Status | Preview URL | Alias URL |
|-----------|--------|-------------|-----------|
| 21.dev | ✅ | [link](...) | [link](...) |
```

- HTML comments don't render in GitHub
- JSON is at the start for easy extraction via regex
- Marker prefix `util-deployments:` identifies our comment
- Visible content is human-readable

**Alternatives Considered**:
- JSON at end: Harder to parse with trailing whitespace variations
- Separate metadata comment: Requires managing two comments

### 3. JSON State Schema

**Task**: Define the JSON structure for deployment state.

**Decision**: Dictionary keyed by project name.

**Rationale**:
```json
{
  "21-dev": {
    "status": "success",
    "previewUrl": "https://abc123.21-dev.pages.dev",
    "aliasUrl": "https://preview.21.dev"
  },
  "docs-21-dev": {
    "status": "success",
    "previewUrl": "https://abc123.docs-21-dev.pages.dev",
    "aliasUrl": "https://preview.docs.21.dev"
  }
}
```

- Project name as key enables O(1) lookup and update
- Flat structure is easy to serialize/deserialize with Codable
- No timestamps needed (GitHub comment shows edit time)

### 4. Swift subprocess Invocation Pattern

**Task**: Determine how to invoke gh CLI from Swift.

**Decision**: Use `Subprocess.run` from swift-subprocess with captured output.

**Rationale**:
```swift
let result = try await Subprocess.run(
    .named("gh"),
    arguments: ["issue", "view", "\(prNumber)", "--json", "comments"]
)
let output = String(data: result.standardOutput, encoding: .utf8)
```

- swift-subprocess is already a dependency in UtilLib
- `Subprocess.run` is simple and synchronous-looking with async/await
- Captures stdout/stderr for parsing and error handling

### 5. Error Handling Strategy

**Task**: Define error handling for gh CLI failures.

**Decision**: Throw typed errors, let command wrapper handle exit codes.

**Rationale**:
- `CommentService` throws `CommentError` enum (notAuthenticated, cliNotFound, apiError)
- `CommentCommand` catches errors and exits with non-zero code
- Minimal output on success (single line), detailed error on failure

## Summary

All technical unknowns resolved. Implementation can proceed with:
1. Codable models for JSON state
2. CommentService with gh CLI invocation
3. Markdown generator for comment body
4. CommentCommand as ArgumentParser wrapper
