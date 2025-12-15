# Research: Cloudflare _redirects Implementation

**Feature**: 003-cloudflare-redirects  
**Date**: 2025-12-14

## Overview

Minimal research required — this is a configuration-only feature using established Cloudflare Pages patterns already in use for `_headers` files.

## Decision 1: Cloudflare _redirects Syntax

**Decision**: Use standard Cloudflare Pages `_redirects` format

**Rationale**: Native Cloudflare Pages feature, no external dependencies, well-documented

**Syntax Reference**:
```text
# Format: source destination [status]
/old-path /new-path 301
/another-old /another-new 302
```

**Key Rules**:
- One redirect per line
- Comments start with `#`
- Default status is 302 if omitted
- Supports splats (`/*`) and placeholders (`:id`)
- Processed before file lookup (redirects take precedence)
- Maximum 2000 rules per project

**Source**: [Cloudflare Pages Redirects Documentation](https://developers.cloudflare.com/pages/configuration/redirects/)

## Decision 2: Trailing Slash Handling

**Decision**: Use trailing slashes in redirect destinations (e.g., `/documentation/`)

**Rationale**: 
- Matches Cloudflare Pages "Add trailing slashes" default setting
- Consistent with DocC-generated URL structure
- Prevents double-redirect scenarios

**Alternatives Considered**:
- No trailing slashes: Rejected — would conflict with Cloudflare's normalization

## Decision 3: Smoke Test Implementation

**Decision**: Use `curl -sI` to verify 301 status code in CI

**Rationale**: 
- Lightweight, no dependencies
- Direct verification of HTTP response
- Matches existing CI patterns

**Implementation Pattern**:
```bash
# Verify redirect returns 301
status=$(curl -sI -o /dev/null -w "%{http_code}" "https://docs.21.dev/")
if [ "$status" != "301" ]; then
  echo "ERROR: Expected 301, got $status"
  exit 1
fi
```

## Decision 4: File Copy Pattern

**Decision**: Use `cp` command in workflow, matching `_headers` pattern

**Rationale**:
- Consistency with existing infrastructure
- No Swift code changes required
- Simple, reliable

**Existing Pattern** (from `_headers`):
```yaml
- name: Copy _headers file
  run: cp Resources/docs-21-dev/_headers.prod Websites/docs-21-dev/_headers
```

## No Further Research Required

All technical decisions are straightforward applications of existing patterns. No NEEDS CLARIFICATION items remain.
