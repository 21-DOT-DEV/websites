# Pre-Implementation Readiness Checklist: md.21.dev

**Purpose**: Validate that requirements are complete, clear, and actionable enough to implement workflows, markdown generation, deployment, and discovery features without rework  
**Created**: 2025-10-16  
**Audience**: Feature implementer (pre-code readiness)  
**Risk Focus**: Workflow execution failures (DocC generation, splitting, artifacts)  
**Scope**: End-to-end integration (workflows + markdown + deployment + discovery)

---

## Workflow Requirements - DocC Generation

### CHK001: Are the exact DocC targets specified with target names from Package.swift?
[Completeness] [Spec §FR-001]
- **Check**: Does spec define P256K and ZKP as specific target names?
- **Risk**: Using wrong target names causes DocC generation to fail with "target not found" error
- **Current**: ✅ PASS - FR-001 explicitly lists "docs-21-dev-P256K" and "docs-21-dev-ZKP"

### CHK002: Is the DocC archive output path fully specified with directory and filename?
[Clarity] [Spec §FR-035]
- **Check**: Does spec define exact path `./Archives/md-21-dev.doccarchive`?
- **Risk**: Ambiguous paths cause export step to fail looking for archive in wrong location
- **Current**: ✅ PASS - FR-035 specifies complete path with directory

### CHK003: Are DocC generation command flags documented (combined-documentation, output-path)?
[Completeness] [Gap]
- **Check**: Does spec or plan document required swift package generate-documentation flags?
- **Risk**: Missing --combined-documentation flag generates separate archives; wrong --output-path breaks export
- **Current**: ⚠️ PARTIAL - FR-002 mentions "combined documentation" but doesn't specify flag name

### CHK004: Is the failure mode specified when DocC targets don't exist in swift-secp256k1?
[Edge Cases] [Spec §Edge Cases]
- **Check**: Does spec define error handling when docs-21-dev-P256K or docs-21-dev-ZKP targets missing?
- **Risk**: Silent failure or confusing error message delays diagnosis
- **Current**: ⚠️ PARTIAL - Edge cases mention DocC4LLM unavailable but not missing DocC targets

---

## Workflow Requirements - Markdown Export

### CHK005: Is the DocC4LLM exact version pinning requirement actionable?
[Clarity] [Spec §FR-039]
- **Check**: Does spec specify exact version string format (`.exact("1.0.0")`)?
- **Risk**: Using `.upToNextMajor` allows format changes that break split logic
- **Current**: ✅ PASS - FR-039 includes example `.exact("1.0.0")` syntax

### CHK006: Is the DocC4LLM export command fully specified with all required arguments?
[Completeness] [Spec §FR-034]
- **Check**: Does spec define complete command: `swift run docc4llm export <path> --output-path <file>`?
- **Risk**: Missing arguments cause export to fail or output to wrong location
- **Current**: ⚠️ PARTIAL - FR-034 mentions `swift run docc4llm export` but doesn't show full command with paths

### CHK007: Is the expected markdown export output format documented (single file vs directory)?
[Clarity] [Spec §FR-036, Assumptions]
- **Check**: Does spec explicitly state DocC4LLM outputs single concatenated file with delimiters?
- **Risk**: Expecting directory structure when tool outputs single file breaks split logic
- **Current**: ✅ PASS - Assumptions clearly state "single concatenated markdown file with delimiter markers"

### CHK008: Is the failure mode specified when DocC4LLM export produces zero-length file?
[Edge Cases] [Gap]
- **Check**: Does spec define error handling for empty export output?
- **Risk**: Split step processes empty file and creates zero symbols without clear error
- **Current**: ❌ MISSING - No edge case for empty export output

---

## Workflow Requirements - File Splitting

### CHK009: Are the exact delimiter marker strings specified (START and END)?
[Clarity] [Spec §FR-036, FR-037]
- **Check**: Does spec define exact marker format: `=== START FILE:` and `=== END FILE ===`?
- **Risk**: Wrong marker strings cause validation to fail or split to miss files
- **Current**: ✅ PASS - FR-037 references delimiter markers; Assumptions show exact format

