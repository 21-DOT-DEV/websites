---
description: Run all test suites for the repository.
auto_execution_mode: 3
---

# Test

1. Run all tests:
   ```bash
   nocorrect swift test
   ```

2. **Run specific test targets**:
   ```bash
   nocorrect swift test --filter DesignSystemTests
   nocorrect swift test --filter IntegrationTests
   ```

3. **Error handling**:
   - If tests fail due to missing TestUtils imports, verify TestUtils target builds correctly
   - For HTML rendering test failures, check if components use proper Slipstream APIs
   - If snapshot tests fail, run `/70-update-snapshots` workflow

4. **Verify test results**:
   - All test cases should pass
   - No test compilation warnings
   - Test coverage should include new components and models

5. **Common test issues**:
   - `@testable import` usage violations (should use public APIs)
   - Missing test cases for new DesignSystem components
   - TestUtils assertion failures due to HTML structure changes