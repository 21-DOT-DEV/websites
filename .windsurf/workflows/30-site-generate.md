---
description: >
  Generate site HTML and assets for the selected site.
---

# Site Generate

1. **Generate site for 21-dev**:
   ```bash
   nocorrect swift run 21-dev
   ```

2. **For other sites** (when added):
   ```bash
   nocorrect swift run <SiteName>
   ```

3. **Verify output structure**:
   - Check `Websites/<SiteName>/` directory exists
   - Confirm `index.html` is generated
   - Verify all page routes from Sitemap.swift are created
   - Ensure static assets are copied correctly

4. **Error handling**:
   - If "No such executable" error: run `/10-build` first
   - If Slipstream rendering fails: check component syntax and imports
   - If missing pages: verify Sitemap.swift routing configuration
   - If CSS missing: run `/20-tailwind-compile` after generation

5. **Output validation**:
   - HTML files should be valid and complete
   - All stylesheet references should point to `static/style.output.css`
   - No broken internal links between pages