### CHK010: Is the delimiter validation logic specified (count START == END, both >0)?
[Completeness] [Spec §FR-037]
- **Check**: Does spec define validation rules: START count must equal END count, both must be >0?
- **Risk**: Mismatched delimiters cause incomplete split; missing validation allows corrupt data through
- **Current**: ⚠️ PARTIAL - FR-037 says "validate format" but doesn't specify exact validation rules

### CHK011: Is the awk split logic specified with path transformation rules?
[Completeness] [Spec §FR-036, Assumptions]
- **Check**: Does spec define how to extract file paths and strip prefixes (`data/documentation/`)?
- **Risk**: Wrong path extraction creates files in wrong directories or with wrong names
- **Current**: ⚠️ PARTIAL - Assumptions mention "awk-based splitting preserves directory structure" but no transformation rules

### CHK012: Is the expected file count specified for validation (2,500+ files)?
[Measurability] [Spec §SC-010]
- **Check**: Does spec define minimum file count threshold for successful split?
- **Risk**: Incomplete split produces 100 files instead of 2,500 without detection
- **Current**: ✅ PASS - SC-010 explicitly states "2,500+ files"

### CHK013: Is the failure mode specified when split produces zero files?
[Edge Cases] [Spec §Edge Cases]
- **Check**: Does spec define error handling when awk split command fails completely?
- **Risk**: Empty output directory passes to deployment, deploying broken docs
- **Current**: ✅ PASS - Edge case "awk split command fails or produces incomplete files"

### CHK014: Is the file organization structure fully specified (p256k/, zkp/ directories)?
[Clarity] [Spec §FR-026, FR-027]
- **Check**: Does spec define two-level hierarchy with target subdirectories and symbol files?
- **Risk**: Wrong directory structure breaks LLM navigation and URL patterns
- **Current**: ✅ PASS - FR-026 specifies "target/symbol.md" pattern; FR-027 shows examples

---

## Workflow Requirements - Artifact Management

### CHK015: Is the artifact naming pattern specified with SHA inclusion?
[Clarity] [Gap]
- **Check**: Does spec define artifact name format: `markdown-docs-${{ github.sha }}`?
- **Risk**: Generic names cause artifact collisions in parallel PR builds
- **Current**: ❌ MISSING - No artifact naming pattern specified

### CHK016: Is the artifact upload path specified (Websites/md-21-dev/)?
[Completeness] [Spec §FR-035]
- **Check**: Does spec define what directory gets uploaded as artifact?
- **Risk**: Uploading wrong directory or missing files causes deployment to fail
- **Current**: ✅ PASS - FR-035 specifies `./Websites/md-21-dev/`

### CHK017: Is the artifact retention period specified (1 day)?
[Completeness] [Spec §FR-019]
- **Check**: Does spec define exact retention: `retention-days: 1`?
- **Risk**: Wrong retention wastes storage or causes artifacts to expire before deployment
- **Current**: ✅ PASS - FR-019 explicitly states "1-day retention"

### CHK018: Is the fallback zipping strategy specified with trigger conditions?
[Completeness] [Spec §FR-033]
- **Check**: Does spec define when to zip artifacts (path validation issues)?
- **Risk**: Not zipping when needed causes artifact upload failures
- **Current**: ⚠️ PARTIAL - FR-033 mentions "fallback to zipping" but doesn't specify trigger condition

---

## Workflow Requirements - Size Monitoring

### CHK019: Are the exact size warning thresholds specified (15k files, 20MB)?
[Measurability] [Spec §FR-038]
- **Check**: Does spec define specific thresholds: warn at 15,000 files or 20MB?
- **Risk**: Wrong thresholds trigger false warnings or miss actual limit approach
- **Current**: ✅ PASS - FR-038 specifies exact thresholds with units

### CHK020: Is the monitoring behavior specified (warn but don't fail)?
[Clarity] [Spec §FR-038]
- **Check**: Does spec explicitly state warnings should not fail the workflow?
- **Risk**: Treating warnings as errors blocks valid deployments under limits
- **Current**: ✅ PASS - FR-038 says "log warnings... without failing"

