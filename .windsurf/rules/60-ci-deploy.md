---
trigger: always_on
description: >
  CI and deployment standards for all Swift-based static sites in this repository.
---

# CI & Deployment

## CI Requirements
- Use macOS-15 runners with Swift 6.1 toolchain.
- Run `build-and-test` workflow on all PRs.
- Ensure Tailwind compilation matches local commands.

## Deployment
- `Websites/<SiteName>/` contents are build output and git-ignored.
- Deploy via GitHub Pages or Cloudflare Pages.
- Only deploy from a clean, passing main branch build.
