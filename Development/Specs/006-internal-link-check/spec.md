# Spec — 006 · Internal link checking for generated HTML output

Feature 006 · Status lives in [plan.md](./plan.md) · Evidence in
[research.md](./research.md)

## Summary

After a site is generated and before it can deploy, every link, image,
stylesheet, and script reference in the generated HTML is resolved
against the files on disk. A reference pointing at nothing fails the
build with the source file and the broken target named — broken
internal links become commit-blockers instead of production 404s.
External URLs and non-HTTP references are skipped entirely; no network
is touched.

## User journey

A maintainer edits a page, generates the site, and CI runs
`util links check --path Websites/<site>` alongside the existing
post-generation steps (`canonical`, `links rewrite`, `agent-directive`).
Every internal reference is checked against the output on disk —
directory-style URLs resolve through their `index.html`, and paths a
`_redirects` rule will answer count as valid. A reference that resolves
to nothing stops the workflow before the site can deploy.

**Independent test:** point the command at any generated site
directory; it exits 0 when every internal reference resolves and
non-zero naming each broken one otherwise.

### Acceptance scenarios

1. **Given** generated HTML containing `<a href="/docs/guide/">` and a
   `docs/guide/index.html` on disk, **when** check runs, **then** the
   reference passes — covers FR-003.
2. **Given** `<a href="/missing">` with no file, directory index, or
   `_redirects` rule for `/missing`, **when** check runs, **then** it
   exits non-zero naming the source file and the broken `href` —
   covers FR-003, FR-007.
3. **Given** `<img src="photo.png">` in `blog/post.html` with
   `blog/photo.png` on disk, **when** check runs, **then** the
   reference resolves against the containing directory — covers FR-004.
4. **Given** `<a href="/old">` where `_redirects` declares
   `/old /new 301`, **when** check runs, **then** the reference counts
   as valid — the edge resolves it — covers FR-005.
5. **Given** `href` values `https://example.com`, `mailto:a@b.c`, and
   `#top`, **when** check runs, **then** all three are skipped and
   counted as skipped — covers FR-006.
6. **Given** `srcset` values with multiple candidates, **when** check
   runs, **then** each candidate URL is checked independently — covers
   FR-002.

## Functional requirements

- **FR-001** Recursively discovers every `.html` file under a supplied
  output directory in a deterministic, sorted order.
- **FR-002** Extracts link-bearing attribute values — `href`, `src`,
  and `srcset` (each candidate URL in the set) — from parsed HTML.
- **FR-003** Resolves each internal reference against the output root:
  exact file, `path/index.html` (directory index), and `path.html`;
  percent-decoded; query strings and fragments stripped before
  resolution.
- **FR-004** Resolves relative references against the containing file's
  directory; a reference escaping the site root is reported as broken.
- **FR-005** Parses `_redirects` at the output root and treats a
  reference matching a rule's source — literal or `*` splat — as valid
  (the edge answers it).
- **FR-006** Skips without checking: URLs with any scheme
  (`https?://`, `mailto:`, `tel:`, `data:`, `javascript:`),
  protocol-relative `//` URLs, fragment-only `#x` references, and empty
  attribute values; fragments are never checked for target existence.
- **FR-007** Reports each broken reference with its source file, raw
  attribute value, resolved path, and reason; prints checked and
  skipped totals; exits non-zero when any internal reference fails to
  resolve.
- **FR-008** The CLI accepts `--path <dir>` (must exist and be a
  directory) and `--verbose` (lists every checked reference per file).

## Measurable outcomes

- **SC-001** `build-slipstream.yml` and `generate-docc.yml` run
  `util links check` after site generation; a broken internal reference
  fails the workflow before deploy.
- **SC-002** Zero false positives on real generated output across all
  three sites (21-dev, docs-21-dev, md-21-dev).
- **SC-003** A full run completes in under 2 minutes on the largest
  site (~4,000 HTML files).

## Edge cases

- **Percent-encoded paths** — decoded before resolution so
  `My%20File.html` matches `My File.html` on disk.
- **`srcset` candidates** — each URL checked; descriptors (`1x`, `2x`,
  `800w`) are not URLs.
- **Redirect splat sources** — a rule `/*/index.html /:splat/ 301`
  exempts `/anything/index.html`, matching the edge's own behavior.
- **Out-of-root relative escape** — `../../x` past the output root is
  broken, not silently clamped.
- **Redirect-source approximation** — source matching is best-effort
  and only ever *grants* an exemption; it can hide a genuinely broken
  link the edge would also answer, which is acceptable (both see a
  working path).

## Assumptions and dependencies

- Runs after site generation, against the output directory — a pure
  filesystem check; no server, no network, no deploy needed.
- Directory-style URLs are served by directory index (`index.html`),
  matching Cloudflare Pages static serving.
- External-link health is deliberately out of scope — deferred to a
  future `--external` scheduled scan (see `research.md` for why
  external checks can never gate).
