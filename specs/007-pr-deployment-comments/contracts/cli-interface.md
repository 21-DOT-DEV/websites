# CLI Interface Contract: util comment

**Feature**: 007-pr-deployment-comments  
**Date**: 2026-01-04

## Command Signature

```bash
swift run util comment \
  --pr <PR_NUMBER> \
  --project <PROJECT_NAME> \
  --status <STATUS> \
  --preview-url <URL> \
  --alias-url <URL> \
  --commit <SHA> \
  --run-url <URL>
```

## Arguments

| Flag | Type | Required | Description |
|------|------|----------|-------------|
| `--pr` | Int | Yes | Pull request number |
| `--project` | String | Yes | Project name (e.g., "21-dev", "docs-21-dev", "md-21-dev") |
| `--status` | String | Yes | Deployment status: "success", "failure", or "pending" |
| `--preview-url` | String | Yes | Cloudflare preview URL |
| `--alias-url` | String | Yes | Cloudflare alias URL |
| `--commit` | String | Yes | Git commit SHA |
| `--run-url` | String | Yes | GitHub Actions run URL |

## Exit Codes

| Code | Meaning |
|------|---------|
| 0 | Success |
| 1 | General error (gh CLI failure, API error) |
| 2 | Invalid arguments |

## Output

### Success (stdout)
```
✅ Updated deployment comment for PR #123
```

### Failure (stderr)
```
Error: gh CLI not found. Ensure GitHub CLI is installed and in PATH.
```
```
Error: Not authenticated. Run 'gh auth login' or set GITHUB_TOKEN.
```
```
Error: Failed to update comment: <API error message>
```

## Environment

| Variable | Required | Description |
|----------|----------|-------------|
| `GITHUB_TOKEN` | Yes (in CI) | Authentication token for gh CLI |
| `GH_TOKEN` | Alternative | Alternative auth token variable |

**Note**: In GitHub Actions, `GITHUB_TOKEN` is automatically available.

## Examples

### Single Deployment
```bash
swift run util comment \
  --pr 42 \
  --project 21-dev \
  --status success \
  --preview-url "https://abc123.21-dev.pages.dev" \
  --alias-url "https://preview.21.dev" \
  --commit "abc1234567890" \
  --run-url "https://github.com/21-DOT-DEV/websites/actions/runs/12345"
```

### Failed Deployment
```bash
swift run util comment \
  --pr 42 \
  --project docs-21-dev \
  --status failure \
  --preview-url "" \
  --alias-url "" \
  --commit "abc1234567890" \
  --run-url "https://github.com/21-DOT-DEV/websites/actions/runs/12345"
```

## Workflow Integration

Replace current bash logic in `deploy-cloudflare.yml`:

```yaml
- name: Update deployment comment
  if: github.event_name == 'pull_request'
  run: |
    swift run util comment \
      --pr ${{ github.event.pull_request.number }} \
      --project ${{ inputs.project-name }} \
      --status ${{ steps.cloudflare.outcome == 'success' && 'success' || 'failure' }} \
      --preview-url "${{ steps.cloudflare.outputs.url }}" \
      --alias-url "${{ steps.cloudflare.outputs.alias }}" \
      --commit "${{ github.sha }}" \
      --run-url "${{ github.server_url }}/${{ github.repository }}/actions/runs/${{ github.run_id }}"
```
