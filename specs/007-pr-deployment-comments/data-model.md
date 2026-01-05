# Data Model: Unified PR Deployment Comments

**Feature**: 007-pr-deployment-comments  
**Date**: 2026-01-04

## Entities

### DeploymentEntry

Represents a single subdomain deployment within a PR comment.

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| project | String | Yes | Project identifier (e.g., "21-dev", "docs-21-dev") |
| status | DeploymentStatus | Yes | Deployment outcome |
| previewUrl | String | Yes | Cloudflare preview URL |
| aliasUrl | String | Yes | Cloudflare alias URL |

**Validation Rules**:
- `project` must be non-empty
- `previewUrl` and `aliasUrl` must be valid URLs (https://)
- `status` must be one of: success, failure, pending

### DeploymentStatus

Enum representing deployment outcome.

| Value | Display | Description |
|-------|---------|-------------|
| success | ✅ | Deployment completed successfully |
| failure | ❌ | Deployment failed |
| pending | ⏳ | Deployment in progress (optional) |

### CommentState

JSON structure embedded in HTML comment for state persistence.

```swift
struct CommentState: Codable {
    var deployments: [String: DeploymentEntry]
    var commit: String
    var runUrl: String
}
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| deployments | Dictionary | Yes | Map of project name → DeploymentEntry |
| commit | String | Yes | Git commit SHA (shared across all deployments) |
| runUrl | String | Yes | GitHub Actions run URL (shared) |

**JSON Example**:
```json
{
  "deployments": {
    "21-dev": {
      "project": "21-dev",
      "status": "success",
      "previewUrl": "https://abc123.21-dev.pages.dev",
      "aliasUrl": "https://preview.21.dev"
    },
    "docs-21-dev": {
      "project": "docs-21-dev",
      "status": "success",
      "previewUrl": "https://abc123.docs-21-dev.pages.dev",
      "aliasUrl": "https://preview.docs.21.dev"
    }
  },
  "commit": "abc1234567890",
  "runUrl": "https://github.com/21-DOT-DEV/websites/actions/runs/12345"
}
```

### GitHubComment

Response model for `gh issue view --json comments` output.

| Field | Type | Description |
|-------|------|-------------|
| id | String | Comment ID (for potential future use) |
| body | String | Comment body content |
| author | Object | Author info (login field) |

**Note**: We only need `body` to extract our embedded JSON state.

## State Transitions

### Comment Lifecycle

```
[No Comment] --create--> [Single Deployment]
     │
     └── First deployment triggers comment creation

[Single Deployment] --update--> [Multiple Deployments]
     │
     └── Subsequent deployments merge into existing state

[Multiple Deployments] --update--> [Multiple Deployments]
     │
     └── Re-deployments update specific subdomain row
```

### Deployment Status Transitions

```
[pending] --> [success]  (deployment succeeded)
[pending] --> [failure]  (deployment failed)
[success] --> [success]  (re-deployment succeeded)
[success] --> [failure]  (re-deployment failed)
[failure] --> [success]  (retry succeeded)
```

## Relationships

```
CommentState 1──* DeploymentEntry
     │
     └── Contains multiple deployments keyed by project name

PR Comment 1──1 CommentState
     │
     └── One PR has one unified deployment comment
```
