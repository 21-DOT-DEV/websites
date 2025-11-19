# websites

## Setup

### Lefthook (Git Hooks)

This project uses [Lefthook](https://github.com/evilmartians/lefthook) via the [lefthook-plugin](https://github.com/csjones/lefthook-plugin) Swift package to automatically manage the sitemap state file.

**Installation**:

```bash
swift package --disable-sandbox lefthook install
```

**What it does**:
- Automatically updates `Resources/sitemap-state.json` when `Package.resolved` changes
- Tracks the `swift-secp256k1` package version for sitemap lastmod dates
- Ensures docs/md subdomain sitemaps only update when the dependency version changes

**Manual verification**:

```bash
# Check if hooks are installed
swift package --disable-sandbox lefthook check-install

# Validate configuration
swift package --disable-sandbox lefthook validate
```

**Note**: The `--disable-sandbox` flag is required because the plugin needs file system access to manage git hooks.