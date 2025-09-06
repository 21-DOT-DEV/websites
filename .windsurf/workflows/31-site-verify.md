---
description: >
  Verify generated site output for structure and assets.
---

# Site Verify

## 1. Structure Validation
- Check for presence of `index.html` and all expected pages
- Verify `Websites/<SiteName>/` directory structure matches Sitemap.swift routes
- Ensure all subdirectories (e.g., `/p256k/`, `/blog/`) are created

## 2. Asset Validation  
- Validate CSS references point to `./static/style.output.css` (relative path)
- Check JS references if applicable
- Verify static assets are copied correctly
- Confirm no broken internal links between pages

## 3. HTML Quality
- Basic HTML validation (well-formed tags)
- All images have `alt` attributes (accessibility)
- Meta tags are present (`charset`, `viewport`, `title`)

## 4. Common Issues
- Missing CSS due to Tailwind compilation failure → run `/20-tailwind-compile`
- Broken stylesheet paths → check for absolute vs relative path issues
- Missing pages → verify Sitemap.swift configuration
