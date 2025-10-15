---
description: >
  Audit DesignSystem for RawHTML usage and suggest Slipstream API alternatives.
  Prevents unnecessary RawHTML when proper APIs exist.
---

# RawHTML Audit

## 1. Search for RawHTML Usage
```bash
# Find all RawHTML instances in DesignSystem
grep -r "RawHTML(" Sources/DesignSystem/ --include="*.swift"
```

## 2. Categorize Findings
For each RawHTML usage found:

### A. Check for Existing Slipstream APIs
```bash
# Search for existing HTML element APIs
find /path/to/slipstream/Sources/Slipstream/W3C/Elements/ -name "*.swift" | xargs grep -l "<ElementName>"
```

### B. Evaluate Necessity
- **Replace immediately**: Basic HTML elements (`<br>`, `<span>`, `<input>`, `<label>`)
- **Consider alternatives**: Complex but structured content
- **Keep as-is**: Dynamic HTML generation that can't be componentized

## 3. Replacement Priority
1. **High**: Replace with existing Slipstream APIs (`Linebreak`, `Span`, `Input`, `Label`)
2. **Medium**: Create new Slipstream APIs for common patterns  
3. **Low**: Document complex RawHTML usage with explanatory comments

## 4. Validation
```bash
# After replacements, verify builds work
nocorrect swift build
nocorrect swift test --filter DesignSystemTests
```

## 5. Documentation
- Update component documentation to reference proper Slipstream APIs
- Add comments explaining when RawHTML is appropriate vs inappropriate
