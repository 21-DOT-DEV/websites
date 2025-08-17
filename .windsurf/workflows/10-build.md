---
description: Build all Swift packages for the selected site.
auto_execution_mode: 3
---

# Build

1. Run Swift build command:
   ```bash
   nocorrect swift build
   ```

2. **Error handling**:
   - If build fails with dependency issues, run `swift package resolve`
   - If Swift version errors occur, verify Swift 6.1+ is installed: `swift --version`
   - Check Package.swift for syntax errors if compilation fails

3. **Verify build output**:
   - Confirm executable targets are built in `.build/debug/`
   - For 21-dev site: verify `.build/debug/21-dev` exists
   - No compilation warnings should remain unaddressed

4. **Common build issues**:
   - Missing import statements in source files
   - Circular dependencies between targets
   - Outdated Package.resolved requiring `swift package update`