# Phase 1: Data Model

**Feature**: LLM-Optimized Markdown Documentation Subdomain  
**Date**: 2025-10-16  
**Status**: Not Applicable

## Overview

This feature implements CI/CD infrastructure for documentation generation. There is no persistent data model, database schema, or application state to design.

## Transient Data Structures

### GitHub Actions Artifacts (Temporary)

**markdown-docs**
- **Type**: Zipped directory or raw directory
- **Lifecycle**: Created by generate-markdown.yml → consumed by deploy-cloudflare.yml → deleted after 1 day
- **Size**: ~1.2MB compressed
- **Structure**:
  ```
  md-21-dev/
  ├── index.md
  ├── p256k.md
  ├── p256k/*.md (1,285 files)
  ├── zkp.md
  └── zkp/*.md (1,285 files)
  ```
- **Retention**: 1 day (FR-019)

### Workflow State (Implicit)

**generate-markdown.yml outputs**:
- `artifact-name`: Name of uploaded markdown docs artifact (passed to deployment job)

**deploy-cloudflare.yml inputs**:
- `artifact-name`: Name to download from artifacts
- `project-name`: Cloudflare Pages project ID ("md-21-dev")
- `deploy-to-production`: Boolean (merged PR = true, preview = false)

### File System State (CI Workspace - Ephemeral)

**During Workflow Execution**:
```
/Archives/
  └── md-21-dev.doccarchive/    # DocC output (auto-cleaned by CI)

/Websites/
  └── md-21-dev/                # Final markdown (uploaded as artifact)
```

**Lifecycle**: Created during CI run → destroyed when workflow completes

## Configuration Data

### Package.swift Dependencies

```swift
.package(url: "https://github.com/21-DOT-DEV/swift-secp256k1", exact: "0.21.1"),
.package(url: "https://github.com/swiftlang/swift-docc-plugin", exact: "1.4.5"),
.package(url: "https://github.com/P24L/DocC4LLM.git", exact: "1.0.0"),  // NEW
```

- **Type**: Static configuration
- **Version Control**: Committed to repository
- **Updates**: Manual (Dependabot PRs)

### Cloudflare Pages Configuration

- **Project Name**: "md-21-dev" (pre-existing)
- **Custom Domain**: "md.21.dev"
- **Framework Preset**: None (static files)
- **Build Command**: None (pre-built by CI)
- **Publish Directory**: artifact root
- **Environment Variables**: None required

**Note**: Configuration exists in Cloudflare UI, not in repository.

## External Index Files

### llms.txt

- **Location**: `Resources/21-dev/llms.txt`
- **Format**: Markdown (llms.txt standard)
- **Deployment**: Part of 21.dev site build
- **Updates**: Manual edits when adding new packages

### agents.md (Template)

- **Location**: `Resources/21-dev/agents-md-template.md`
- **Usage**: Copy to swift-secp256k1 repository
- **Deployment**: Not deployed from this repository

## Rationale

This feature has no persistent data layer because:
1. Documentation is generated artifacts (ephemeral CI outputs)
2. Final output is static files (no database, no runtime state)
3. Configuration is declarative (YAML workflows, Package.swift)
4. Deployment is stateless (Cloudflare Pages serves static content)

All state management is handled by:
- **GitHub Actions**: Workflow orchestration, artifact storage
- **Cloudflare Pages**: Deployment history, rollback capability
- **Package.resolved**: Dependency version locking

## Next Phase

Phase 2 task generation will focus on:
- Workflow file creation (YAML)
- Constitution amendment
- Index file creation
- Package.swift updates
- Cloudflare configuration verification
