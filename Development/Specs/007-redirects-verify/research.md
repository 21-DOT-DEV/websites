# Research — 007 · Verify _redirects rules against deployed URLs

Evidence and rejected alternatives for [the plan](./plan.md). Spec in
[spec.md](./spec.md).

## 1. `_redirects` file semantics — what the file actually promises

Cloudflare Pages parses `_redirects` line-by-line as
`[source] [destination] [code?]`: `#` comments, blank lines ignored, one
rule per line, each declaration ≤1,000 characters. **The default code
is 302**, not 301 — an omitted status is a temporary redirect.
Permitted codes: 200, 301, 302, 303, 307, 308 — where 200 is a *rewrite*
(the destination's content is served under the source URL; no redirect
is emitted). Rewrites beyond 200 are not supported: a rule declaring
e.g. `404` is ignored by the edge, not served (per the advanced-redirects
table, which lists non-200 rewrites as unsupported). Destinations may be
paths or absolute external URLs and may contain fragments, query
strings, `:placeholder`s and splats.

Matching is anchored and literal: a splat `*` compiles to `.*` (may be
empty), a placeholder `:name` to `[^/]+` (never a slash), and the whole
source to `^…$`. Sources never see the fragment (browser-evaluated);
query strings on sources are not matched. Limits: 2,000 static + 100
dynamic rules per file (2,100 total).

Two behaviors make live verification tractable:

- **Rules fire regardless of asset existence** — "redirects are always
  followed, regardless of whether or not an asset matches the incoming
  request" — so a probe path can never hit a real page instead of the
  rule; splat probes are safe by construction.
- **First match wins** — the top-most matching rule applies, so a
  verification request observes the same resolution the edge applies.

## 2. The positional-classification pitfall — why file-derived checks matter

The Cloudflare parser (`workers-sdk/parseRedirects.ts`) classifies
*positionally*, not per-rule: once a dynamic rule (containing `*` or
`:placeholder`) appears, `canCreateStaticRule` flips false permanently —
every subsequent rule counts against the 100-dynamic budget even if it
looks static. Past 100 dynamic rules the parser **breaks and silently
discards the file's tail** — a documented real-world failure (a large
file 404'd everything after ~120 rules with no build-time signal;
`workers-sdk` issue 14694).

Two implications:

- **Our own files already trip the positional rule, harmlessly** —
  `Resources/21-dev/_redirects` leads with `/.well-known/*` (dynamic),
  so `/docs` and `/api` count as dynamic. At ~3 rules total, no risk —
  but a future static rule appended *below* a splat is silently
  dynamic. The verifier doesn't lint ordering (out of scope), yet it
  catches the failure mode anyway: a silently-dropped rule fails
  verification as a 404.
- **Syntax-level validation cannot catch this** — `wrangler` reports
  invalid entries but surfaces nothing at deploy time; only observed
  behavior reveals a dropped rule.

## 3. Why verify behavior, not syntax — and the curl status quo

**Decision: assert observed responses (`status` + `Location`) for every
verifiable rule, derived from the file itself.** The status quo is two
hand-maintained curl blocks in `deploy-cloudflare.yml` — each tests a
fixed URL list that silently misses any rule nobody remembered to add.
Deriving checks from `_redirects` makes coverage automatic (SC-002).

Rejected alternatives:

- **Keep the curl list** — the drift it already has is the bug being
  fixed. The current blocks assert only status codes, never `Location`
  — so they would pass even where a redirect points somewhere wrong.
- **Parse-only validation** (`wrangler`/`parseRedirects` offline) —
  proves the file is well-formed, says nothing about whether rules
  *fire* — the silent-drop and Functions-bypass modes pass it.
- **Warn on edge-ignored rules instead of failing** — wrangler's own
  posture: `pages deploy` surfaces invalid rules as named warnings
  (unsupported status, infinite loop, dynamic-limit overflow) and ships
  anyway; Netlify's Deploy Summary does the same. Deploy tooling warns
  because its job is to ship what it understands — a verifier's job is
  the opposite, so the same findings are escalated to failure with the
  refusal named. It also removes a false-pass corner: a declared `404`
  on a path that naturally 404s would "pass" a raw status assertion
  without the rule ever running.
- **lychee / link checkers** — they check that referenced *pages*
  exist; redirect-rule verification (status + `Location` equality) is
  a different problem they don't solve.
- **Bulk Redirects / Cloudflare Rules** — a different mechanism for
  larger rule sets; orthogonal to verifying `_redirects` as authored.
- **End-to-end browser tests** (Playwright) — a full runner for what
  HEAD requests already prove.

## 4. What a probe can and cannot prove

- **Literal rules** — request `base-url + source`; assert status equals
  the declared code and `Location` equals the declared target
  (normalized: relative targets resolve against the base URL, external
  targets asserted literally).
