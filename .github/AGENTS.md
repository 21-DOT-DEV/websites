# Agent guide — `.github/`

CI/CD conventions for workflows in this repository. Root `AGENTS.md` rules
apply.

## Conventions

- **Runners**: `macos-26` with `DEVELOPER_DIR:
  /Applications/Xcode_26.4.app/Contents/Developer` — keep local and CI
  aligned on toolchain and Tailwind flags. Shell-only jobs that use no
  Swift/Xcode toolchain may run `ubuntu-latest` instead.
- **Actions are SHA-pinned** with a version comment
  (`actions/checkout@<sha> # v7.0.1`); never pin floating tags.
  `action-pins.yml` verifies each comment's tag resolves to its pinned SHA.
- **Untrusted PRs get no deploy** — Dependabot- and fork-authored PRs
  receive no secrets and a read-only token, so `deploy-cloudflare.yml`
  skips itself there and reports the reason via its notice job instead.
- **Least privilege**: `permissions: {}` at the top, minimal job-level grants
  (e.g. `contents: read`, `pull-requests: write` only on the job that posts
  comments).
- **Path filters** gate each workflow to its own files — a workflow only runs
  when its subjects change.
- **Reusable workflows** (`uses: ./.github/workflows/...`) carry shared deploy
  logic; behavior lives in `util` subcommands, not inline shell (ADR 0004).
- **Gate doctrine**: correctness checks may block; process/documentation
  checks are advisory (visible on the PR, not required). `development-docs.yml`
  is advisory by design — see `Development/Roadmap/backlog.md` for the
  promotion path.
- `Websites/` build output never lands in a commit; deploys run only from a
  clean, passing `main`.
