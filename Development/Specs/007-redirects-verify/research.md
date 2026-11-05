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
is emitted). Destinations may be paths or absolute external URLs and
may contain `:placeholder`s and splats.

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
  fixed.
- **Parse-only validation** (`wrangler`/`parseRedirects` offline) —
  proves the file is well-formed, says nothing about whether rules
  *fire* — the silent-drop and Functions-bypass modes pass it.
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
- **Non-3xx wildcard rules (rewrites)** — **cannot be proven by
  request**: a probe `/.well-known/<token>` returns 404 whether the
  rewrite ran or not (the rewritten target doesn't exist either way).
  Reported as *skipped* with a stated reason — honest coverage beats a
  false pass. (FR-004.)
- **HEAD vs GET** — HEAD suffices for status+`Location`; GET fallback
  on 405/501 for completeness. No evidence Pages refuses HEAD.
- **Pages Functions caveat** — `_redirects` does not apply to requests
  served by Functions; if middleware owns a path the rule won't fire
  and verify reports it. That is correct behavior: the file's
  declaration is not the deployment's behavior.

## 5. What stays out

- **Ordering/limit lint** — warning on static rules after a dynamic
  one, or counting against the 2,000/100 budgets, is a cheap future
  addition to the parser but a lint, not a verification.
- **Production sweeps** — verification runs on previews (mirroring the
  existing `deploy-to-production == false` gate); scheduled prod checks
  belong to external monitoring.
- **www → apex** — lives in Cloudflare Rules (dynamic expressions
  `_redirects` can't express); out of scope.
- **Chains** — only the first hop is asserted; each rule's own check
  covers the next hop.
