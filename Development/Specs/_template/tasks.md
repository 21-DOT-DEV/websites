<!--
Delete this comment before committing.

The ordered work — add this file when the task set has dependency waves or
review slices that a flat `## Tasks` list in plan.md would hide. Rules:

  * No frontmatter, no `status` field — plan.md alone carries those.
  * Tasks are TNNN (e.g. T001) in dependency order. One checkbox is one
    reviewable change — one commit-shaped unit of work.
  * `[P]` marks a task with no prerequisites — free to pick up early or in
    parallel.
  * Group headers name the review slice — the section of the diff a
    reviewer reads in one pass — and each group closes on a
    **Checkpoint:** line stating what must be true before the next slice
    starts.
  * An authored diff over ~300 changed lines per commit or pull request
    gets split, or the task justifies in-line why it cannot be — ~300 is
    the midpoint of the documented 200–400 review-effectiveness band;
    the count is per commit/PR, not the whole working tree. Generated
    output (lock files, bulk deletions, mechanical sweeps) is exempt. A
    coherent document set that can't be split — a spec and its companions
    landing together — is a legitimate justification; name it in the PR
    description.
  * If the spec ships as more than one pull request, say so here and name
    the boundaries; inside a PR, commit order follows group order so
    `git log` reads the same way.
  * Cite requirements as `FR-NNN` / `SC-NNN` when spec.md exists.
  * Tick the box in the same change that lands the task.
-->

# Tasks — NNN · <title>

Ordered work for [the plan](./plan.md); requirements cited as `FR-NNN` from
`spec.md` when it exists; evidence in `research.md` when the spec has one.

Format: `- [ ] TNNN [P?] what lands · files`. <One line on how this spec's
tasks decompose.>

## <Group name — the review slice>

- [ ] T001 [P] <what lands> · `path/to/file`
- [ ] T002 <what lands> · `path/to/file`

**Checkpoint:** <what is verifiably true when this group closes>.
