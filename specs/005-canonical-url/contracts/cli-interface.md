# CLI Interface Contract: Canonical URL Commands

**Feature**: 005-canonical-url  
**Date**: 2025-12-30

## Command Structure

```
util canonical <subcommand> [options]
```

### Subcommands

| Subcommand | Description |
|------------|-------------|
| `check` | Audit HTML files for canonical URL issues |
| `fix` | Add or update canonical URL tags |

---

## `util canonical check`

Scans HTML files and reports canonical URL status.

### Synopsis

```
util canonical check --path <directory> --base-url <url> [--verbose]
```

### Options

| Option | Short | Required | Description |
|--------|-------|----------|-------------|
| `--path` | | Yes | Directory containing HTML files to scan |
| `--base-url` | | Yes | Base URL for canonical derivation (e.g., `https://21.dev`) |
| `--verbose` | `-v` | No | Show detailed output for each file |

### Exit Codes

| Code | Meaning |
|------|---------|
| `0` | All files have valid canonical tags |
| `1` | One or more files have missing or mismatched canonicals |

### Output Format

**Default (summary)**:
```
Checking canonicals in ./Websites/21-dev...

✅ 45 valid
⚠️ 3 mismatch
❌ 12 missing

Result: 12 issues found
```

**Verbose (`-v`)**:
```
Checking canonicals in ./Websites/21-dev...

✅ index.html → https://21.dev/
✅ about/index.html → https://21.dev/about/
⚠️ docs/guide.html
   Expected: https://21.dev/docs/guide
   Found:    https://old-domain.dev/docs/guide
❌ blog/post-1.html (missing)
❌ blog/post-2.html (missing)

Summary:
✅ 45 valid
⚠️ 3 mismatch
❌ 12 missing

Result: 12 issues found
```

---

## `util canonical fix`

Adds or updates canonical URL tags in HTML files.

### Synopsis

```
util canonical fix --path <directory> --base-url <url> [--force] [--dry-run] [--verbose]
```

### Options

| Option | Short | Required | Description |
|--------|-------|----------|-------------|
| `--path` | | Yes | Directory containing HTML files to fix |
| `--base-url` | | Yes | Base URL for canonical derivation |
| `--force` | | No | Overwrite existing canonical tags (even if different) |
| `--dry-run` | | No | Preview changes without modifying files |
| `--verbose` | `-v` | No | Show detailed output for each file |

### Exit Codes

| Code | Meaning |
|------|---------|
| `0` | All fixes applied successfully |
| `1` | One or more files could not be fixed |

### Behavior Matrix

| Current State | `--force` | Action |
|---------------|-----------|--------|
| Missing | N/A | Insert canonical tag |
| Mismatch | No | Skip (warn) |
| Mismatch | Yes | Update canonical tag |
| Valid | N/A | Skip (no change needed) |
| Error | N/A | Skip (cannot fix) |

### Output Format

**Default**:
```
Fixing canonicals in ./Websites/docs-21-dev...

✅ Added: 12 files
⚠️ Skipped: 3 files (existing canonical, use --force to overwrite)
❌ Failed: 0 files

Result: 12 files updated
```

**Dry-run (`--dry-run`)**:
```
Fixing canonicals in ./Websites/docs-21-dev... (dry run)

Would add canonical to:
  - documentation/p256k/index.html → https://docs.21.dev/documentation/p256k/
  - documentation/zkp/index.html → https://docs.21.dev/documentation/zkp/
  ... (10 more)

Would skip (existing canonical):
  - index.html (has: https://docs.21.dev/)

Summary:
  Would add: 12 files
  Would skip: 3 files

No files were modified (dry run)
```

---

## Validation Rules

### `--path` Validation
- Must exist
- Must be a directory
- Must be readable

**Error**: `Error: Path does not exist or is not a directory: /invalid/path`

### `--base-url` Validation
- Must be valid URL
- Must have `http://` or `https://` scheme
- Should not have trailing path (warning only)

**Error**: `Error: Invalid base URL. Must include scheme (e.g., https://21.dev)`

---

## Integration Examples

### CI Pipeline (GitHub Actions)

```yaml
- name: Check canonical URLs
  run: |
    swift run util canonical check \
      --path ./Websites/docs-21-dev \
      --base-url https://docs.21.dev
```

### Local Development

```bash
# Check all sites
swift run util canonical check --path ./Websites/21-dev --base-url https://21.dev -v
swift run util canonical check --path ./Websites/docs-21-dev --base-url https://docs.21.dev -v
swift run util canonical check --path ./Websites/md-21-dev --base-url https://md.21.dev -v

# Fix missing canonicals (preview first)
swift run util canonical fix --path ./Websites/docs-21-dev --base-url https://docs.21.dev --dry-run
swift run util canonical fix --path ./Websites/docs-21-dev --base-url https://docs.21.dev

# Force update all canonicals (domain migration)
swift run util canonical fix --path ./Websites/21-dev --base-url https://new-domain.dev --force
```
