---
description: Scaffold a new page for the 21-dev site.
auto_execution_mode: 3
---

# Page Scaffold

1. Create Swift file in `Sources/21-dev/` (e.g., `P256K.swift`, `Bitcoin.swift`).
2. Add page struct with static property:
   ```swift
   struct PageName {
       static var page: some View {
           BasePage(title: "Page Title") {
               // Page content here
           }
       }
   }
   ```
3. Add route to sitemap in `Sources/21-dev/Sitemap.swift`:
   ```swift
   let sitemap: Sitemap = [
       "index.html": Homepage.page,
       "newpage/index.html": PageName.page
   ]
   ```
4. Build and test: `nocorrect swift run 21-dev`