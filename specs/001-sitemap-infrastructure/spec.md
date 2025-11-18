# Feature Specification: Sitemap Infrastructure Overhaul

**Feature Branch**: `001-sitemap-infrastructure`  
**Created**: 2025-11-14  
**Status**: Draft  
**Input**: User description: "Ensure all content across 21.dev, docs.21.dev, and md.21.dev is discoverable by search engines and properly indexed, with automated submission eliminating manual maintenance burden."

## Clarifications

### Session 2025-11-14

- Q: How should robots.txt reference sitemaps across subdomains? → A: Each subdomain has its own robots.txt pointing to its own sitemap.xml (standard per-subdomain approach)
- Q: Who/what updates the sitemap state file and when? → A: Option A - Lefthook plugin auto-updates state file locally before git operations (runs on checkout/merge, detects Package.resolved changes, updates state file automatically, developer commits both files together)
- Q: How should Lefthook be installed for developers? → A: Option B - SPM plugin handles installation (lefthook-plugin package includes installation logic to download/install Lefthook binary automatically if missing)
- Q: What logging/error reporting format should API submissions use? → A: Option C - Hybrid approach with GitHub Actions annotations for failures (`::warning::`) and structured logs for successes (key=value format with metrics)
- Q: What should workflows do if state file version doesn't match Package.resolved? → A: Option A - Fail the build with clear error message indicating state file is stale and needs lefthook-plugin to run (forces manual state file update before deployment)

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Search Engine Discovery Across All Subdomains (Priority: P1)

Search engines need to discover and index all published content across the three subdomains (21.dev, docs.21.dev, md.21.dev) to drive organic traffic and improve discoverability.

**Why this priority**: Core blocker preventing proper indexing. Without valid sitemaps, search engines rely on crawling alone, leading to incomplete coverage and poor rankings. This is the foundation for all SEO efforts.

**Independent Test**: Can be fully tested by validating that all three subdomains generate valid sitemap.xml files containing 100% of their URLs. Deliverable value: search engines can discover all content.

**Acceptance Scenarios**:

1. **Given** 21.dev has been deployed, **When** accessing `https://21.dev/sitemap.xml`, **Then** receive a valid sitemap XML containing all 21.dev URLs (homepage, packages, blog posts)
3. **Given** docs.21.dev documentation has been generated, **When** accessing `https://docs.21.dev/sitemap.xml`, **Then** receive a valid sitemap XML containing all documentation page URLs under `/documentation/`
4. **Given** md.21.dev markdown files have been generated, **When** accessing `https://md.21.dev/sitemap.xml`, **Then** receive a valid sitemap XML containing all markdown file URLs
5. **Given** any sitemap has been generated, **When** validating against XML schema, **Then** conform to sitemap protocol 0.9 specification
6. **Given** a deployment includes new or removed pages, **When** sitemaps are regenerated, **Then** reflect current URL inventory with 100% accuracy

---

### User Story 2 - SEO-Optimized Modification Dates (Priority: P2)

Search engines use `lastmod` dates to determine crawl priority and detect content freshness. Accurate modification dates improve crawl efficiency and ranking signals, while incorrect dates (e.g., all pages showing "today") waste crawl budget.

**Why this priority**: Enhances SEO effectiveness but not a complete blocker. Without accurate dates, search engines still index content but less efficiently. Provides significant value for mature sites with stable content.

**Independent Test**: Can be tested by comparing sitemap lastmod values against actual content change history. For 21.dev, verify git commit dates match lastmod; for docs/md, verify lastmod only changes when swift-secp256k1 package version changes. Deliverable value: optimized search engine crawl patterns.

**Acceptance Scenarios**:

1. **Given** a 21.dev page's source file has not been modified since previous deployment, **When** sitemap is regenerated, **Then** lastmod date remains unchanged from previous sitemap
2. **Given** a 21.dev page's source file was modified via git commit, **When** sitemap is generated, **Then** lastmod date reflects the git commit timestamp of the most recent change
3. **Given** docs.21.dev was generated from swift-secp256k1 version 1.2.3, **When** docs are regenerated with same package version, **Then** all documentation page lastmod dates remain unchanged
4. **Given** docs.21.dev is generated from a new swift-secp256k1 version, **When** docs are regenerated, **Then** all documentation page lastmod dates update to current generation timestamp
5. **Given** md.21.dev was generated from swift-secp256k1 version 1.2.3, **When** markdown is regenerated with same package version, **Then** all markdown file lastmod dates remain unchanged
6. **Given** a deployment includes both changed and unchanged pages, **When** sitemap is generated, **Then** only changed pages show updated lastmod dates

---

### User Story 3 - Automated Search Engine Notification (Priority: P3)

Manual sitemap submission to Google Search Console and Bing Webmaster Tools is time-consuming, error-prone, and often forgotten during deployments. Automation ensures immediate notification, reducing time-to-index.

