<!--
Sync Impact Report:
- Version: 1.1.0 → 1.2.0 (MINOR - adds approved dependency)
- Principle Modified: II. Zero Dependencies
- Change Type: DocC4LLM added to approved dependencies list
- Core Principle: PRESERVED (Zero dependencies policy maintained with expanded approved list)
- New Dependency: DocC4LLM (markdown export tool) - temporary until Swift plugin available
- Rationale: Only tool for .doccarchive → markdown export; enables LLM-optimized documentation
- Migration Path: Planned conversion to Swift plugin (build-time-only dependency)
- Principles: 6 principles (no additions/removals)
  I. Design System First
  II. Zero Dependencies [MODIFIED - DocC4LLM added to approved list]
  III. Test-First Development (NON-NEGOTIABLE)
  IV. Static Site Architecture
  V. Slipstream API Preference
  VI. Swift 6 + SPM Standards
- Templates Status:
  ✅ spec-template.md - No changes needed
  ✅ plan-template.md - No changes needed
  ✅ tasks-template.md - No changes needed
  ✅ checklist-template.md - No changes needed
- Affected Features:
  ✓ 002-i-want-to (md.21.dev) - Constitutional gate cleared
- Previous Version History:
  • 1.0.0 → 1.1.0 (2025-10-15): Added IaC exemption to Test-First Development
-->

# Static Site Project Constitution

## Core Principles

### I. Design System First

All site development MUST use the DesignSystem target located in `Sources/DesignSystem/`. Every page, component, layout, token, and utility MUST be built using or extending the DesignSystem rather than creating ad-hoc implementations in site-specific code.

**Rationale**: Ensures consistency, reusability, and maintainability across all sites. The DesignSystem serves as the single source of truth for UI patterns and prevents fragmentation.

**Requirements**:
- New components MUST be created in `Sources/DesignSystem/Components/`
- New layouts MUST be created in `Sources/DesignSystem/Layouts/`
- Design tokens MUST be defined in `Sources/DesignSystem/Tokens/`
- Site-specific targets (e.g., `21-dev`) MUST depend on DesignSystem
- No duplication of component logic across sites

### II. Zero Dependencies

The project MUST NOT introduce any dependencies beyond the approved core stack: Slipstream (static site framework), swift-plugin-tailwindcss (styling), swift-docc-plugin (documentation generation), DocC4LLM (markdown export tool), and swift-testing (testing framework). NO additional Swift packages, NPM packages, or third-party frameworks may be added.

**Rationale**: Minimizes complexity, reduces security surface area, ensures long-term maintainability, and keeps build times fast. Every dependency is a liability.

**Requirements**:
- Package.swift MUST contain only: Slipstream, swift-plugin-tailwindcss, swift-docc-plugin, swift-secp256k1, DocC4LLM, swift-testing
- No JavaScript frameworks (React, Vue, Angular, etc.)
- No CSS frameworks beyond TailwindCSS
- No runtime dependencies in generated static sites
- Solutions MUST be implemented using the existing stack

### III. Test-First Development (NON-NEGOTIABLE)

All new features and components MUST follow test-driven development: tests are written first, reviewed and approved, verified to fail, then implementation proceeds. No implementation without tests.

**Rationale**: Ensures correctness, prevents regressions, enables confident refactoring, and serves as executable documentation.

**Requirements**:
- Tests written before implementation code
- Tests MUST fail before implementation (red phase)
- Tests MUST pass after implementation (green phase)
- Use swift-testing framework (NOT XCTest)
- TestUtils target provides shared test helpers
- Unit tests in `Tests/DesignSystemTests/`
- Integration tests in `Tests/IntegrationTests/`

**Exemptions for Infrastructure-as-Code**:

Infrastructure configuration files (GitHub Actions workflows, Cloudflare Pages configuration, deployment manifests, and CI/CD pipeline definitions) are exempt from strict test-first development but MUST satisfy these alternative quality gates:

1. **Syntax & Schema Validation**: Configuration files MUST pass automated syntax validation before commit (GitHub Actions workflow validator, YAML linters, schema validation tools)

2. **Integration Testing via Actual Execution**: Configuration MUST be validated through real execution in isolated environments:
   - GitHub Actions workflows: PR-based preview runs
   - Cloudflare deployments: Preview deployment validation
   - Infrastructure changes: Test in non-production environment

3. **Business Logic Unit Testing**: Any extractable business logic (shell scripts >10 lines, custom actions, data transformation logic, version parsing) MUST have dedicated unit tests written test-first

4. **Documented Validation**: Task completion criteria MUST explicitly document validation procedures (what was tested, how, expected outcomes)

**Examples of Exempt Configuration**:
- `.github/workflows/*.yml` - GitHub Actions workflow definitions
- `cloudflare.toml` - Cloudflare Pages configuration
- `tailwind.config.cjs` - Tailwind CSS configuration files
- Deployment manifests and CI/CD pipeline YAML

**Examples Requiring TDD**:
- Custom GitHub Actions written in TypeScript/JavaScript
- Shell scripts with conditional logic, loops, or error handling
- Swift code that processes configuration or generates manifests
- Custom deployment scripts with business logic

**Rationale**: Industry-standard practice treats infrastructure configuration as declarative specifications validated through integration testing rather than isolated unit tests. Attempting to unit test platform behavior (GitHub Actions runner, Cloudflare API) creates fragile mocks that provide little value compared to actual execution testing.

### IV. Static Site Architecture

The project MUST generate pure static HTML/CSS/JS output with NO server-side rendering, NO runtime frameworks, and NO client-side routing. Every site is compiled to static files deployable to any CDN or static host.

**Rationale**: Maximum performance, security, reliability, and portability. Static sites have no server vulnerabilities, scale infinitely, and work everywhere.

