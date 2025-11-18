# Sitemap State File Schema

**Feature**: 001-sitemap-infrastructure  
**File**: `Resources/sitemap-state.json`  
**Purpose**: Persist swift-secp256k1 package version and generation timestamp for lastmod preservation

## JSON Schema

### Structure

```json
{
  "package_version": "string (semver)",
  "generated_date": "string (ISO 8601 timestamp)"
}
```

### Field Specifications

#### `package_version`

**Type**: String  
**Format**: Semantic versioning (major.minor.patch)  
**Required**: Yes  
**Source**: `Package.resolved` → pins array → swift-secp256k1 entry → state.version

**Validation**:
- Must match semver pattern: `^\d+\.\d+\.\d+(-[a-zA-Z0-9.-]+)?(\+[a-zA-Z0-9.-]+)?$`
- Examples: `0.22.0`, `1.0.0`, `0.21.0-beta.1`

**Extraction Command**:
```bash
jq -r '.pins[] | select(.identity == "swift-secp256k1") | .state.version' Package.resolved
```

---

#### `generated_date`

**Type**: String  
**Format**: ISO 8601 timestamp with timezone  
**Required**: Yes  
**Value**: Timestamp when docs/md sitemaps were last generated with this package version

**Format**: `YYYY-MM-DDTHH:MM:SS±HH:MM`  
**Example**: `2025-11-14T19:30:00-08:00`

**Generation Command**:
```bash
date -u +"%Y-%m-%dT%H:%M:%S%z"
```

---

## Complete Examples

### Initial State
```json
{
  "package_version": "0.22.0",
  "generated_date": "2025-11-13T14:20:00-08:00"
}
```

### After Version Update
```json
{
  "package_version": "0.23.0",
  "generated_date": "2025-11-14T19:30:00-08:00"
}
```

---

## Lifecycle

### 1. File Creation (First Time)

**Trigger**: First docs or md sitemap generation when file doesn't exist

**Process**:
1. Check if `Resources/sitemap-state.json` exists
2. If not, extract current swift-secp256k1 version from Package.resolved
3. Get current timestamp
4. Create file with both values
5. Commit file to repository

**Script Pseudocode**:
```bash
if [ ! -f "Resources/sitemap-state.json" ]; then
  VERSION=$(jq -r '.pins[] | select(.identity == "swift-secp256k1") | .state.version' Package.resolved)
  TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%S%z")
  echo "{\"package_version\":\"$VERSION\",\"generated_date\":\"$TIMESTAMP\"}" > Resources/sitemap-state.json
  git add Resources/sitemap-state.json
  git commit -m "Initialize sitemap state for swift-secp256k1 v$VERSION"
fi
```

---

### 2. Version Change Detection (Lefthook)

**Trigger**: `git checkout`, `git merge`, `git rebase` that modifies Package.resolved

**Hook**: `.lefthook/post-checkout.yml`

**Process**:
1. Check if Package.resolved was modified in this operation
2. Extract new swift-secp256k1 version from Package.resolved
3. Read current package_version from sitemap-state.json
4. Compare versions
5. If different:
   - Update state file with new version + current timestamp
   - Stage file for commit (developer commits manually)
   - Print notification
6. If same: No action

**Script Pseudocode**:
```bash
#!/bin/bash
# .lefthook/scripts/update-sitemap-state.sh

STATE_FILE="Resources/sitemap-state.json"
NEW_VERSION=$(jq -r '.pins[] | select(.identity == "swift-secp256k1") | .state.version' Package.resolved)

if [ ! -f "$STATE_FILE" ]; then
  # File doesn't exist, create it
  TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%S%z")
  echo "{\"package_version\":\"$NEW_VERSION\",\"generated_date\":\"$TIMESTAMP\"}" > "$STATE_FILE"
  echo "✅ Created sitemap state for swift-secp256k1 v$NEW_VERSION"
  exit 0
fi

CURRENT_VERSION=$(jq -r '.package_version' "$STATE_FILE")

if [ "$NEW_VERSION" != "$CURRENT_VERSION" ]; then
  TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%S%z")
  jq --arg version "$NEW_VERSION" --arg date "$TIMESTAMP" \
    '.package_version = $version | .generated_date = $date' \
    "$STATE_FILE" > "$STATE_FILE.tmp" && mv "$STATE_FILE.tmp" "$STATE_FILE"
  echo "✅ Updated sitemap state: v$CURRENT_VERSION → v$NEW_VERSION"
  echo "⚠️  Don't forget to commit Resources/sitemap-state.json"
else
  echo "ℹ️  Sitemap state unchanged (swift-secp256k1 v$CURRENT_VERSION)"
fi
```

---

### 3. Sitemap Generation (Read)