### CHK021: Are the actual Cloudflare Pages limits documented (20k files, 25MB)?
[Completeness] [Spec §FR-038]
- **Check**: Does spec define the absolute limits (not just warning thresholds)?
- **Risk**: Not knowing true limits prevents understanding warning urgency
- **Current**: ✅ PASS - FR-038 mentions limits in parenthetical (20,000 files, 25MB)

---

## Workflow Requirements - CI Triggers

### CHK022: Are the exact path filter globs specified for PR triggers?
[Completeness] [Spec §FR-015]
- **Check**: Does spec list exact paths: Package.swift, Package.resolved, workflow files?
- **Risk**: Wrong filters cause workflows to run unnecessarily or miss required runs
- **Current**: ⚠️ PARTIAL - FR-015 mentions "PR changes to Package.swift/Package.resolved" but no complete path list

### CHK023: Is the branch filter specified (only main branch)?
[Clarity] [Gap]
- **Check**: Does spec define which branches trigger production deployment?
- **Risk**: Deploying from feature branches pollutes production
- **Current**: ❌ MISSING - No branch filter specification

### CHK024: Is the PR merge detection logic specified (merged == true)?
[Completeness] [Gap]
- **Check**: Does spec define how to detect merged vs closed PRs for production deployment?
- **Risk**: Deploying on any PR close (including abandoned PRs) causes wrong deployments
- **Current**: ❌ MISSING - No merge detection logic documented

### CHK025: Are the workflow_dispatch inputs specified for manual triggers?
[Completeness] [Gap]
- **Check**: Does spec define manual trigger inputs (deploy-to-production boolean)?
- **Risk**: No manual deployment capability for hotfixes or testing
- **Current**: ❌ MISSING - No workflow_dispatch configuration specified

---

## Deployment Requirements

### CHK026: Is the Cloudflare Pages project name specified exactly (md-21-dev)?
[Clarity] [Spec §FR-007]
- **Check**: Does spec define exact project name with hyphenation?
- **Risk**: Wrong project name causes deployment to fail or deploy to wrong site
- **Current**: ✅ PASS - FR-007 explicitly names "md-21-dev" project

### CHK027: Is the custom domain configuration specified (md.21.dev)?
[Completeness] [Spec §FR-006, FR-009]
- **Check**: Does spec define custom domain setup requirement?
- **Risk**: Deployment succeeds but site inaccessible at intended URL
- **Current**: ✅ PASS - FR-006 specifies "md.21.dev subdomain"; FR-009 covers custom domain

### CHK028: Is the deploy-to-production flag logic specified?
[Completeness] [Gap]
- **Check**: Does spec define when deploy-to-production is true vs false?
- **Risk**: Always deploying to production or never deploying
- **Current**: ❌ MISSING - No production flag logic documented

### CHK029: Is the preview URL comment format specified?
[Clarity] [Spec §FR-018]
- **Check**: Does spec define what information appears in PR comment (URL, status, logs)?
- **Risk**: Unhelpful comments don't provide needed review information
- **Current**: ⚠️ PARTIAL - FR-018 says "URL posted in PR comments" but no format details

### CHK030: Is the rollback procedure specified (Cloudflare UI)?
[Completeness] [Spec §FR-024]
- **Check**: Does spec document how to roll back bad deployments?
- **Risk**: Production issues with no documented recovery path
- **Current**: ✅ PASS - FR-024 states "rollback available via Cloudflare Pages deployment history UI"

---

## Markdown Output Quality

### CHK031: Is the expected symbol count per module documented (~1,285 each)?
[Measurability] [Gap]
- **Check**: Does spec define expected file counts for P256K and ZKP separately?
- **Risk**: Can't validate if split produced correct number of files per module
- **Current**: ❌ MISSING - SC-010 says 2,500+ total but no per-module breakdown

