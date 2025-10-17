# Workflow Contract: generate-markdown.yml

**Type**: Reusable GitHub Actions Workflow  
**Purpose**: Generate DocC archive, export to markdown, split into individual files, upload artifact  
**Caller**: MD-21-DEV.yml orchestrator workflow

## Inputs

### `ref` (string, required)
- **Description**: Git ref to checkout (branch, tag, or SHA)
- **Example**: `"main"`, `"002-i-want-to"`, `"abc123f"`
- **Usage**: Passed to `actions/checkout@v4`

### `swift-version` (string, optional)
- **Description**: Swift toolchain version
- **Default**: `"6.1"`
- **Example**: `"6.1"`, `"6.2"`
- **Usage**: Passed to `swift-actions/setup-swift@v2`

## Outputs

### `artifact-name` (string)
- **Description**: Name of the uploaded artifact containing markdown documentation
- **Value**: `"markdown-docs-${{ github.sha }}"`
- **Example**: `"markdown-docs-a1b2c3d4"`
- **Usage**: Consumed by deploy-cloudflare.yml for deployment

## Workflow Steps

### 1. Checkout Repository
```yaml
- uses: actions/checkout@v4
  with:
    ref: ${{ inputs.ref }}
```

### 2. Setup Swift
```yaml
- uses: swift-actions/setup-swift@v2
  with:
    swift-version: ${{ inputs.swift-version }}
```

### 3. Resolve Dependencies
```yaml
- run: swift package resolve
```
- **Validates**: Package.resolved matches Package.swift
- **Ensures**: Exact dependency versions (FR-017)

### 4. Generate DocC Archive
```yaml
- run: |
    swift package \
      --allow-writing-to-directory ./Archives \
      generate-documentation \
      --target docs-21-dev-P256K \
      --target docs-21-dev-ZKP \
      --output-path ./Archives/md-21-dev.doccarchive \
      --combined-documentation
```
- **Output**: `./Archives/md-21-dev.doccarchive/`
- **Targets**: P256K, ZKP (FR-001)
- **Feature**: Combined documentation (FR-002)
- **Exit on Error**: Yes (FR-013)

### 5. Export to Markdown
```yaml
- run: |
    swift run docc4llm export \
      Archives/md-21-dev.doccarchive \
      --output-path md-21-dev-concatenated.md
```
- **Input**: `.doccarchive` directory
- **Output**: Single concatenated markdown file (~1.1MB, 68k lines)
- **Tool**: DocC4LLM 1.0.0 (FR-034, FR-039)
- **Exit on Error**: Yes (FR-013)

### 6. Validate Format
```yaml
- name: Validate delimiter format
  run: |
    START_COUNT=$(grep -c "^=== START FILE:" md-21-dev-concatenated.md || true)
    END_COUNT=$(grep -c "^=== END FILE ===$" md-21-dev-concatenated.md || true)
    
    if [ "$START_COUNT" -eq 0 ] || [ "$END_COUNT" -eq 0 ]; then
      echo "❌ Format validation failed"
      echo "START markers: $START_COUNT"
      echo "END markers: $END_COUNT"
      echo "Expected: >0 for both"
      exit 1
    fi
    
    if [ "$START_COUNT" -ne "$END_COUNT" ]; then
      echo "❌ Delimiter mismatch"
      echo "START markers: $START_COUNT"
      echo "END markers: $END_COUNT"
      exit 1
    fi
    
    echo "✓ Format validation passed (delimiters: $START_COUNT)"
```
- **Validates**: Delimiter markers present and balanced (FR-037)
- **Fails**: If delimiters missing or mismatched
- **Logs**: Actionable error with counts (FR-022)

### 7. Split into Individual Files
```yaml
- name: Split markdown into individual files
  run: |
    mkdir -p Websites/md-21-dev
    cd Websites/md-21-dev
    
    awk '/=== START FILE: /{
      gsub(/ ===$/, "", $4)
      path=$4
      sub(/^data\/documentation\//, "", path)
      sub(/\.json$/, ".md", path)
      system("mkdir -p \"$(dirname \"" path "\")\"")}
    /=== END FILE ===/{
      close(path)
      path=""
      next}
    path{
      print > path
    }' ../../md-21-dev-concatenated.md
    
    FILE_COUNT=$(find . -type f -name "*.md" | wc -l)
    echo "✓ File splitting complete (files: $FILE_COUNT)"
```
- **Input**: Concatenated markdown file
- **Output**: 2,500+ individual `.md` files in `Websites/md-21-dev/`
- **Structure**: Two-level hierarchy `target/symbol.md` (FR-026, FR-027)
- **Tool**: awk (FR-036)