**Trigger**: docs.21.dev or md.21.dev sitemap generation during CI

**Process**:
1. Read sitemap-state.json
2. Extract package_version and generated_date
3. Compare package_version with current Package.resolved version
4. If versions match:
   - Use generated_date as lastmod for all docs/md pages
   - Preserve existing timestamps (no change)
5. If versions differ (state file stale):
   - Log warning
   - Use current timestamp as lastmod
   - Update state file (should not happen if Lefthook working)

**Script Pseudocode**:
```bash
#!/bin/bash
# Extract lastmod for docs/md sitemap

STATE_FILE="Resources/sitemap-state.json"
CURRENT_VERSION=$(jq -r '.pins[] | select(.identity == "swift-secp256k1") | .state.version' Package.resolved)

if [ ! -f "$STATE_FILE" ]; then
  # Fallback: use current timestamp
  LASTMOD=$(date -u +"%Y-%m-%d")
  echo "⚠️  State file missing, using current timestamp"
else
  STATE_VERSION=$(jq -r '.package_version' "$STATE_FILE")
  
  if [ "$STATE_VERSION" = "$CURRENT_VERSION" ]; then
    # Versions match, use stored timestamp
    GENERATED_DATE=$(jq -r '.generated_date' "$STATE_FILE")
    LASTMOD=$(echo "$GENERATED_DATE" | cut -d'T' -f1)  # Extract date portion
    echo "✅ Using preserved lastmod: $LASTMOD (swift-secp256k1 v$STATE_VERSION)"
  else
    # Versions mismatch, use current timestamp
    LASTMOD=$(date -u +"%Y-%m-%d")
    echo "⚠️  Version mismatch (state: v$STATE_VERSION, current: v$CURRENT_VERSION), using current timestamp"
  fi
fi

# Use $LASTMOD for all URLs in sitemap
```

---

## Validation

### JSON Schema Compliance

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "type": "object",
  "required": ["package_version", "generated_date"],
  "properties": {
    "package_version": {
      "type": "string",
      "pattern": "^\\d+\\.\\d+\\.\\d+(-[a-zA-Z0-9.-]+)?(\\+[a-zA-Z0-9.-]+)?$",
      "description": "Semantic version of swift-secp256k1 package"
    },
    "generated_date": {
      "type": "string",
      "pattern": "^\\d{4}-\\d{2}-\\d{2}T\\d{2}:\\d{2}:\\d{2}[+-]\\d{2}:\\d{2}$",
      "description": "ISO 8601 timestamp with timezone"
    }
  },
  "additionalProperties": false
}
```

### Validation Commands

```bash
# Validate JSON syntax
jq empty Resources/sitemap-state.json

# Validate required fields
jq -e '.package_version and .generated_date' Resources/sitemap-state.json

# Validate semver format
jq -e '.package_version | test("^\\d+\\.\\d+\\.\\d+")' Resources/sitemap-state.json

# Validate timestamp format
jq -e '.generated_date | test("^\\d{4}-\\d{2}-\\d{2}T")' Resources/sitemap-state.json
```

---

## Error Handling

### File Missing
- **During Generation**: Use current timestamp as fallback, continue
- **During Lefthook**: Create file with current values

### File Corrupt (Invalid JSON)
- **During Generation**: Log error, use current timestamp, continue
- **During Lefthook**: Backup corrupt file, create new file

### Missing Fields
- **During Generation**: Log error, use current timestamp, continue
- **During Lefthook**: Add missing fields with default values

### Version Not Found in Package.resolved
- **During Generation**: Error, fail build (swift-secp256k1 required)
- **During Lefthook**: Log warning, skip update

---

## Git Workflow Integration

### Commit Message Pattern

```
Update sitemap state for swift-secp256k1 v{version}

- Package version: {old_version} → {new_version}
- Generated date: {new_timestamp}
- Triggered by: Package.resolved update
```

### Example Commit

```
Update sitemap state for swift-secp256k1 v0.23.0

- Package version: 0.22.0 → 0.23.0
- Generated date: 2025-11-14T19:30:00-08:00
- Triggered by: Package.resolved update
```

---

## Future Enhancements

### Multi-Package Support (if needed)
```json
{
  "packages": {
    "swift-secp256k1": {
      "version": "0.22.0",
      "generated_date": "2025-11-14T19:30:00-08:00"
    }
  }
}
```

### Per-Sitemap Timestamps (if docs/md diverge)
```json
{
  "package_version": "0.22.0",
  "docs_generated_date": "2025-11-14T19:30:00-08:00",
  "md_generated_date": "2025-11-14T19:30:00-08:00"
}
```

**Current Implementation**: Single shared state is sufficient since both docs and md are generated from same package.
