# Development Tools

Tooling for the [Development](../../README.md) tree, kept small enough to build and test on
its own. Everything below runs from the repository root.

    # Unit tests — parsing, cross-references, index tables
    swift test --package-path Development/Tools

    # Rewrite the index tables in Specs/README.md and ADRs/README.md
    swift run --package-path Development/Tools plans

    # CI mode — fail if an index is stale or a document is invalid
    swift run --package-path Development/Tools plans --check

## Why a second package

This manifest exists alongside the root `Package.swift` rather than adding targets to it.
The root manifest resolves the site's entire dependency graph — Slipstream pinned to the
moving `develop` branch, SwiftSoup, Subprocess, the Tailwind build plugin — before building
any target, so a documentation check would resolve (and block on) the site it merely
observes. This package resolves two pinned dependencies, needs nothing from the site build,
and builds and tests in seconds from cold. The layout is deliberately small and focused:

- `Sources/PlanIndex/` is the library — the schema, the checks, the index generator.
- `Sources/plans/` is the executable entry point that reports what the library found.
- `Tests/` exercises the library through the command line's own entry points.

## Dependencies

- [`swift-yaml`](https://github.com/21-DOT-DEV/swift-yaml) — decodes the YAML frontmatter in
  every plan and ADR. Pinned to a commit; exact-version pinning is only used where a
  transitory package-resolution bug made it unusable (see below).
- [`swift-argument-parser`](https://github.com/apple/swift-argument-parser) — gives `plans`
  real flag parsing instead of a string compare. Exact version; a `1.6.1...<2.0.0` range
  once resolved 1.6.1's transitive `swift-syntax` pin to a commit that no longer built,
  which is the bug named above. Exact pinning keeps that failure mode out.

The YAML package requires C++ interoperability (`.interoperabilityMode(.Cxx)` on both
targets). Keeping it inside this package means the site targets never see that build
requirement.

## Layout rules

The package is self-contained: it reads the `Development/` tree relative to the working
directory, has no build-time access to the site's sources, and its `Package.swift` is the
only manifest it will ever need. New checks go in `PlanIndex`; new command surface goes in
the same `plans` executable (a subcommand), not a new target.
