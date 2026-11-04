# Agent guide — `.github/`

CI/CD conventions for workflows in this repository. Root `AGENTS.md` rules
apply.

## Conventions

- **Runners**: `macos-26` with `DEVELOPER_DIR:
  /Applications/Xcode_26.4.app/Contents/Developer` — keep local and CI
  aligned on toolchain and Tailwind flags.
- **Actions are SHA-pinned** with a version comment
  (`actions/checkout@<sha> # v6.0.2`); never pin floating tags.
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