### CHK032: Are the markdown formatting requirements specified (CommonMark)?
[Clarity] [Spec §SC-008]
- **Check**: Does spec define which markdown spec to follow?
- **Risk**: Ambiguous "valid markdown" allows incompatible dialects
- **Current**: ✅ PASS - SC-008 explicitly references "CommonMark specification"

### CHK033: Is the source link format specified (GitHub URLs with line numbers)?
[Completeness] [Spec §FR-005, SC-003]
- **Check**: Does spec define link pattern: https://github.com/org/repo/blob/version/file.swift#L123?
- **Risk**: Wrong URL format creates broken links to source code
- **Current**: ⚠️ PARTIAL - FR-005 mentions "exact file and line numbers" but no URL pattern

### CHK034: Are the required content elements specified per symbol file?
[Completeness] [Gap]
- **Check**: Does spec define what must be in each symbol.md (signature, params, return, description)?
- **Risk**: Incomplete symbol files missing critical API information
- **Current**: ❌ MISSING - SC-002 mentions "complete signatures" but no structured content requirements

---

## Discovery Files - llms.txt

### CHK035: Is the llms.txt location specified (21.dev root, not md.21.dev)?
[Clarity] [Spec §FR-040]
- **Check**: Does spec explicitly state llms.txt lives at 21.dev, not md.21.dev?
- **Risk**: Creating file in wrong location makes documentation undiscoverable
- **Current**: ✅ PASS - FR-040 says "llms.txt at 21.dev"

### CHK036: Is the llms.txt standard URL specified (https://llmstxt.org)?
[Completeness] [Spec §FR-040]
- **Check**: Does spec reference llms.txt standard specification?
- **Risk**: Implementing custom format instead of standard makes file non-compliant
- **Current**: ✅ PASS - FR-040 explicitly says "following llms.txt standard"

### CHK037: Are the required llms.txt sections specified?
[Completeness] [Gap]
- **Check**: Does spec define what sections to include (site description, module links, structure)?
- **Risk**: Incomplete llms.txt missing critical discovery information
- **Current**: ❌ MISSING - FR-040 mentions standard but no content requirements

### CHK038: Are the llms.txt URL patterns specified for md.21.dev references?
[Clarity] [Gap]
- **Check**: Does spec define how to link to md.21.dev from llms.txt (module overviews, example symbols)?
- **Risk**: Wrong URL patterns in llms.txt lead LLMs to non-existent pages
- **Current**: ❌ MISSING - No URL pattern guidance for llms.txt content

---

## Discovery Files - agents.md

### CHK039: Is the agents.md target location specified (swift-secp256k1 repo root)?
[Clarity] [Spec §FR-040]
- **Check**: Does spec state agents.md goes in swift-secp256k1 repository, not this repo?
- **Risk**: Creating file in wrong repo makes it unavailable to LLMs
- **Current**: ✅ PASS - FR-040 says "agents.md in swift-secp256k1 repository"

### CHK040: Are the required agents.md sections specified?
[Completeness] [Gap]
- **Check**: Does spec define what content agents.md needs (setup, module links, structure)?
- **Risk**: Incomplete template doesn't provide agents with necessary guidance
- **Current**: ❌ MISSING - FR-040 mentions agents.md but no content requirements

### CHK041: Is the agents.md delivery mechanism specified (template file)?
[Clarity] [Gap]
- **Check**: Does spec clarify that this repo creates a template, not the final agents.md?
- **Risk**: Confusion about who creates/maintains agents.md
- **Current**: ❌ MISSING - No clarification on template vs final file

---

## Discovery Files - Root Index

### CHK042: Are the root index.md content requirements specified?
[Completeness] [Spec §FR-041]
- **Check**: Does spec define what information to include for human visitors?
- **Risk**: Unhelpful index confuses accidental visitors
- **Current**: ⚠️ PARTIAL - FR-041 says "explaining structure" but no specific content

### CHK043: Is the index.md generation timing specified (after split, before upload)?
[Clarity] [Gap]
- **Check**: Does spec define when in the workflow to create index.md?
- **Risk**: Creating too early (before split) means can't include actual file counts
- **Current**: ❌ MISSING - No workflow step ordering for index creation

---

## Error Handling & Logging

