# Implementation Plan: Unified PR Deployment Comments

**Branch**: `007-pr-deployment-comments` | **Date**: 2026-01-04 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/007-pr-deployment-comments/spec.md`

## Summary

Refactor the inline bash comment generation in `deploy-cloudflare.yml` into a Swift CLI command (`swift run util comment`) that aggregates multiple subdomain deployments (21-dev, docs-21-dev, md-21-dev) into a single unified PR comment. The command uses `gh` CLI via swift-subprocess, stores state in hidden HTML comment metadata, and generates a markdown table with per-subdomain rows.

## Technical Context

**Language/Version**: Swift 6.1+  
**Primary Dependencies**: swift-subprocess (existing), swift-argument-parser (existing), gh CLI (external)  
**Storage**: N/A (state embedded in PR comment body)  
**Testing**: swift-testing with mocked gh CLI invocations  
**Target Platform**: macOS 15+ (GitHub Actions runner), Linux (CI)  
**Project Type**: CLI extension (existing util target)  
**Performance Goals**: < 5 seconds per invocation  
**Constraints**: Must work in GitHub Actions environment with GITHUB_TOKEN  
**Scale/Scope**: 3 subdomains, single PR comment per PR

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Notes |
|-----------|--------|-------|
| I. Static-First | ✅ N/A | CLI tool, not site content |
| II. Spec-First & TDD | ✅ Pass | Spec complete, TDD planned |
| III. Accessibility | ✅ N/A | CLI tool |
| IV. Design System | ✅ N/A | Not a UI component |
| V. Zero-Dependency | ✅ Pass | Uses existing approved deps (swift-subprocess, swift-argument-parser) |
| VI. Security | ✅ Pass | Relies on gh CLI auth, no secrets in code |
| VII. Open Source | ✅ Pass | Will document CLI usage |

**IaC Exemption**: Workflow YAML changes exempt from TDD per constitution; validated via PR execution.

## Project Structure

### Documentation (this feature)

```text
specs/007-pr-deployment-comments/
├── spec.md              # Feature specification (complete)
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output (CLI interface)
└── tasks.md             # Phase 2 output (/speckit.tasks)
```

### Source Code (repository root)

```text
Sources/
├── UtilLib/
│   ├── Models/
│   │   └── DeploymentComment.swift    # NEW: DeploymentEntry, CommentState models
│   └── Services/
│       └── CommentService.swift       # NEW: gh CLI invocation, state parsing, markdown gen
└── util/
    └── Commands/
        └── CommentCommand.swift       # NEW: ArgumentParser command wrapper

Tests/
└── UtilLibTests/
    ├── DeploymentCommentTests.swift   # NEW: Model tests (DeploymentEntry, CommentState)
    └── CommentServiceTests.swift      # NEW: Service tests with mocked gh CLI
```

**Structure Decision**: Split implementation follows existing pattern—`UtilLib` contains reusable models and logic (testable), `util` contains thin command wrappers. Matches `SitemapCommand`/`SitemapUtilities` pattern.

## Planning Decisions

Captured from clarification session:

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Testing | Unit tests with mocked gh CLI | Avoid CI flakiness, gh CLI is well-tested |
| Code organization | UtilLib + util split | Matches existing pattern, enables unit testing |
| Comment retrieval | `gh issue view --json comments` | Structured JSON output, no pagination |
| Comment identification | By marker prefix | Robust against other bots/title changes |
| Workflow update | Replace entirely | Clean cutover, git revert available |

## Complexity Tracking

No violations to justify. Feature uses existing patterns and approved dependencies.
