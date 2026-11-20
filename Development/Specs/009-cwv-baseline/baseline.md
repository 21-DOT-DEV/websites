# CWV baseline — recorded observation

Regenerate with `nocorrect swift run util vitals baseline` *(lands with
spec 009's implementation — not yet in the tree)*. Do not edit by hand
below the GENERATED marker — the writer owns the status line there, so
this file can never disagree with `baseline.json`; maintainer-maintained
fields live above the marker.

## Maintainer-maintained readings

| Reading | Status | Date | Notes |
|---|---|---|---|
| Search Console CWV report — 21.dev | ☐ checked | — | dashboard-only, no API |
| Search Console CWV report — docs.21.dev | ☐ checked | — | expected "No data available" |
| Ahrefs Site Audit + PSI key — 21.dev | ☐ configured | — | scheduled crawl on |
| Ahrefs Site Audit + PSI key — docs.21.dev | ☐ configured | — | scheduled crawl on |
| Cloudflare beacon history (one-time GraphQL read) | ☑ declined by maintainer | 2026-11-19 | stays an available option — see `research.md` D2 |

## What's measured

| Source | Type | Covers | Notes |
|---|---|---|---|
| Cloudflare Observatory | lab | LCP, CLS, FCP, SI, TBT, TTFB, score × mobile/desktop, one region per page (~21 available; `--region` override) | REST API, plan quota |
| PageSpeed Insights | lab | same set | same API Ahrefs reads |
| CrUX API | field probe | origin p75 LCP/INP/CLS/FCP/TTFB | expected `insufficient` |
| Cloudflare GraphQL | field (edge) | TTFB + origin-response p50/p95/p99, 28-day | only edge-observable metric |

INP is proxied by TBT (passive lab cannot measure interaction); WebPageTest
scripted tests are the documented upgrade path if a page becomes
interactive. Thresholds judged at p75: LCP ≤ 2.5s · INP ≤ 200ms · CLS ≤ 0.1.

<!-- GENERATED — everything below is rewritten by `util vitals baseline` -->

**Status: PENDING — no credentialed run yet.**

*(pending — no measurements yet)*