**Why this priority**: Quality-of-life improvement that accelerates indexing but isn't blocking. Sites can still be discovered through sitemaps alone or via crawling. Primary benefit is speed and operational efficiency.

**Independent Test**: Can be tested by monitoring API calls to Google and Bing submission endpoints after deployment, and verifying successful HTTP 200 responses within 5 minutes of deployment completion. Deliverable value: zero manual submission overhead.

**Acceptance Scenarios**:

1. **Given** 21.dev sitemap has been deployed, **When** deployment completes successfully, **Then** system submits sitemap URL to Google Search Console API within 5 minutes
2. **Given** 21.dev sitemap has been deployed, **When** deployment completes successfully, **Then** system submits sitemap URL to Bing Webmaster Tools API within 5 minutes
3. **Given** docs.21.dev sitemap has been deployed, **When** deployment completes successfully, **Then** system submits sitemap URL to both Google and Bing APIs within 5 minutes
4. **Given** md.21.dev sitemap has been deployed, **When** deployment completes successfully, **Then** system submits sitemap URL to both Google and Bing APIs within 5 minutes
5. **Given** API submission fails for any reason, **When** failure is detected, **Then** system logs detailed error information and alerts via GitHub Actions workflow notification
6. **Given** API credentials are missing or invalid, **When** submission is attempted, **Then** system fails gracefully with clear error message indicating credential issue

---

### Edge Cases

