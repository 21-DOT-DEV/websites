# Contracts — external APIs

The four surfaces `util vitals` touches. Auth details live in
`CredentialStore` / `VitalsCommand`; this file pins the wire shapes.

Credential rule that applies to every surface: secrets travel in request
**headers**, never URL query strings — recorded error text lands in
committed `baseline.*` artifacts, and a `?key=` parameter inside a logged
URL would leak it.

## Cloudflare REST (Observatory, open beta) — `https://api.cloudflare.com/client/v4`

Auth: `Authorization: Bearer <CLOUDFLARE_API_TOKEN>` (token needs
**Zone → Settings → Write** to trigger tests and **Zone → Analytics → Read**
for the GraphQL query below — `httpRequestsAdaptiveGroups` is zone-scoped,
so Account-level Analytics Read does not cover it).

| Call | Purpose |
|---|---|
| `GET /zones/{zone}/speed_api/availabilities` | Plan quota + allowed regions |
| `POST /zones/{zone}/speed_api/pages/{url}/tests` body `{"region": "<region>"}` | Start a test; `{url}` is the full page URL percent-encoded into the path. Returns `result.id` |
| `GET /zones/{zone}/speed_api/pages/{url}/tests/{id}` | Poll until `desktopReport.state` and `mobileReport.state` are `COMPLETE`/`FAILED` |
| `POST /zones/{zone}/speed_api/schedule/{url}` | (Optional) create a recurring schedule — dashboard equivalent |

Envelope: `{"success": bool, "result": …, "errors": [{"code", "message"}]}`.
Each `*Report` is a `LighthouseReport`: `cls`, `fcp`, `lcp`, `performanceScore`,
`si`, `tbt`, `ttfb`, `deviceType`, `state`, `error{code,detail}`, `jsonReportUrl`.

## Cloudflare GraphQL — `POST https://api.cloudflare.com/client/v4/graphql`

Edge field timing, zone-scoped, per host, trailing window:

```graphql
query($zone: String!, $since: Date!, $host: String!) {
  viewer { zones(filter: {zoneTag: $zone}) {
    httpRequestsAdaptiveGroups(limit: 1, filter: {
      date_geq: $since,
      clientRequestHTTPHost_in: [$host],
      edgeResponseContentTypeName: "html"
    }) {
      count
      quantiles {
        edgeTimeToFirstByteMsP50 edgeTimeToFirstByteMsP95 edgeTimeToFirstByteMsP99
        originResponseDurationMsP50 originResponseDurationMsP95 originResponseDurationMsP99
      }
    }
  } }
}
```

Timing fields are plan-gated; absent permission/plan → recorded
`unavailable` with the error text, never a hard failure. The 28-day
window clamps to the dataset's per-plan `maxDuration`/`notOlderThan`
limits — the artifact's `windowDays` records the window actually queried.

## PageSpeed Insights — `GET https://www.googleapis.com/pagespeedonline/v5/runPagespeed`

Auth: `X-Goog-Api-Key: <GOOGLE_API_KEY>` header (key effectively required —
keyless quota is shared-IP and 429-prone).

Query: `url`, `strategy=mobile|desktop`, `category=performance`.

Reads `lighthouseResult.categories.performance.score` and
`audits.{largest-contentful-paint, cumulative-layout-shift,
total-blocking-time, first-contentful-paint, speed-index,
server-response-time}.numericValue`. `loadingExperience` sections are
parse-tolerant but ignored — Google is deprecating field data in PSI.

## Chrome UX Report — `POST https://chromeuxreport.googleapis.com/v1/records:queryRecord`

Auth: `X-Goog-Api-Key: <GOOGLE_API_KEY>` header (same Google key as PSI;
enable both APIs on the one project).

Body: `{"origin": "<origin>", "metrics": ["largest_contentful_paint",
"interaction_to_next_paint", "cumulative_layout_shift",
"first_contentful_paint", "experimental_time_to_first_byte"]}`

- HTTP 404 → `insufficient` (expected for both origins — recorded finding).
- HTTP 200 → `record.metrics.<metric>.percentiles.p75` per metric.
