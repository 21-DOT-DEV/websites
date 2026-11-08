# Research — 006 · Internal link checking for generated HTML output

Evidence and rejected alternatives for [the plan](./plan.md). Spec in
[spec.md](./spec.md).

## 1. Why a build step, not a crawler — the DocC model

**Decision: resolve internal references against generated output on
disk, at build time. No HTTP, no server, deterministic.** Apple's own
documentation pipeline sets the precedent: DocC resolves symbol and
article links at documentation-compile time, and the swiftlang
"soundness" CI job runs
`swift package generate-documentation --analyze --warnings-as-errors`
so a broken internal reference fails the build with zero network
involvement. The generated-HTML analog is the same check one level
later: parse the emitted files and resolve every `href`/`src`/`srcset`
against the output root.

The major static-site platforms go further than a CI gate — broken
internal links are a *build error*:

- **Docusaurus** ships `onBrokenLinks: 'throw'` as the default —
  `docusaurus build` aborts on any broken internal link ("to ensure you
  never ship any broken link"), and `onBrokenAnchors` does the same for
  `#fragment` targets.
- **Astro/Starlight**'s `starlight-links-validator` (~266k weekly
  downloads) fails `astro build` on unresolved internal links and
  explicitly *skips* external URLs, `mailto:`, and anchor-only links.
- **VitePress** has dead-link checking built in
  (`ignoreDeadLinks` for opt-out).

Internal integrity is deterministic — the file either exists or it
doesn't — so every failure is the author's own to fix. That is what
makes a blocking step fair.

## 2. Internal-only, external deferred — the flakiness data

**Decision: the blocking check covers internal references only;
external links go to a future `--external` scheduled scan.** The
operations literature is unanimous that external probes don't belong in
a gate: one measured first sweep against a docs site returned ~38%
false positives — bot-blocking (403), rate limits (429), dropped HEAD
requests — none of them the commit's fault. Getting honest numbers
required a contact-bearing user agent, accepting 429, per-domain
exclusions, HEAD→GET fallback, and treating only 404/410/DNS-failures
as errors. That machinery is exactly what a blocking path must not
depend on, which is why the standard split is `lychee --offline` as a
PR gate plus a weekly external sweep that files an issue rather than
failing. The backlog entry records this as
`util links check --external` — never a required check.

## 3. Own checker vs. adopting a tool

**Decision: implement in `UtilLib` behind `util links check`, not
lychee/htmlproofer/linkinator.** Alternatives considered:

- **lychee** — the standard link checker; but its `--offline` mode
  still reasons about URLs against a base, needs a site origin
  convention per project, and brings a Rust toolchain into a SwiftPM
  repo. The check needed here is narrower: files on disk.
- **htmlproofer** — the filesystem-resolution model matches exactly
  (`disable_external`), but adds a Ruby toolchain.
- **linkinator** — Node equivalent; same toolchain objection.
- **Playwright/curl crawls** — require a running server; the check's
  whole point is that it needs none.

The deciding factors: `SwiftSoup` is already a `UtilLib` dependency
(used by `LinkRewriter`), `HTMLFileWalker` already discovers generated
HTML, and the `check`-vs-`fix` command shape is established
(`canonical check|fix`, `links rewrite`). A ~200-line checker on
existing primitives beats a new toolchain dependency — and it can do
the `_redirects`-exemption correctly, which no off-the-shelf tool knows
about.

## 4. The `_redirects` exemption — edge-resolved paths aren't broken

**Decision: links matching a `_redirects` rule's source count as valid
when the edge would answer them.** Without this, every legitimate link
to a redirected path (e.g. `/docs` → the docs site) reports broken —
the file provably doesn't exist, yet the URL works because the edge
answers it.

The matcher implements Cloudflare's documented source syntax rather
than an approximation: a `*` splat compiles to a greedy `.*` anywhere
in the source — the real `docs-21-dev` file already uses a mid-path
splat (`/p256k/*/index.html`) that a suffix-only matcher would miss —
and `:placeholder` segments each match exactly one `[^/]+` segment.
Exemption is status-aware because that is what the edge honors: rules
declaring a supported redirect status (`301`, `302`, `303`, `307`,
`308`) always grant (a redirect answers the link even when its target
is absent), `200` proxy rules grant only when the substituted target
resolves on disk — the edge serves the target's content at the source
path and does not chain proxies — and statuses the edge ignores,
including unsupported `3xx` codes, grant nothing. An absent status
column defaults to `302`, so an undeclared rule exempts like any
supported redirect. When several rules match, the first in file order
governs — the edge applies the top-most match (`docs-21-dev` places
`/p256k/*/index.html` ahead of `/*/index.html`; verified live that
`/p256k/x/index.html` follows the p256k rule, `301` to
`/documentation/p256k/x/`).

The exemption's premise was also verified against the sites' Pages
Functions: both sites run `_middleware.ts` on `/*` routes, and
`_redirects` does not apply to responses a Function serves — but
every current handler delegates via `context.next()` to the asset
pipeline where `_redirects` is evaluated (the same live `301` above
passed through docs-21-dev's middleware; 21-dev's
`/.well-known/nostr.json` likewise returns `200` through its `200`
proxy rule).

Loop refusal models Wrangler/Pages deploy error 10021 verbatim —
"Infinite loop detected in this rule and has been ignored. This will
cause a redirect to strip `.html` or `/index` and end up triggering
this rule again" (cloudflare/workers-sdk#11824). Canonicalization
(`x/index.html` → `x/`, `x.html` → `x`) is the loop mechanism; the
spec-mandated catch-all-to-root refusal is a checker policy on top.

The same parser (`RedirectRule.swift` / `RedirectsParser` in
`Sources/UtilLib/Links/`) is shared with Specs/007's `redirects
verify`, which checks the rules themselves — whichever feature lands
first provides it, and both plans describe consuming it.

## 5. What stays out

- **Fragment existence** (`#section` → does the anchor exist?) —
  Docusaurus checks this via `onBrokenAnchors`; left out of v1 because
  it needs heading-ID extraction across generators. Candidate for a
  later flag.
- **External scan** — deferred; see §2 and the backlog entry.
- **Production sweeps** — the check runs on generated output before
  deploy; it is a prevention gate, not monitoring.
