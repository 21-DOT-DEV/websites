---
feature: 005
title: Sticky deployment comments on pull requests
phase: "2 · Utilities Library Refactoring"
status: Implemented
updated: 2026-11-02
adrs: [4]
---

# Sticky deployment comments on pull requests

## Goal

Each deployment pull request carries one self-updating comment with the
preview URL and status — current information without a trail of repeated
comments.

## Approach

- `util comment` (part of the utilities CLI — see `Specs/004-utilities-cli`,
  whose `contracts/comment-interface.md` defines the subcommand) posts and
  updates the comment through the GitHub API.
- `deploy-cloudflare.yml` calls `swift run util comment ...` in its
  "Update deployment comment on PR" step; the job's `pull-requests: write`
  permission is scoped to that job only.
- The comment is idempotent: a marker identifies the bot comment so each run
  edits the same comment instead of posting a new one.

## Verification

- Open a deployment PR and observe a single comment updating in place across
  redeploys — exercised continuously by the normal deploy pipeline, so the
  manual-validation leftover is tracked in `../../Roadmap/backlog.md` rather
  than kept open here.
