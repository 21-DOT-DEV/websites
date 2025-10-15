---
trigger: always_on
description: >
  Architectural principles and patterns for Swift-based static sites in this repository.
---

# Swift Architecture

## Core Principles
- Use Swift 6.1+ with Swift Package Manager for all code.
- Organize code into clear, reusable modules; keep APIs minimal and focused.
- Avoid overusing generics or complex type constraints in public APIs.
- Use dependency injection where practical; avoid global state.

## Module Boundaries
- Executable targets for each site in `Sources/<SiteName>/`.
- Shared UI components and utilities in `Sources/DesignSystem/`.
- Keep DesignSystem agnostic of any single site’s business logic.

## Conventions
- File and type names must be descriptive and follow Swift naming guidelines.
- Public APIs require doc comments (`///`) explaining purpose and usage.

## Page Structure
- Each site page should be a struct with static `page` property
- Use `@main` attribute on SiteGenerator in Sitemap.swift for entry point
- Keep page content separate from routing logic