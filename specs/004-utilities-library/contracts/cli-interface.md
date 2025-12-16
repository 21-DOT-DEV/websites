# CLI Interface Contract: util

**Feature**: 004-utilities-library  
**Date**: 2025-12-15

## Overview

The `util` CLI provides subcommands for sitemap generation, headers validation, and state management for 21.dev websites.

## Command Structure

```
util <subcommand> <action> [options]
```

## Global Options

| Option | Short | Type | Description |
|--------|-------|------|-------------|
| `--help` | `-h` | Flag | Show help for command |
| `--verbose` | `-v` | Flag | Enable verbose output |

---

## Subcommand: sitemap

### sitemap generate

Generate a sitemap.xml for a specific site.

**Usage**:
```bash
util sitemap generate --site <site-name> [--output <path>] [--verbose]
```

**Options**:
| Option | Short | Type | Required | Default | Description |
|--------|-------|------|----------|---------|-------------|
| `--site` | `-s` | String | Yes | — | Site name: `21-dev`, `docs-21-dev`, `md-21-dev` |
| `--output` | `-o` | String | No | `Websites/<site>/sitemap.xml` | Output file path |
| `--verbose` | `-v` | Flag | No | false | Show detailed progress |

**Exit Codes**:
| Code | Meaning |
|------|---------|
| 0 | Success |
| 1 | Invalid arguments |
| 2 | Site output directory not found |
| 3 | No URLs discovered |
| 4 | Write error |

**Output (stdout)**:
```
✅ Sitemap generated: Websites/21-dev/sitemap.xml (42 URLs)
```

**Output (--verbose)**:
```
🔍 Discovering URLs in Websites/21-dev/...
  Found: https://21.dev/
  Found: https://21.dev/packages/swift-secp256k1/
  ... (42 URLs total)
📅 Computing lastmod dates...
  Using git commit dates for 21-dev
📝 Writing sitemap to Websites/21-dev/sitemap.xml
✅ Sitemap generated: Websites/21-dev/sitemap.xml (42 URLs)
```

---

### sitemap validate

Validate an existing sitemap.xml file.

**Usage**:
```bash
util sitemap validate --site <site-name> [--input <path>] [--verbose]
```

**Options**:
| Option | Short | Type | Required | Default | Description |
|--------|-------|------|----------|---------|-------------|
| `--site` | `-s` | String | Yes | — | Site name for base URL validation |
| `--input` | `-i` | String | No | `Websites/<site>/sitemap.xml` | Sitemap file to validate |
| `--verbose` | `-v` | Flag | No | false | Show all validated URLs |

**Exit Codes**:
| Code | Meaning |
|------|---------|
| 0 | Valid sitemap |
| 1 | Invalid arguments |
| 2 | File not found |
| 3 | Invalid XML |
| 4 | Invalid URLs found |

**Output (success)**:
```
✅ Sitemap valid: 42 URLs, all correctly formatted
```

**Output (failure)**:
```
❌ Sitemap validation failed:
  [INVALID_URL] URL exceeds 2048 characters at line 15
  [INVALID_URL] Missing scheme at line 23
```

---

## Subcommand: headers

### headers validate

Validate a Cloudflare _headers file.

**Usage**:
```bash
util headers validate --site <site-name> --env <environment> [--input <path>] [--verbose]
```

**Options**:
| Option | Short | Type | Required | Default | Description |
|--------|-------|------|----------|---------|-------------|
| `--site` | `-s` | String | Yes | — | Site name: `21-dev`, `docs-21-dev`, `md-21-dev` |
| `--env` | `-e` | String | Yes | — | Environment: `prod`, `dev` |
| `--input` | `-i` | String | No | `Resources/<site>/_headers.<env>` | Headers file to validate |
| `--verbose` | `-v` | Flag | No | false | Show all validated rules |

**Exit Codes**:
| Code | Meaning |
|------|---------|
| 0 | Valid headers |
| 1 | Invalid arguments |
| 2 | File not found |
| 3 | Parse error |
| 4 | Missing required headers (prod only) |
| 5 | Invalid header format |

**Output (success)**:
```
✅ Headers valid: 12 rules for 21-dev (prod)
```

**Output (failure)**:
```
❌ Headers validation failed:
  [MISSING_HEADER] X-Frame-Options required for prod at /*
  [INVALID_FORMAT] Invalid header syntax at line 8
```

**Required Headers (prod)**:
- `X-Frame-Options`
- `X-Content-Type-Options`
- `Referrer-Policy`

---

## Subcommand: state

### state update

Update the state file with new package version.

**Usage**:
```bash
util state update [--package-version <version>] [--file <path>] [--verbose]
```

**Options**:
| Option | Short | Type | Required | Default | Description |
|--------|-------|------|----------|---------|-------------|
| `--package-version` | `-p` | String | No | Auto-detect from Package.resolved | Version string (semver) |
| `--file` | `-f` | String | No | `Resources/sitemap-state.json` | State file path |
| `--verbose` | `-v` | Flag | No | false | Show detailed changes |

**Exit Codes**:
| Code | Meaning |
|------|---------|
| 0 | Success |
| 1 | Invalid arguments |
| 2 | Cannot detect package version |
| 3 | Write error |

**Output**:
```
✅ State updated: 0.21.0 → 0.21.1 (2025-12-15T08:30:00Z)
```

---

### state validate

Validate the state file format and content.

**Usage**:
```bash
util state validate [--file <path>] [--verbose]
```

**Options**:
| Option | Short | Type | Required | Default | Description |
|--------|-------|------|----------|---------|-------------|
| `--file` | `-f` | String | No | `Resources/sitemap-state.json` | State file path |
| `--verbose` | `-v` | Flag | No | false | Show all fields |

**Exit Codes**:
| Code | Meaning |
|------|---------|
| 0 | Valid state file |
| 1 | Invalid arguments |
| 2 | File not found |
| 3 | Invalid JSON |
| 4 | Missing required fields |
| 5 | Invalid field format |

**Output (success)**:
```
✅ State file valid: version 0.21.1, 2 subdomains
```

**Output (failure)**:
```
❌ State file validation failed:
  [INVALID_JSON] Unexpected token at line 3
  [MISSING_FIELD] Required field 'package_version' not found
```

---

## Help Output

### util --help

```
OVERVIEW: CLI utilities for 21.dev websites

USAGE: util <subcommand>

OPTIONS:
  -h, --help              Show help information.

SUBCOMMANDS:
  sitemap                 Generate and validate sitemaps
  headers                 Validate Cloudflare _headers files
  state                   Manage sitemap state files

  See 'util <subcommand> --help' for detailed help.
```

### util sitemap --help

```
OVERVIEW: Generate and validate sitemaps

USAGE: util sitemap <subcommand>

OPTIONS:
  -h, --help              Show help information.

SUBCOMMANDS:
  generate                Generate sitemap.xml for a site
  validate                Validate an existing sitemap

  See 'util sitemap <subcommand> --help' for detailed help.
```
