---
description: >
  Troubleshoot common issues in build, test, or deployment.
  Specific solutions for frequent DesignSystem and Slipstream problems.
---

# Troubleshooting Common Issues

## Build Issues

### Swift Compilation Errors
1. **Missing imports**: Add `import Slipstream` to component files
2. **Circular dependencies**: Check Package.swift target dependencies
3. **Swift version mismatch**: Verify Swift 6.1+ with `swift --version`
4. **Package resolution**: Run `swift package resolve` or `swift package update`

### DesignSystem Import Errors
1. **Cannot find DesignSystem**: Ensure target depends on DesignSystem in Package.swift
2. **TestUtils not found**: Add TestUtils dependency to test targets
3. **Missing public APIs**: Check if types/functions are marked `public`

## Test Issues

### TestUtils Problems
1. **@testable import violations**: Use public APIs instead of @testable import in TestUtils
2. **HTML rendering failures**: Verify component uses proper Slipstream syntax
3. **Missing test assertions**: Use `TestUtils.renderHTML()` and `assertValidHTMLDocument()`

### Component Test Failures
1. **SVG path mismatches**: Update test expectations after icon changes
2. **CSS class changes**: Update HTML assertions when Tailwind classes change
3. **Snapshot test failures**: Run `/70-update-snapshots` workflow

## Tailwind CSS Issues

### Compilation Problems
1. **Missing output file**: Run `/20-tailwind-compile` workflow
2. **Config file errors**: Check `Resources/<SiteName>/tailwind.config.cjs` syntax
3. **Content glob issues**: Ensure content includes `["./Websites/<SiteName>/**/*.html"]`
4. **Plugin errors**: Verify no unauthorized plugins in config

### ClassModifier Workarounds
1. **Grid layout issues**: Use `.modifier(ClassModifier(add: "grid grid-cols-X"))` until native Grid API
2. **Complex responsive**: Use ClassModifier for multi-breakpoint layouts temporarily
3. **Custom CSS**: Limit to `.modifier(ClassModifier(add: "custom-class"))`

## Site Generation Issues

### Slipstream Rendering
1. **Empty HTML output**: Check if `@main` attribute on SiteGenerator
2. **Missing pages**: Verify Sitemap.swift routing configuration
3. **Component not rendering**: Ensure component implements `View` protocol
4. **CSS not loading**: Check stylesheet URL uses `"static/style.output.css"` (relative path)

### Route Configuration
1. **404 pages**: Add routes to Sitemap.swift: `"path/index.html": PageName.page`
2. **Broken links**: Use relative paths in Link components
3. **Missing static files**: Ensure assets copied to `Websites/<SiteName>/static/`

## Performance Issues

### Build Time
1. **Slow compilation**: Use `swift build --jobs 1` to reduce memory usage
2. **Large dependency tree**: Run `swift package show-dependencies` to audit
3. **Frequent rebuilds**: Check for unnecessary file modifications

### Memory Issues
1. **Large HTML generation**: Break large pages into smaller components
2. **Test memory usage**: Limit TestUtils HTML output size in assertions
