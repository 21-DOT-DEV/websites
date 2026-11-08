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
  reference matching a rule's source as valid when the edge would
  answer it. Source matching implements Cloudflare's documented
  syntax — one `*` splat greedily matching any characters anywhere in
  the source, `:placeholder` segments each matching exactly one path
  segment, literal text otherwise; when several sources match, the
  first rule in file order governs (the edge applies the top-most
  match). A rule's effective status decides the exemption — a
  supported redirect status (`301`, `302`, `303`, `307`, `308`)
  exempts outright (the edge answers with a redirect); `200` exempts
  only when its substituted target itself resolves on disk, without
  re-applying `_redirects` (the edge serves the target's content and
  does not chain proxies); any other declared status grants nothing.
  A rule whose target loops back through its own source applies to
  nothing and exempts nothing: a `3xx` target re-requested under the
  same pattern, a `200` proxy target whose canonical form
  (`x/index.html` → `x/`, `x.html` → `x`) re-matches — proxy fetches
  never re-run `_redirects` otherwise — or a catch-all proxying the
  site root, the SPA-shell fallback. A source that fails to compile
  (more than one `*`) can never match. An absent status column
  defaults to `302`, so an undeclared rule exempts like any
  supported redirect.
- **FR-006** Skips without checking: URLs with any scheme
  (`https?://`, `mailto:`, `tel:`, `data:`, `javascript:`),
  protocol-relative `//` URLs, fragment-only `#x` references, and empty
  attribute values; fragments are never checked for target existence.
- **FR-007** Reports each broken reference with its source file, raw
  attribute value, resolved path, and reason; files that cannot be
  parsed are counted as skipped and named in warnings; prints checked
  and skipped totals; exits non-zero when any internal reference
  fails to resolve.
- **FR-008** The CLI accepts `--path <dir>` (must exist and be a
  directory) and `--verbose` (lists every checked reference per file).

## Measurable outcomes

- **SC-001** `build-slipstream.yml` and `generate-docc.yml` run
  `util links check` after site generation; a broken internal reference
  fails the workflow before deploy.
- **SC-002** Zero false positives on real generated output across both
  generated sites (21-dev, docs-21-dev).
- **SC-003** A full run completes in under 2 minutes on the largest
  site (~4,000 HTML files).

## Edge cases

- **Percent-encoded paths** — decoded before resolution so
  `My%20File.html` matches `My File.html` on disk.
- **`srcset` candidates** — each URL checked; descriptors (`1x`, `2x`,
  `800w`) are not URLs.
- **Redirect splat and placeholder sources** — a rule
  `/p256k/*/index.html /documentation/p256k/:splat/ 301` exempts
  `/p256k/anything/index.html`: the splat is not required to end the
  source, matching the edge's greedy `.*` semantics; `:placeholder`
  segments each match exactly one segment.
- **Redirect status handling** — a supported redirect status (`301`,
  `302`, `303`, `307`, `308`) exempts because the edge answers with a
  redirect regardless of what the target serves; a `200` proxy rule
  exempts only when its substituted target also resolves on disk —
  `_redirects` is not re-applied to the rewrite (the edge does not
  chain proxies); other declared statuses — including unsupported
  `3xx` codes like `300`, and non-redirect codes like `404` — exempt
  nothing; an absent status column defaults to `302` and exempts like
  any supported redirect.
- **Overlapping redirect sources** — the first matching rule in file
  order governs: `docs-21-dev`'s file places `/p256k/*/index.html`
  before the catch-all `/*/index.html`, so `/p256k/x/index.html`
  follows the p256k rule — verified live, it `301`s to
  `/documentation/p256k/x/`.
- **Non-canonical URL forms** — `/file/` resolving through `file.html`
  or `/dir` through `dir/index.html` count as valid because Pages
  redirects non-canonical spellings to the canonical URL rather than
  404ing (the documented direction: `/contact.html` → `/contact`,
  `/about/index.html` → `/about/`). The question answered is "would
  the edge serve this URL," not "is this the canonical spelling" —
  canonical form is `util canonical`'s concern.
- **SPA fallback not honored** — Pages documents serving the site
  root for unmatched paths on projects without a top-level
  `404.html`; a reference that would only "resolve" through such a
  shell still reports broken — the shell is not the page.
- **Unparseable HTML** — a file that cannot be read or parsed is
  counted as skipped and named in a warning, never dropped silently —
  a quiet skip would let a parse regression green the gate; the check
  verifies servable markup, not markup validity. A directory whose
  every file fails to parse exits non-zero like an empty scan.
- **Root config files are not assets** — `_redirects`, `_headers`,
  `_routes.json`, and `_worker.js` sit in the output root but the
  edge never serves them, so a link to one reports broken even though
  the file is on disk. The same name under a subdirectory is an
  ordinary file and is served.
- **URL normalization follows WHATWG** — ASCII tab/newline are
  removed from attribute values and `\` resolves as `/` (special-scheme
  rule), so `a\b` checks `a/b` and `\\host` counts as protocol-relative.
  Percent-decoding is per-segment after splitting on `/`: `%2F`/`%5C`
  inside a segment are *not* separators (the edge requests the encoded
  path), so a segment decoding to one reports broken rather than
  resolving to a different file; `%2e`-style encoded dots still
  normalize. A query-only `?x` reference resolves to the containing
  page itself.
- **Deliberate catch-all proxies are honored but named** — a `200`
  catch-all like `/* /shell` genuinely serves at the edge, so matching
  references count as resolved — but it also masks the entire gate, so
  the scan emits a warning naming the rule. The refusal model covers
  only the ambient root-proxy SPA-fallback shape (`/* /`/`/index.html`),
  not deliberate shell proxies.
- **Dot-directories are not scanned** — the shared walker skips
  hidden paths (`.skipsHiddenFiles`), so HTML under `.well-known/` or
  other dot-directories goes unchecked while CF does serve it.
  Generated output emits no such files today; revisit if that
  changes.
- **Case-insensitive filesystems** — `FileManager` follows the
  volume's case semantics, so on case-insensitive APFS (local dev and
  the macOS CI runners) a link whose case differs from the file's
  still passes even though the edge serves paths case-sensitively. A
  case-mismatched link is a latent false pass until checked on a
  case-sensitive volume.
- **Pages Functions** — both sites run `_middleware.ts` on every HTML
  route (`_routes.json` includes `/*`), and `_redirects` does not
  apply to responses a Function *serves*. The exemption premise holds
  because every current handler delegates to `context.next()`, so
  HTML requests reach the asset pipeline where `_redirects` is
  evaluated — verified live: `/p256k/x/index.html` returns `301`
  through docs-21-dev's middleware. Today's only Function-served
  response is docs-21-dev's `Accept: text/markdown` negotiation —
  outside the checker's HTML-link model; a handler that starts
  serving HTML paths directly would bypass `_redirects` for those
  paths — revisit the exemption premise if one stops delegating.
- **Out-of-root relative escape** — `../../x` past the output root is
  broken, not silently clamped.

## Assumptions and dependencies

- Runs after site generation, against the output directory — a pure
  filesystem check; no server, no network, no deploy needed.
- Directory-style URLs are served by directory index (`index.html`),
  matching Cloudflare Pages static serving.
- External-link health is deliberately out of scope — deferred to a
  future `--external` scheduled scan (see `research.md` for why
  external checks can never gate).