### 8. Monitor Size
```yaml
- name: Monitor deployment size
  run: |
    FILE_COUNT=$(find Websites/md-21-dev -type f | wc -l)
    SIZE_MB=$(du -sm Websites/md-21-dev | cut -f1)
    
    echo "Files: $FILE_COUNT"
    echo "Size: ${SIZE_MB}MB"
    
    if [ "$FILE_COUNT" -gt 15000 ]; then
      echo "::warning::Approaching file limit: $FILE_COUNT files (limit: 20,000)"
    fi
    
    if [ "$SIZE_MB" -gt 20 ]; then
      echo "::warning::Approaching size limit: ${SIZE_MB}MB (limit: 25MB)"
    fi
```
- **Monitors**: File count and total size (FR-038)
- **Warns**: At 75% thresholds (15k files, 20MB)
- **Does NOT Fail**: Warnings only (clarification Q14)

### 9. Create Root Index
```yaml
- name: Create root index
  run: |
    cat > Websites/md-21-dev/index.md << 'EOF'
    # Swift secp256k1 Documentation
    
    LLM-optimized markdown documentation for the swift-secp256k1 library.
    
    ## Modules
    
    - [P256K](./p256k.md) - secp256k1 Elliptic Curve operations
    - [ZKP](./zkp.md) - Zero-Knowledge Proof operations
    
    ## Structure
    
    Documentation is organized as individual markdown files per symbol:
    - Pattern: `/{module}/{symbol-name}.md`
    - Example: [/p256k/int128.md](./p256k/int128.md)
    
    For programmatic discovery, see:
    - [llms.txt at 21.dev](https://21.dev/llms.txt)
    - agents.md in swift-secp256k1 repository
    EOF
```
- **Creates**: Human-readable index (FR-041)
- **Purpose**: Helps accidental human visitors understand structure

### 10. Upload Artifact
```yaml
- uses: actions/upload-artifact@v4
  with:
    name: markdown-docs-${{ github.sha }}
    path: Websites/md-21-dev/
    retention-days: 1
```
- **Artifact Name**: Includes commit SHA for uniqueness
- **Path**: Entire markdown directory
- **Retention**: 1 day (FR-019)
- **Compression**: Automatic by actions/upload-artifact

## Error Handling

### DocC Generation Failure
```
❌ DocC generation failed
Stage: swift package generate-documentation
Target: docs-21-dev-P256K, docs-21-dev-ZKP
Exit code: 1
Error: [swift package error output]
Action: Check Package.swift documentation targets exist
```

### Markdown Export Failure
```
❌ Markdown export failed
Stage: DocC4LLM export
Command: swift run docc4llm export Archives/md-21-dev.doccarchive
Exit code: 1
Error: [DocC4LLM error output]
Action: Verify archive exists at path and DocC4LLM is in Package.swift
```

### Format Validation Failure
```
❌ Format validation failed
START markers: 0
END markers: 0
Expected: >0 for both
Action: DocC4LLM version may have changed format - review output file
```

### Split Failure
```
❌ File splitting complete (files: 0)
Action: awk command failed or no valid delimiters found
```

## Success Criteria

- ✓ DocC archive generated successfully
- ✓ Markdown export completes without errors
- ✓ Delimiter validation passes (START count = END count > 0)
- ✓ File splitting produces 2,500+ files
- ✓ Size within Cloudflare limits (<20k files, <25MB)
- ✓ Artifact uploaded successfully
- ✓ Total time <15 minutes (SC-005)

## Contract Guarantees

**IF** workflow succeeds **THEN**:
1. Artifact `markdown-docs-${{ github.sha }}` exists
2. Artifact contains 2,500+ markdown files
3. Files follow `target/symbol.md` structure
4. Files are valid CommonMark markdown (SC-008)
5. Total size <25MB, <20k files
6. Artifact retention = 1 day

**IF** workflow fails **THEN**:
1. Error identifies stage (DocC gen, export, split, validate)
2. Error includes command that failed
3. Error provides actionable next step
4. No artifact uploaded (fail fast)
5. Diagnosis possible within 5 minutes (SC-007)