- What happens when swift-secp256k1 package version changes but documentation content is identical? (Answer: lastmod should still update to signal potential metadata/infrastructure changes)
- How does system handle removed pages that exist in previous sitemap state but not in current deployment? (Answer: remove from sitemap, exclude from submission)
- What if git history is unavailable for a 21.dev page (e.g., new file not yet committed)? (Answer: use current deployment timestamp as fallback)
- How does system handle sitemap size limits (50,000 URLs per sitemap, 50MB uncompressed)? (Answer: current URL counts are well below limits; monitor and implement pagination if needed in future)
- What if Google/Bing APIs are temporarily unavailable during deployment? (Answer: log warning but don't fail deployment; retry mechanism optional for future enhancement)
- How are sitemap URLs formatted for Cloudflare Pages preview deployments vs. production? (Answer: only production deployments generate and submit sitemaps; preview deployments skip sitemap generation)
- What if state file version doesn't match Package.resolved during CI build? (Answer: fail the build with clear error message indicating lefthook-plugin needs to update state file; forces developer to commit updated state file before redeploying)

## Requirements *(mandatory)*

### Functional Requirements

#### Sitemap Generation

- **FR-001**: System MUST generate individual subdomain sitemaps during their respective deployment workflows: docs.21.dev (generate-docc), md.21.dev (generate-markdown), 21.dev (build-slipstream)
- **FR-002**: System MUST generate a sitemap XML file at `https://21.dev/sitemap.xml` containing all 21.dev URLs during the build-slipstream workflow
- **FR-003**: System MUST generate a sitemap XML file at `https://docs.21.dev/sitemap.xml` containing all DocC documentation URLs during the generate-docc workflow
- **FR-004**: System MUST generate a sitemap XML file at `https://md.21.dev/sitemap.xml` containing all markdown documentation URLs during the generate-markdown workflow
- **FR-005**: All generated sitemaps MUST conform to sitemap protocol 0.9 specification
- **FR-006**: All sitemap URLs MUST use absolute URLs with correct protocol and subdomain (e.g., `https://21.dev/`, not relative paths)

#### URL Discovery

- **FR-012**: 21.dev sitemap MUST discover URLs from Slipstream's existing `Sitemap` dictionary tracking mechanism in `SiteGenerator.swift`
- **FR-013**: docs.21.dev sitemap MUST discover URLs by scanning the `Websites/docs-21-dev/documentation/` directory for HTML files after DocC generation
- **FR-014**: md.21.dev sitemap MUST discover URLs by scanning the `Websites/md-21-dev/` directory for markdown files after export
- **FR-015**: URL discovery MUST achieve 100% coverage of all publicly accessible pages (no missing URLs)
- **FR-016**: URL discovery MUST exclude non-page assets (CSS, JavaScript, images, fonts) from sitemaps

#### Modification Date Preservation

- **FR-017**: 21.dev sitemap MUST calculate lastmod dates from git commit history for each page's source file using `git log -1 --format=%cI -- path/to/file`
- **FR-018**: docs.21.dev sitemap MUST track lastmod based on swift-secp256k1 package version from `Package.resolved`
- **FR-019**: md.21.dev sitemap MUST track lastmod based on swift-secp256k1 package version from `Package.resolved`
- **FR-020**: System MUST persist package version and generation timestamp in git-tracked state file at `Resources/sitemap-state.json` (shared by docs.21.dev and md.21.dev subdomains)
- **FR-021**: State file MUST use format: `{ "package_version": "X.Y.Z", "generated_date": "ISO8601_timestamp" }`
- **FR-022**: When package version is unchanged, system MUST preserve existing lastmod date from state file
- **FR-023**: When package version changes, lefthook-plugin MUST automatically update state file during git checkout/merge operations, and workflows MUST update all documentation page lastmod dates to current generation timestamp using the state file's generated_date
- **FR-023.1**: If CI workflows detect state file package version does not match Package.resolved swift-secp256k1 version, workflow MUST fail with error message indicating state file is stale and lefthook-plugin needs to run locally
- **FR-024**: For 21.dev pages without git history (uncommitted new files), system MUST use current deployment timestamp as fallback lastmod

#### robots.txt Configuration

- **FR-025**: Each subdomain MUST have its own robots.txt file with appropriate sitemap reference
- **FR-026**: 21.dev robots.txt MUST include `Sitemap: https://21.dev/sitemap.xml`
- **FR-027**: docs.21.dev robots.txt MUST include `Sitemap: https://docs.21.dev/sitemap.xml`
- **FR-028**: md.21.dev robots.txt MUST include `Sitemap: https://md.21.dev/sitemap.xml`
- **FR-029**: robots.txt files MUST be generated/updated during their respective subdomain build workflows

#### Search Engine Submission

- **FR-030**: 21.dev deployment workflow MUST submit sitemap URL to Google Search Console API within 5 minutes after successful deployment
- **FR-031**: 21.dev deployment workflow MUST submit sitemap URL to Bing Webmaster Tools API within 5 minutes after successful deployment
- **FR-032**: docs.21.dev deployment workflow MUST submit sitemap URL to Google Search Console API within 5 minutes after successful deployment
- **FR-033**: docs.21.dev deployment workflow MUST submit sitemap URL to Bing Webmaster Tools API within 5 minutes after successful deployment
- **FR-034**: md.21.dev deployment workflow MUST submit sitemap URL to Google Search Console API within 5 minutes after successful deployment
- **FR-035**: md.21.dev deployment workflow MUST submit sitemap URL to Bing Webmaster Tools API within 5 minutes after successful deployment
- **FR-036**: API submissions MUST use credentials stored as GitHub Actions secrets (GOOGLE_SEARCH_CONSOLE_API_KEY, BING_WEBMASTER_API_KEY)
- **FR-037**: System MUST log successful API submissions using structured format with key=value pairs including: sitemap URL, API name (google/bing), HTTP status code, duration in milliseconds, and ISO 8601 timestamp
- **FR-038**: System MUST log failed API submissions as GitHub Actions workflow annotations using `::warning::` format with details including: sitemap URL, API name, HTTP status code, error message; deployment MUST continue and succeed despite submission failures
- **FR-039**: Subdomain sitemap generation and submission MUST only occur for production deployments, not preview deployments

### Key Entities

- **Subdomain Sitemap**: Individual XML file for each subdomain at `/sitemap.xml` containing that subdomain's URLs, lastmod dates, and optional metadata, generated during deployment workflows
- **Sitemap State File**: JSON file persisting package version and generation timestamp for docs/md subdomains, enabling lastmod preservation across builds (format: `{ "package_version": "X.Y.Z", "generated_date": "ISO8601" }`)
- **URL Entry**: Individual page reference within a sitemap, containing `<loc>` (absolute URL) and `<lastmod>` (ISO 8601 date)

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: All three subdomains (21.dev, docs.21.dev, md.21.dev) generate valid XML sitemaps conforming to protocol 0.9, verifiable via sitemap validator tools
- **SC-002**: URL discovery achieves 100% coverage verified by comparing sitemap URLs against actual deployed content inventory
- **SC-003**: Google Search Console and Bing Webmaster Tools receive successful sitemap API submissions within 5 minutes of each subdomain deployment, all logged in GitHub Actions workflow output
- **SC-005**: Zero manual sitemap submission actions required post-implementation, verified by removing manual submission from deployment checklist
- **SC-006**: Coverage report in Google Search Console shows 95%+ of submitted URLs indexed within 7 days of first submission
- **SC-007**: Unchanged pages preserve their original lastmod dates across redeployments, verifiable by comparing sitemap versions before/after no-op deployments
- **SC-008**: Documentation pages (docs.21.dev, md.21.dev) only update lastmod when swift-secp256k1 package version changes in Package.resolved

## Assumptions

- Cloudflare Pages projects for all three subdomains are already configured and deployed separately
- lefthook-plugin SPM package automatically installs Lefthook binary if missing (no manual installation required)
- Google Search Console and Bing Webmaster Tools accounts are already registered and verified for all three subdomains
- API credentials for search engine submission can be obtained and stored securely as GitHub Actions secrets
- Current URL counts across all subdomains are well below sitemap protocol limits (50,000 URLs per file, 50MB uncompressed)
- Production deployments can be distinguished from preview deployments via environment variables or GitHub Actions context
