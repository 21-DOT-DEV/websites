# AGENTS.md

**NOTE**: Copy this file to the swift-secp256k1 repository root as `AGENTS.md`

## Prerequisites

- **Swift 6.0+** (pin with `.swift-version` file in repo root)
- **Xcode 16+** (macOS) or Swift toolchain (Linux)
- **SwiftPM** (Swift Package Manager)
- **Platforms**: macOS 13+, Linux (Ubuntu 20.04+ - match CI image to avoid glibc mismatches)
- **System deps**: None (pure Swift, libsecp256k1 vendored)

## Setup

```bash
# Clone and setup
git clone https://github.com/21-DOT-DEV/swift-secp256k1.git
cd swift-secp256k1

# Verify Swift version
swift --version  # Expect 6.0+

# Build all targets
swift build

# Run all tests
swift test

# Run tests for specific module
swift test --filter P256KTests
swift test --filter ZKPTests

# Run targeted test
swift test --filter P256KTests/testSigning
```

## Code Style

- Swift 6.0+ with strict concurrency checking
- Follow Swift API Design Guidelines
- Public APIs require documentation comments (`///`)
- Use descriptive names; avoid abbreviations
- Prefer value types over reference types
- All public APIs must have tests

## Common Tasks

```bash
# Build with optimizations (release mode)
swift build -c release

# Run single test
swift test --filter TestClassName.testMethodName

# Run targeted test example
swift test --filter P256KTests/testSigning

# Generate test coverage (if xcov or similar configured)
swift test --enable-code-coverage

# Clean build artifacts
swift package clean

# Update dependencies
swift package update

# Run static analysis (if swiftlint configured)
swiftlint lint

# Format code (if swiftformat configured)
swiftformat .
```

## Tooling Configs

- If `.swiftlint.yml` exists, run `swiftlint lint`
- If `.swiftformat` exists, run `swiftformat .` (or `swiftformat --lint` in CI)
- Optional: Use `Makefile` for common tasks:
  ```makefile
  test: ; swift test
  fmt:  ; swiftformat .
  lint: ; swiftlint lint
  ```

## What "Done" Means

- ✅ All tests pass: `swift test`
- ✅ No compiler warnings
- ✅ Code formatted (SwiftFormat if configured)
- ✅ Documentation comments for all public APIs
- ✅ New APIs have corresponding tests
- ✅ Update CHANGELOG.md for user-facing changes
- ✅ CI passes on GitHub Actions (see CI Matrix below)

## Module Structure

This package provides two cryptographic modules:

- **P256K** (`Sources/P256K/`): secp256k1 Elliptic Curve cryptography - key generation, ECDSA signing, ECDH key agreement
- **ZKP** (`Sources/ZKP/`): Zero-Knowledge Proofs - Pedersen commitments, range proofs, Schnorr signatures

ZKP builds on P256K primitives. Both share the secp256k1 curve implementation.

## CI Matrix

GitHub Actions runs tests on:
- **macOS**: macOS 13+, Swift 6.0+, Xcode 16+
- **Linux**: Ubuntu 20.04+, Swift 6.0+

Jobs: `build-and-test-macos`, `build-and-test-linux`

## Reproduce CI Locally

```bash
# Match toolchain, then:
swift build && swift test  # expect zero warnings
```

If CI enforces "zero warnings," ensure your local build is clean before pushing.

## Security Guidelines

**General**:
- Never commit private keys or test secrets
- Use `SecureBytes` for sensitive data
- Clear cryptographic material after use (zeroization)
- Report security issues privately to maintainers (see SECURITY.md)

**Crypto-Specific**:
- All signing/verification operations MUST be constant-time
- Review timing-sensitive code in `Sources/P256K/Implementation/`
- Side-channel tests live in `Tests/P256KTests/SideChannelTests/`
- Fuzzing targets (if present) in `Tests/Fuzz/`
- Never log secret keys, even in debug mode
- Validate all inputs before cryptographic operations

## Scope of Changes Agents May Make

- ✅ Tests, docs, comments, internal refactors (no public symbol changes)
- ✅ Bug fixes that preserve ABI/SPI
- ❌ Public API changes without a semver plan + maintainer approval
- ❌ Swapping cryptographic primitives or parameters without ADR + review

## Performance & Side-Channel Budgets

- ECDSA sign/verify throughput must not regress >5% vs previous release
- No new data-dependent branches/mem access on secret data
- Use constant-time comparisons for secrets; avoid `==` on `Data`/`Array`
- Add/keep microbenchmarks (if using swift-benchmark) under `Benchmarks/`

## Test Determinism

- Use deterministic RNG fixtures for unit tests (seeded)
- No network or wall-clock assumptions in tests
- If fuzzing present, gate it behind an explicit flag/job (not default `swift test`)

## Important Repository Files (Portable Links)

- [SECURITY.md](./SECURITY.md): Security policy and vulnerability reporting
- [CONTRIBUTING.md](./CONTRIBUTING.md): Contribution guidelines and PR process
- [CHANGELOG.md](./CHANGELOG.md): Version history and breaking changes
- [Package.swift](./Package.swift): Package manifest and dependencies
- [README.md](./README.md): Project overview and quick start

Configuration (if present):
- [.swiftlint.yml](./.swiftlint.yml): Linting rules
- [.swiftformat](./.swiftformat): Code formatting rules
- [.swift-version](./.swift-version): Swift toolchain version pin

## Important Repository Files (Agent Imports)

For agents that support @imports (local-first for offline/air-gapped environments):

@./SECURITY.md
@./CONTRIBUTING.md
@./CHANGELOG.md
@./README.md
@./Package.swift

## API Documentation (Portable Links)

**Remote** (online):
- [Root Index](https://md.21.dev/): Documentation structure and navigation
- [P256K Module](https://md.21.dev/p256k.md): Elliptic Curve operations reference
- [ZKP Module](https://md.21.dev/zkp.md): Zero-Knowledge Proof operations reference
- [Example Symbol](https://md.21.dev/p256k/sharedsecret.md): Sample documentation format

**Local** (if Docs/ directory exists in repo):
- [Docs/INDEX.md](./Docs/INDEX.md): Local documentation index
- [Docs/API.md](./Docs/API.md): Local API reference summary

Documentation format: Individual markdown files per symbol (~2,500 files total)
Pattern: `/{module}/{symbol-name}.md`
Structure: Swift signatures, parameters, return types, source links

## API Documentation (Agent Imports)

For agents that support @imports (local-first):

**Local** (offline-friendly, if Docs/ exists):
@./Docs/INDEX.md
@./Docs/API.md
@./SECURITY.md
@./CONTRIBUTING.md
@./CHANGELOG.md
@./README.md

**Remote** (mirrors, requires internet):
@https://md.21.dev/p256k.md
@https://md.21.dev/zkp.md

## Releases

```bash
# Tag release
git tag vX.Y.Z && git push --tags

# Update CHANGELOG.md under the same version
```

**Documentation**: Always reflects the latest swift-secp256k1 release:
- https://md.21.dev/p256k.md
- https://md.21.dev/zkp.md

*Note: Versioned documentation paths (e.g., `/vX.Y.Z/`) are planned for future implementation.*

## Discovery

Documentation indexed at:
- https://21.dev/llms.txt (llms.txt standard)
- This file (AGENTS.md in repository root)

Documentation automatically regenerates on new package releases.
