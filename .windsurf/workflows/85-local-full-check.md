---
description: Full local check before PR: build, test, compile CSS, generate and verify site.
auto_execution_mode: 1
---

# Local Full Check
1. Run `/47-build-test-chain` (replaces separate /10-build and /11-test).
2. Run `/20-tailwind-compile`.
3. Run `/32-site-generate-and-verify`.
4. Run `/46-rawhtml-audit` to verify component rendering.
