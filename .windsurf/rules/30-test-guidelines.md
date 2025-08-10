---
trigger: glob
description: >
globs: Tests/**/*.swift
---

# Testing Guidelines

## Framework & Test Writing Procedures

### Core Testing Principles
- **ALWAYS use**: Swift's built-in `swift-testing` framework
- **IMPORT**: TestUtils in all test files for consistency
- **RENDER**: HTML using `TestUtils.renderHTML(view)` (wraps official Slipstream API)
- **PREFER**: TestUtils assertions over manual `#expect(html.contains())` patterns

### Test Structure Pattern
```swift
import Testing
import TestUtils
@testable import DesignSystem

struct ComponentNameTests {
    
    @Test("Component behavior description")
    func testSpecificBehavior() throws {
        // Arrange
        let component = ComponentName(param: "value")
        
        // Act  
        let html = try TestUtils.renderHTML(component)
        
        // Assert using TestUtils
        TestUtils.assertValidHTMLDocument(html)
        TestUtils.assertContainsText(html, texts: ["expected"])
    }
}
```

## Testing Workflows & Processes

### Component Development Testing Cycle
1. **UNIT TEST FIRST**: Create test in `Tests/DesignSystemTests/Components/`
2. **USE TESTUTILS**: Apply systematic TestUtils patterns from start
3. **TEST INCREMENTALLY**: Start with basic rendering, add complexity
4. **INTEGRATION TEST**: Verify component works in site context via `Tests/IntegrationTests/`

### Systematic Consistency Process

#### Code Review Checklist
- [ ] All tests import and use TestUtils appropriately
- [ ] No manual `#expect(html.contains("<html"))` patterns
- [ ] HTML structure validation uses `TestUtils.assertValidHTMLDocument()`
- [ ] Batch operations use `TestUtils.assertContainsTailwindClasses()` / `assertContainsText()`
- [ ] File system tests use `TestUtils.createTempDirectory()` / `cleanupDirectory()`

#### Finding Inconsistencies
```bash
# Search for manual patterns that should use TestUtils
grep -r "#expect(html.contains(\"<html\"" Tests/          # → assertValidHTMLDocument()
grep -r "#expect(html.contains(\"h-screen\"" Tests/      # → assertContainsTailwindClasses()
grep -r "#expect(html.contains(\"static/style\"" Tests/  # → assertContainsStylesheet()
```

#### Systematic Replacement Strategy
```swift
// ❌ Manual patterns to replace
#expect(html.contains("<html"))
#expect(html.contains("h-screen"))
#expect(html.contains("flex"))

// ✅ TestUtils patterns  
TestUtils.assertValidHTMLDocument(html)
TestUtils.assertContainsTailwindClasses(html, classes: ["h-screen", "flex"])
```

## Test Organization & Naming

### Directory Structure & Naming
```
Tests/
├── TestUtils/                    # Implementation details in 00-project-basics.md
├── DesignSystemTests/           
│   ├── Components/
│   │   └── PlaceholderViewTests.swift    # Component + "Tests" suffix
│   └── Layouts/
│       └── BasePageTests.swift          # Layout + "Tests" suffix  
└── IntegrationTests/
    └── Site21DEVTests.swift             # "Site" + SiteName + "Tests"
```

### Test Function Naming
```swift
@Test("Component handles specific scenario")  
func testComponentSpecificScenario() throws {
    // Descriptive test names that explain expected behavior
}

// ❌ Avoid vague names
@Test("Component works") 
func testComponent() { }
```

## Test Categories & Patterns

### Component Unit Testing Pattern
```swift
struct PlaceholderViewTests {
    
    @Test("PlaceholderView renders with correct structure")
    func testPlaceholderViewStructure() throws {
        let view = PlaceholderView(text: "Welcome")
        let html = try TestUtils.renderHTML(view)
        
        // Use TestUtils for consistent validation
        TestUtils.assertContainsTailwindClasses(html, classes: TestUtils.placeholderViewClasses)
        TestUtils.assertContainsText(html, texts: ["Welcome"])
    }
}
```

### Layout Component Testing Pattern  
```swift
struct BasePageTests {
    
    @Test("BasePage generates complete HTML document")
    func testBasePageHTMLDocument() throws {
        let page = BasePage(title: "Test Page") {
            Text("Content")
        }
        let html = try TestUtils.renderHTML(page)
        
        // TestUtils handles complex validation
        TestUtils.assertValidHTMLDocument(html)
        TestUtils.assertValidTitle(html, expectedTitle: "Test Page")
        TestUtils.assertContainsStylesheet(html)
    }
}
```

### Site Integration Testing Pattern
```swift
struct Site21DevTests {
    
    @Test("21-dev generates complete site")
    func testSiteGeneration() throws {
        let tempURL = TestUtils.createTempDirectory(suffix: "-site")
        
        try renderSitemap(sitemap, to: tempURL)
        
        let indexPath = tempURL.appendingPathComponent("index.html")
        let html = try String(contentsOf: indexPath, encoding: .utf8)
        
        TestUtils.assertValidHTMLDocument(html)
        TestUtils.cleanupDirectory(tempURL)
    }
}
```

## CI & Automation Workflows

### PR Testing Strategy
```yaml
# .github/workflows/test.yml
- name: Unit Tests (Fast Feedback)
  run: swift test --filter DesignSystemTests --parallel

- name: Integration Tests (Complete Validation)  
  run: swift test --filter IntegrationTests
```

