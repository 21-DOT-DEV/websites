---
trigger: glob
globs: .github/**/*.yml
description: >
  Apply when working on CI/CD workflows, GitHub Actions, deployment configurations, or Cloudflare Pages setup for Slipstream sites
---
# CI/CD Standards for Slipstream Sites

## Required Workflow Structure
- **Shared workflow**: `.github/workflows/cloudflare-deployment.yml` (exact name required)
- **Site workflows**: `.github/workflows/<SiteName>.yml` (one per site, no other naming allowed)
- **Build platform**: macOS-15 + Swift 6.1 (requires DEVELOPER_DIR override)
- **Deployment target**: Cloudflare Pages

## Critical Runtime Requirements
### Swift 6.1 Compatibility on macOS-15
```yaml
jobs:
  build:
    runs-on: macos-15
    env:
      DEVELOPER_DIR: "/Applications/Xcode_16.4.app/Contents/Developer"
```
**IMPORTANT**: macOS-15 runners default to Swift 6.0.0. Must set `DEVELOPER_DIR` to Xcode 16.4 for Swift 6.1 compatibility.

### Site Generation URL Construction
**CRITICAL**: Use `URL(fileURLWithPath: #filePath)` not `URL(string: #filePath)` in main.swift:
```swift
// ✅ CORRECT - Creates proper file URL with scheme
let projectURL = URL(fileURLWithPath: #filePath)
  .deletingLastPathComponent()
  .deletingLastPathComponent()

// ❌ WRONG - Missing file:// scheme causes runtime failure
guard let projectURL = URL(string: #filePath)? // FAILS IN CI
```

## Workflow Trigger Configuration
```yaml
on:
  pull_request:
    types: [opened, synchronize, reopened, closed]
    branches: ["main"]
    paths:
      - ".github/workflows/cloudflare-deployment.yml"
      - ".github/workflows/<SiteName>.yml"
      - "Sources/<SiteName>/**"
      - "Resources/<SiteName>/**"
      - "Sources/DesignSystem/**"
      - "Tests/**"
      - "Package.swift"
  workflow_dispatch:
```

## Required Job Structure
### Build Job (in shared workflow)
```yaml
build:
  runs-on: macos-15
  env:
    DEVELOPER_DIR: "/Applications/Xcode_16.4.app/Contents/Developer"
  steps:
    - uses: actions/checkout@v3
    - name: Cache Swift Package Manager
      uses: actions/cache@v3
      with:
        path: |
          .build
          ~/.cache/org.swift.swiftpm
        key: ${{ runner.os }}-spm-${{ hashFiles('Package.swift', 'Package.resolved') }}
    - name: Build Dependencies
      run: swift build --configuration release
    - name: Run Tests
      run: swift test --parallel
    - name: Generate Site
      run: swift run ${{ inputs.website }}
    - name: Compile Tailwind CSS
      run: |
        swift package --disable-sandbox tailwindcss \
          --input Resources/${{ inputs.website }}/static/style.css \
          --output Websites/${{ inputs.website }}/static/style.output.css \
          --config Resources/${{ inputs.website }}/tailwind.config.cjs
```

### Site Workflow (simplified)
```yaml
jobs:
  trigger:
    uses: ./.github/workflows/cloudflare-deployment.yml
    with:
      website: <SiteName>  # Single parameter when names align
      deploy-to-production: ${{ github.event.pull_request.merged }}
    secrets:
      cloudflare-api-token: ${{ secrets.CLOUDFLARE_API_TOKEN }}
      cloudflare-account-id: ${{ secrets.CLOUDFLARE_ACCOUNT_ID }}
```

## Critical Tailwind CSS Configuration
**MUST MATCH LOCAL WORKING COMMAND**: CI Tailwind build must use identical flags as local development:
```bash
# ✅ CORRECT - Matches local command exactly
swift package --disable-sandbox tailwindcss \
  --input Resources/${{ inputs.website }}/static/style.css \
  --output Websites/${{ inputs.website }}/static/style.output.css \
  --config Resources/${{ inputs.website }}/tailwind.config.cjs

# ❌ WRONG - Missing --config causes style failures
swift package --disable-sandbox tailwindcss build \
  -i Resources/${{ inputs.website }}/static/style.css \
  -o Websites/${{ inputs.website }}/static/style.output.css
```

## TestUtils Architecture Compliance
**CRITICAL**: TestUtils target must NOT use `@testable import` since it's a regular target, not test target:
```swift
// ✅ CORRECT - Regular imports only
import Foundation
import Slipstream
import Testing

// ❌ WRONG - Causes CI failure: "module not compiled for testing"
@testable import DesignSystem  // Remove from TestUtils.swift
```

## Deployment Rules
- **Production deploys**: Only on merged PRs to main (`github.event.pull_request.merged == true`)
- **Preview deploys**: Every open PR gets preview deployment
- **Manual production deploys**: Not permitted via UI
- **Output directory**: `Websites/<SiteName>/` (must be git-ignored)
- **Branch logic**: Default `preview`, switches to `main` when `deploy-to-production: true`

## PR Comment Error Handling
**ROBUST COMMENT LOGIC**: Always include fallback for missing previous comments:
```bash
# Try to edit last comment, fallback to creating new comment if none exists
if ! gh issue comment ${{ github.event.pull_request.number }} --edit-last --body "${{ env.DEPLOYMENT_TEXT }}" 2>/dev/null; then
  echo "No previous comment found, creating new comment..."
  gh issue comment ${{ github.event.pull_request.number }} --body "${{ env.DEPLOYMENT_TEXT }}"
fi
```

## Required Action Versions
- **Pin to current versions**: Use `actions/upload-artifact@v4` and `actions/download-artifact@v4` (not v3)
- **CloudFlare Pages**: Use `cloudflare/pages-action@v1` with `wranglerVersion: '3'`
- **Checkout**: Use `actions/checkout@v3`

## Workflow Parameter Optimization
**SINGLE PARAMETER PRINCIPLE**: When Swift target name matches CloudFlare project name, eliminate redundant parameters:
```yaml
# ✅ PREFERRED - Single parameter
with:
  website: 21-dev  # Used for both Swift target and CloudFlare project

# ❌ AVOID - Redundant parameters
with:
  website: 21-dev
  swift-target: 21-dev  # Unnecessary duplication
```

## Shared Workflow Requirements
The `cloudflare-deployment.yml` must:
- Accept `website` (string) and `deploy-to-production` (boolean) inputs only
- Use `website` parameter for both Swift target (`swift run ${{ inputs.website }}`) and CloudFlare project
- Include both build and deploy jobs in single reusable workflow
- Handle PR comment creation/editing with error fallback
- Publish `Websites/${{ inputs.website }}` to Cloudflare Pages project `${{ inputs.website }}`