**Requirements**:
- Output MUST be static files in `Websites/<SiteName>/`
- No Node.js server, no PHP, no runtime dependencies
- No client-side JavaScript frameworks (React, Vue, etc.)
- All dynamic content resolved at build time
- Deploy to GitHub Pages, Cloudflare Pages, or similar
- Generated sites MUST work offline (except external resources)

### V. Slipstream API Preference

All UI implementation MUST use structured Slipstream APIs (e.g., `.fontSize()`, `.display()`, `.padding()`) instead of raw HTML strings or arbitrary CSS classes. RawHTML MUST only be used when no Slipstream API exists, and such usage MUST be documented with justification.

**Rationale**: Type safety, compile-time validation, better refactoring, consistent API surface, and prevents Tailwind class string errors.

**Requirements**:
- Use Slipstream modifiers: `.fontSize()`, `.padding()`, `.margin()`, `.display()`, etc.
- Search Slipstream APIs before using RawHTML
- Document all RawHTML usage with comments explaining why
- Never use raw class strings like `class="text-lg p-4"`
- Prefer structured layout APIs over manual flex/grid classes
- Link stylesheets with relative paths: `./static/style.css` (not `/static/style.css`)

### VI. Swift 6 + SPM Standards

The project MUST use Swift 6.1+ with Swift Package Manager exclusively. All code MUST follow Swift naming conventions, use clear module boundaries, and maintain minimal public APIs.

**Rationale**: Leverages Swift's type safety, compile-time guarantees, and modern concurrency. SPM provides reproducible builds without external build systems.

**Requirements**:
- Swift 6.1+ with `swift-tools-version: 6.1`
- Each site is an executable target in `Sources/<SiteName>/`
- Shared code in `Sources/DesignSystem/`
- Test utilities in `Tests/TestUtils/` (NOT a test target)
- Public APIs require doc comments (`///`)
- File and type names follow Swift naming guidelines
- NO XCTest (use swift-testing)
- Prefix commands with `nocorrect` in zsh (e.g., `nocorrect swift build`)

## Technology Stack Requirements

### Approved Stack

**Language & Build**:
- Swift 6.1+ (macOS 15+)
- Swift Package Manager (SPM)
- No alternate build systems (no Xcode project files, no Make, no npm scripts)

**Frameworks**:
- Slipstream v2 for static site generation
- swift-plugin-tailwindcss (exact version in Package.swift)
- TailwindCSS via plugin (shared preset in `Tailwind/preset.js`)
- swift-testing for all tests

**CI/CD**:
- GitHub Actions with macOS-15 runners
- Swift 6.1 toolchain
- Tailwind compilation matching local commands exactly
- Deploy from clean, passing main branch only

### Prohibited Technologies

- JavaScript frameworks (React, Vue, Angular, Svelte, etc.)
- CSS frameworks beyond TailwindCSS (Bootstrap, Bulma, etc.)
- Build tools beyond SPM (Webpack, Vite, Rollup, etc.)
- Runtime servers (Node.js, Python, PHP, etc.)
- Database systems (this is static site generation)
- Additional Swift packages beyond approved list

## Development Workflow

### File Structure Standards

**Site Targets**: `Sources/<SiteName>/`
- Each site is standalone executable
- Contains Sitemap.swift with `@main` entry point
- Pages as structs with static `page` property

**DesignSystem**: `Sources/DesignSystem/`
- `Components/` - Reusable UI components
- `Icons/` - Icon system and SVG components  
- `Layouts/` - Page-level layout containers
- `Models/` - Data models for components
- `Tokens/` - Design tokens and styling constants
- `Utilities/` - Shared utility code

**Tests**:
- `Tests/DesignSystemTests/` - Unit tests
- `Tests/IntegrationTests/` - Site-level tests
- `Tests/TestUtils/` - Shared test helpers (NOT a test target)

**Build Output**: `Websites/<SiteName>/`
- Git-ignored, never committed
- Generated HTML/CSS/JS output
- Ready for deployment to static host

### Tailwind Configuration

- Shared preset: `Tailwind/preset.js`
- Per-site config: `Resources/<SiteName>/tailwind.config.cjs`
- Entry CSS: `Resources/<SiteName>/static/style.input.css`
- NO plugins beyond official Tailwind
- Content globs MUST include only HTML output (not Swift source)
- Compilation command MUST match between local and CI exactly

### Quality Gates

**Before PR**:
- All tests pass (`nocorrect swift test`)
- Site generates successfully (`/32-site-generate-and-verify` workflow)
- Tailwind compiles without errors (`/20-tailwind-compile` workflow)
- No build warnings
- Clean build from scratch succeeds

**Before Merge**:
- CI build passes on macOS-15
- All tests pass in CI
- No unresolved TODO comments in implementation code
- Documentation updated if public APIs changed

## Governance

This constitution supersedes all other development practices and preferences. Any deviation from these principles MUST be explicitly justified in a Complexity Tracking section of the implementation plan and approved before proceeding.

**Amendment Process**:
1. Propose changes with clear rationale and impact analysis
2. Update constitution with semantic versioning:
   - MAJOR: Backward incompatible governance changes or principle removals
   - MINOR: New principle or materially expanded guidance
   - PATCH: Clarifications, wording fixes, non-semantic refinements
3. Update all dependent templates in `.specify/templates/`
4. Document changes in Sync Impact Report
5. Commit with descriptive message

**Compliance**:
- All PRs MUST verify alignment with constitution principles
- Constitution Check section in plan.md MUST gate feature work
- Complexity/violations MUST be justified in Complexity Tracking table
- Windsurf rules in `.windsurf/rules/*.md` enforce these principles during development

**Version**: 1.2.0 | **Ratified**: 2025-10-15 | **Last Amended**: 2025-10-16