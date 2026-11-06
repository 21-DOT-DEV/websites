# Roadmap Prioritization — Research Snapshot

**Purpose:** Preserve the evidence-based ranking that drove the Roadmap v1.4.0
refactor — a point-in-time record of what was evaluated, how it scored, and
where each item landed. The living ordering is the Priority Tiers table in
`Roadmap/README.md`; this document is the snapshot behind it and is not kept
in sync — if the two disagree, the README wins.

**Date:** 2026-11-05
**Method:** Enumerated every feature across phases 1–8 plus `backlog.md`,
reconciled each against shipped code, then scored on value, effort, and
unblocking potential against five stated priorities (SEO/GEO + AI crawlers →
performance → server-side analytics → Swift WASM demos → DesignSystem).
External research covered static-site search (Pagefind), accessibility CI
(axe), Core Web Vitals measurement (CrUX vs Lighthouse vs RUM), server-side
analytics on Cloudflare Pages, HTTP/2 Push deprecation, sitemap `changefreq`/
`priority` efficacy, AI/GEO verification primitives, and Swift→WASM toolchain
feasibility.

## Decisions that shaped the ranking

Four open questions resolved before scoring, with the maintainer:

1. **Structure:** hybrid — phase numbers are stable identifiers (never
   renumbered, ADR/RFC/`Specs/NNN` convention); `Roadmap/README.md` is the
   authoritative ordering via Now/Next/Later tiers. WASM got the next
   appended number (Phase 9).
2. **Analytics:** edge/server-side now; self-hosted Plausible demoted to a
   contingent fallback (it's a client beacon — contradicts the server-side
   priority). Privacy policy stays; edge collection still processes
   IP-derived data.
3. **WASM:** new Phase 9 — pipeline feature, then a P256K in-browser demo
   (the package is already WASM-ready; needs a new `Package.swift` entry +
   WASM build pipeline + scoped toolchain exception).
4. **GEO:** verify-first — Phase 3 F11 extends `util agent-directive audit`
   (retrieval-vs-training `robots.txt` policy, `llms.txt` link health,
   JSON-LD, freshness) plus a documented Cloudflare AI Crawl Control review.
   `llms.txt`/`context7.json` recorded as deployed optionality, not proven
   value — Ahrefs measured ~97% of `llms.txt` files never fetched; the
   *proven* surface is retrieval-crawler access, semantic HTML, JSON-LD,
   and speed.

## Top 20 — value vs. effort