- **3xx wildcard rules** — substitute a fixed token for `*`/`:name` in
  both source and target, request the probe source, assert `Location`
  matches the probe-expanded pattern. Works because redirects fire
  regardless of whether the probed target exists.
- **Non-3xx wildcard rules (rewrites)** — a *fixed-token* probe can't
  prove them (`/.well-known/<token>` returns 404 whether the rewrite
  ran or not), but a *real-target* probe can — with two guards. The
  splat-expanded target must map to an existing file under the
  deployed output root (`Websites/<site>/`, not `Resources/<site>/` —
  the authored tree carries undeployed config and lacks generated
  content; see §6), and the probed source path must not itself be a
  deployed asset, else a `200` comes from the file and proves nothing.
  Under both guards a `200` on the source path is reachable only
  through the rewrite — confirmed live,
  `preview.21-dev.pages.dev/.well-known/nostr.json` → `200`. Otherwise
  the rule is reported as *skipped* with a stated reason — honest
  coverage beats a false pass. (FR-004.)
- **HEAD vs GET** — HEAD suffices for status+`Location`; confirmed live
  on both sites (status and `Location` both returned on every probe,
  including through docs-21-dev's middleware pass-through). GET
  fallback on 405/501 remains for completeness.
- **`Location` is echoed verbatim** — relative targets come back
  relative (`/documentation/p256k/`), absolute targets absolute
  (`https://docs.21.dev/documentation/`); no host rewriting. Observed
  on every live probe, splat-expanded values included.
- **Pages Functions caveat** — `_redirects` does not apply to requests
  served by Functions; if middleware owns a path the rule won't fire
  and verify reports it. That is correct behavior: the file's
  declaration is not the deployment's behavior. Two observed layers
  bound where that premise holds — see §6.

## 5. What stays out

- **Ordering/limit lint** — warning on static rules after a dynamic
  one, or counting against the 2,000/100 budgets, is a cheap future
  addition to the parser but a lint, not a verification.
- **Production sweeps** — verification runs on previews (mirroring the
  existing `deploy-to-production == false` gate); scheduled prod checks
  belong to external monitoring.
- **www → apex** — lives in Cloudflare Rules (dynamic expressions
  `_redirects` can't express); out of scope.
- **Zone-level shadows** — WAF, redirect, and page rules configured on
  the custom domain can override file rules entirely (observed: prod
  `21.dev/api` → `403` while the preview returns the declared `301`).
  Out of scope for the same reason production sweeps are — the preview
  deploy is where the file is the only redirect policy.
- **Chains** — only the first hop is asserted; each rule's own check
  covers the next hop.

## 6. Live observations (2026-11-08 probes)

Everything below was measured against the real deployments, and is the
evidence behind FR-004's real-target probes and the `--base-url`
guidance:

- `preview.21-dev.pages.dev/api` → `301`,
  `Location: https://docs.21.dev/documentation/` — the declared rule
  firing; preview per-deploy and branch-alias hosts run `_redirects`
  normally.
- `docs-21-dev.pages.dev/p256k` → `301`,
  `Location: https://docs.21.dev/p256k` — the apex project host is
  canonicalized by Functions' hostname redirect *before* `_redirects`
  is consulted. Pointing `--base-url` at an apex host fails every
  rule's `Location` check while measuring the wrong layer.
- `21.dev/api` → `403` across HEAD, GET, and browser UAs — a
  zone-level rule on the custom domain shadows the file's declared
  `301`; the same path on the preview host returns it. Real dogfood
  evidence for §4's Functions caveat, from one level higher in the
  stack.
- `preview.21-dev.pages.dev/.well-known/nostr.json` → `200` —
  proves the `/.well-known/*` rewrite: Pages doesn't serve
  dot-directories directly (a documented platform quirk — uploads
  drop hidden directories unless opted in), so a `200` on a dot-path
  is reachable only through the `200` rewrite. This is the FR-004
  real-target probe working end to end.
- `Resources/<site>/` is a source tree, not the deployed root —
  `SiteGenerator`'s excluded list drops `_headers.*`, `*.cjs`,
  `blog/`, `functions/`, `packages/` from the copy, and
  `Resources/docs-21-dev/` holds only config (`wrangler.toml`,
  `external-archives.json`, `theme-settings.json`) with none of the
  deployed DocC HTML. Real-target existence is therefore checked
  under `Websites/<site>/` — the generated tree wrangler actually
  uploads — with `--file`'s parent as the fixture escape hatch.
- `/.well-known/` is not free real estate — Cloudflare reserves
  `acme-challenge`/`pki-validation` sub-paths for domain-control
  validation and advises excluding `/.well-known/*` from custom rules;
  a fixed-token probe could land on a reserved sub-path, a real-target
  probe cannot.
- Edge caches responses, negative ones included — a reused hostname
  can serve a stale `404` over a live rule; the per-deploy
  `<hash>.pages.dev` origin starts empty, so verifying the per-deploy
  URL avoids the whole class.