### CHK044: Are the required error context elements specified per pipeline stage?
[Completeness] [Spec §FR-022, SC-007]
- **Check**: Does spec define what info to log: stage name, error type, affected paths, command that failed?
- **Risk**: Generic errors delay diagnosis beyond 5-minute SC-007 target
- **Current**: ✅ PASS - FR-022 says "actionable context"; SC-007 requires stage identification

### CHK045: Are the error messages specified for each known failure mode?
[Completeness] [Spec §Edge Cases]
- **Check**: Does spec provide example error messages for key failures?
- **Risk**: Inconsistent or unclear error messages across stages
- **Current**: ⚠️ PARTIAL - Edge cases describe failures but no specific error message text

### CHK046: Is the logging level specified (minimal, errors only)?
[Clarity] [Spec Clarifications]
- **Check**: Does spec define how much to log (debug vs info vs error only)?
- **Risk**: Verbose logging makes CI output hard to scan; missing logs hide issues
- **Current**: ✅ PASS - Clarifications Q6 states "Minimal logging - only errors and final status"

---

## Reusable Workflow Architecture

### CHK047: Are the reusable workflow input/output contracts specified?
[Completeness] [Spec §FR-032]
- **Check**: Does spec define inputs (ref, swift-version) and outputs (artifact-name) for generate-markdown.yml?
- **Risk**: Wrong interface prevents orchestrator workflow from calling correctly
- **Current**: ⚠️ PARTIAL - FR-032 mentions pattern but no explicit input/output definitions

### CHK048: Is the workflow reuse pattern specified (MD-21-DEV calls generate + deploy)?
[Clarity] [Spec §FR-032]
- **Check**: Does spec define orchestrator pattern: MD-21-DEV.yml calls generate-markdown.yml and deploy-cloudflare.yml?
- **Risk**: Creating monolithic workflow instead of reusable components
- **Current**: ✅ PASS - FR-032 explicitly describes the three-workflow pattern

### CHK049: Are the workflow job dependencies specified (deploy needs generate)?
[Completeness] [Gap]
- **Check**: Does spec define job ordering: generate must complete before deploy?
- **Risk**: Deploy starting before generate completes causes artifact-not-found errors
- **Current**: ❌ MISSING - No job dependency specification

---

## Performance & Scalability

### CHK050: Is the total time budget specified (15 minutes)?
[Measurability] [Spec §SC-004, SC-005]
- **Check**: Does spec define maximum acceptable time for full workflow?
- **Risk**: Slow workflows without clear SLO; no baseline for optimization
- **Current**: ✅ PASS - SC-004 and SC-005 both specify "15 minutes"

### CHK051: Is the time budget breakdown specified per stage?
[Measurability] [Gap]
- **Check**: Does spec allocate time budget across DocC gen, export, split, upload stages?
- **Risk**: Can't identify bottleneck stage when total time approaches limit
- **Current**: ❌ MISSING - Only total time specified, no per-stage breakdown

---

## Summary

**Total Items**: 51  
**Status Breakdown**:
- ✅ **PASS**: 23 items (45%)
- ⚠️ **PARTIAL**: 13 items (25%)
- ❌ **MISSING**: 15 items (30%)

**Critical Gaps (Block Implementation)**:
1. **CHK003**: Missing DocC command flag specification (--combined-documentation)
2. **CHK006**: Incomplete DocC4LLM export command
3. **CHK010**: No delimiter validation logic
4. **CHK024**: No PR merge detection logic
5. **CHK028**: No deploy-to-production flag logic
6. **CHK047**: Missing workflow input/output contracts
7. **CHK049**: No job dependency specification

**High-Risk Gaps (Workflow Execution Failures)**:
1. **CHK008**: No empty export output handling
2. **CHK011**: No awk path transformation rules
3. **CHK015**: No artifact naming pattern
4. **CHK018**: No zipping fallback trigger condition
5. **CHK034**: No per-symbol content requirements

**Recommendation**: Address critical gaps before starting workflow implementation. High-risk gaps can be clarified during implementation but increase rework risk.