| Rank | Item | What it fixes or unlocks | Effort | Value | Source | Landed |
|---|---|---|---|---|---|---|
| 1 | `util links check` | Blocking internal-link check on generated HTML; kills the stale-link regression class. Spec'd incl. srcset expansion, %-decoding, query/fragment stripping | S–M | Very High | Phase 3 F9 → `Specs/006` | Now |
| 2 | `util redirects verify` | Parses `_redirects` + verifies preview deploys per rule; replaces hand curl checks; last feature closing Phase 2 | S–M | Very High | Phase 2 F2 → `Specs/007` | Now |
| 3 | `security.txt` | RFC 9116 vulnerability-disclosure metadata; completes the security-header posture | XS | High | Phase 3 F7 | Now |
| 4 | CWV field baseline | CrUX + Search Console + PSI readings *before* optimizing — targets effort at measured, not assumed, problems | S | Very High | Phase 3 F3 | Now |
| 5 | 21.dev asset hashing | `/static/style.css` is unversioned; content-hash or `?v=` URLs + `immutable` enable year-cache (docs site already does this for hashed DocC assets) | S–M | High | `backlog.md` | Now |
| 6 | FR/SC citation checks | CI gate so plan↔spec requirement references can't silently rot; the earned-companion convention depends on it | M | High | `backlog.md` | Next |
| 7 | Performance budgets (`util build verify`) | Machine-checked size/perf gates in CI; makes wins permanent instead of aspirational | M | High | Phase 3 F8 | Now |
| 8 | `actionlint` workflow validation | Catches GitHub Actions drift at lint time, pre-push | XS | Medium | Phase 7 F7 | Next |
| 9 | 21.dev Pagefind search | Site search after the DocC-search descope; indexes generated HTML, zero server; strict CSP needs `wasm-unsafe-eval` handling | M | Medium-High | Phase 5 F3 + `backlog.md` | Next |
| 10 | Mobile-usability audit | Search Console Mobile Usability reading *before* scoping work — `SiteHeader` already has a hamburger menu; the original "mobile is difficult" premise is unverified | XS | Medium | Phase 5 F4 | Next |
| 11 | a11y audit + axe CI | WCAG 2.2 AA verification + regression gate; automated testing complements, never replaces, manual review | M | High | Phase 5 F6/F7 | Later |
| 12 | `links check --external` | Scheduled, non-blocking external-link scan; needs bot-handling (contact UA, HEAD→GET fallback, retries, severity grading) before it reports honestly | M | Medium | `backlog.md` (F9 follow-up) | Next |
| 13 | 103 Early Hints | Browser-supported replacement for dead HTTP/2 Push; the `Link:` header infra already exists in `_headers.prod` | S | Medium | `backlog.md` | Now |
| 14 | Uptime + client-error monitoring | External uptime check + JS-error visibility | S | Medium | `backlog.md` | Next |
| 15 | CWV optimization work | The actual fixes — sequenced *after* #4, so effort goes where field data says it's needed | M+ | High (contingent) | Phase 3 F3 | Now |
| 16 | `development-docs.yml` required check | Docs-index gate becomes merge-blocking | XS | Medium | `backlog.md` | Next |
| 17 | Social proof (stars/downloads) | Package credibility signals on the site | XS | Low-Med | Phase 3 F10 | Later |
| 18 | a11y quick wins | Skip-nav, reduced-motion, focus indicators — cheap, independent of the full audit | S | Medium | Phase 5 F7 | Next |
| 19 | RSS feed | Programmatic access; also GEO-adjacent (machine-readable content surface) | M | Medium | Phase 5 F1 | Later |
| 20 | DesignSystem token expansion | The gate for dark mode, layout library, and most Phase 8 component work | M–L | High (enabler) | Phase 4 F1 | Later |

*Abbreviations: CWV = Core Web Vitals; CrUX = Chrome UX Report (real-user
field data); PSI = PageSpeed Insights; GEO = generative-engine
optimization; F*n* = Feature *n* in the named phase file.*

## Evaluated and held below the cut

| Item | Why it ranks lower or is deferred |
|---|---|
| Full dark mode (Phase 6) | Gated by #20 token expansion — no earlier slot is honest |
| Documentation versioning (Phase 7) | No established need for multiple major versions yet |
| Sitemap index generation (Phase 7 F4) | Per-subdomain sitemaps already ship; marginal at current scale |
| Sitemap `changefreq`/`priority` | **Likely Won't-Do** — Google ignores both fields (Phase 2's own backlog note); Phase 7 F6 annotated accordingly |
| i18n scaffolding | English-only site; no demonstrated demand |
| Phase 8 cluster (forms, feedback, living style guide, visual regression, comments, editorial workflow, local-dev docs, component analytics) | Gated by contributors, traffic, or DesignSystem maturity that doesn't exist yet |
| Blog tags/comments | The blog has one post |
| SRI hashes | No significant third-party CDN assets to pin |
| Brotli compression | Cloudflare already negotiates it — verify, don't build |
| Newsletter, testimonials, community features | Growth-dependent; premature at current traffic |
| Critical CSS / extensive resource hints | Traffic and complexity don't justify ahead of items 1–20 |
| HTTP/2 Server Push | **Dead tech** — removed from Chrome 106 / Firefox 132, deprecated by Cloudflare. Replaced by #13 |
| Self-hosted Plausible | Contradicts the server-side priority — rescoped to edge analytics (Phase 7 F1); kept as contingent fallback in `backlog.md` |

## Standing note

Rankings are a snapshot of 2026-11-05 evidence. Re-rank when: a Now-tier item
ships, field data (#4) reveals a different performance story, or the AI-GEO
evidence base changes (the `llms.txt` value question especially — revisit if
major platforms commit to reading it).