### Test Execution Commands
```bash
# Development workflow commands
swift test                                    # All tests
swift test --filter DesignSystemTests        # Unit tests only
swift test --filter IntegrationTests         # Integration tests only
swift test --filter Site21DEVTests           # Specific site tests
```

### Parallel Execution Guidelines
- **UNIT TESTS**: Safe to run in parallel (no file system operations)
- **INTEGRATION TESTS**: Use TestUtils temp directories for isolation
- **CI OPTIMIZATION**: Run unit and integration tests in parallel workflows

## Test Quality & Performance Standards

### Test Performance Guidelines
- **UNIT TESTS**: Keep under 100ms each
- **INTEGRATION TESTS**: Allow up to 5 seconds for file system operations
- **USE**: TestUtils efficient utilities to minimize overhead
- **BATCH**: Multiple related assertions using TestUtils batch operations

### Test Isolation & Reliability  
- **NO SHARED STATE**: Each test must be completely independent
- **USE TESTUTILS**: For safe temporary file operations and cleanup
- **DETERMINISTIC**: Avoid timestamps, random IDs in test content
- **CLEANUP**: Always use TestUtils.cleanupDirectory() in integration tests

## Debugging Test Issues

### Systematic Debugging Process
1. **ISOLATE**: Run failing test individually vs in parallel
2. **SIMPLIFY**: Start with basic HTML rendering using TestUtils.renderHTML()
3. **INCREMENTAL**: Add complexity one component at a time  
4. **CHECK IMPORTS**: Verify TestUtils import and usage patterns

### Common Test Failure Patterns
| Failure Type | Likely Cause | Solution |
|--------------|--------------|----------|
| Empty HTML output | Complex generic constraints | Use `any View` patterns (see 10-swift-architecture.md) |
| TestUtils not found | Missing TestUtils import | Add `import TestUtils` |  
| File system failures | Missing cleanup | Use TestUtils.createTempDirectory() and cleanupDirectory() |
| CI inconsistencies | Parallel test conflicts | Check test isolation with TestUtils patterns |

### TestUtils Migration Strategy
1. **IDENTIFY**: Search for manual assertion patterns using grep commands above
2. **PRIORITIZE**: High-impact patterns (HTML structure, stylesheets, batch operations) first
3. **REPLACE**: One test file at a time, verify all tests pass after each change
4. **REVIEW**: Use systematic code review checklist for consistency

## Snapshot Testing Guidelines

### Snapshot Policy & Management
- **COMMIT**: Snapshots in `__snapshots__/` directories next to test files
- **NORMALIZE**: Use `TestUtils.normalizeHTML()` for consistent comparisons
- **DETERMINISTIC**: Avoid dynamic content in snapshots
- **HUMAN-READABLE**: Keep snapshots reviewable in PRs

### Snapshot Testing Pattern
```swift
@Test("Component generates expected snapshot")
func testComponentSnapshot() throws {
    let view = ComponentName(text: "Snapshot Content")
    let html = try TestUtils.renderHTML(view)
    
    let expectedSnapshot = """
    <div class="expected-classes">Snapshot Content</div>
    """
    
    #expect(TestUtils.normalizeHTML(html) == TestUtils.normalizeHTML(expectedSnapshot))
}
```

## Advanced Testing Patterns

### Testing Component Composition
```swift
@Test("Components integrate correctly")
func testComponentIntegration() throws {
    let page = BasePage(title: "Integration") {
        PlaceholderView(text: "Integrated Content")
    }
    let html = try TestUtils.renderHTML(page)
    
    // Test both components work together
    TestUtils.assertValidHTMLDocument(html)
    TestUtils.assertContainsTailwindClasses(html, classes: TestUtils.placeholderViewClasses)
    TestUtils.assertContainsText(html, texts: ["Integrated Content"])
}
```

### Testing Error Conditions
```swift
@Test("Component handles edge cases gracefully")
func testComponentEdgeCases() throws {
    let view = ComponentName(text: "")  // Edge case: empty input
    let html = try TestUtils.renderHTML(view)
    
    // Should still render valid structure
    TestUtils.assertValidHTMLDocument(html) 
}
```

## Integration with Development Workflow

### Test-Driven Component Development
1. **WRITE FAILING TEST**: Define expected behavior using TestUtils patterns
2. **IMPLEMENT COMPONENT**: Make test pass with minimal implementation
3. **REFACTOR**: Improve implementation while keeping tests green
4. **INTEGRATE**: Test component in site context via integration tests

### Continuous Quality Assurance
- **PRE-COMMIT**: Run `swift test` before commits
- **CODE REVIEW**: Apply systematic TestUtils consistency checklist
- **CI ENFORCEMENT**: Block merges on any test failures
- **REGULAR AUDITS**: Search for and eliminate manual assertion patterns

## Performance & Optimization

### Test Suite Optimization
- **PARALLEL UNIT TESTS**: Safe with TestUtils patterns
- **ISOLATED INTEGRATION TESTS**: TestUtils handles temp directory isolation
- **CACHED BUILDS**: CI caching strategies for Swift build artifacts
- **MINIMAL FILE OPERATIONS**: Use TestUtils efficient patterns

### Memory & Resource Management
- **TESTUTILS CLEANUP**: Always cleanup temp directories in integration tests
- **BATCH OPERATIONS**: Use TestUtils batch assertions for efficiency  
- **AVOID LARGE SNAPSHOTS**: Keep snapshot content focused and minimal