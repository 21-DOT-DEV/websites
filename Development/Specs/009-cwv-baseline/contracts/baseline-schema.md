# Contract — `baseline.json` schema (v1)

Machine-readable twin of `baseline.md`; emitted by `util vitals baseline`
(`--dry-run` emits `status: pending`). Not a `budget.json` — this file holds
**measured values**, thresholds are derived later (Phase 3 F8).

```jsonc
{
  "schemaVersion": 1,
  "generatedAt": "2026-11-19T00:00:00Z",      // null while pending
  "status": "pending | partial | complete",
  "origins": ["https://21.dev", "https://docs.21.dev"],
  "fieldData": {
    "crux": [                                // one per origin
      { "origin": "…", "status": "insufficient | available | error",
        "p75": { "lcpMs": 0, "inpMs": 0, "cls": 0, "fcpMs": 0, "ttfbMs": 0 } | null,
        "detail": "…" }
    ],
    "edgeTtfb": [                            // one per host
      { "host": "…", "windowDays": 28, "sampleCount": 0,  // windowDays: queried window; < 28 when plan-clamped, 0 when skipped
        "status": "available | unavailable",
        "p50Ms": 0, "p95Ms": 0, "p99Ms": 0,
        "originP50Ms": 0, "originP95Ms": 0, "originP99Ms": 0,
        "detail": "…" }
    ]
  },
  "lab": {
    "observatory": [                         // one per page
      { "url": "…", "testId": "…" | null, "region": "…", "error": null,
        "mobile":  { "metrics": { /* LabMetrics */ }, "error": null },
        "desktop": { "metrics": { /* LabMetrics */ }, "error": null } }
    ],
    "pagespeed": [                           // one per page
      { "url": "…",
        "mobile":  { "metrics": { /* LabMetrics */ }, "error": null },
        "desktop": { "metrics": { /* LabMetrics */ }, "error": null } }
    ]
  },
  "pageSet": ["…"],                          // resolved URL list actually measured
  "gaps": ["crux", "gsc-cwv", "inp-field"],  // recorded, not failures
  "notes": ["…"]                             // free-text findings
}
```

`LabMetrics` (all nullable — a failed test yields nulls, not a zero):

```jsonc
{ "lcpMs": 1840, "cls": 0.02, "tbtMs": 120, "fcpMs": 910,
  "speedIndexMs": 1450, "ttfbMs": 380, "performanceScore": 92 }
// any field may be null; score is 0–100
```

Both instruments' `mobile`/`desktop` entries carry `metrics` **and**
`error` so a failed call or report (HTTP error, malformed response, 429;
a `FAILED` Lighthouse report on one form factor) is attributable —
`metrics: null` + `error: "…"` — rather than indistinguishable from
absent data. Observatory's per-page `error` records test-level failures
(trigger refused, poll never completed); per-report `error` maps the
API's `error{code,detail}` when one form factor's report fails while the
other completes. `testId` is `null` on a refused trigger — a refused
`POST` returns no `result.id`.

Rules:

- `status` is `complete` only when every requested section has data or a
  recorded unavailability reason; `partial` when any page/section errored.
- Missing/absent metrics are `null`, never `0` — zero is a measurement.
- `gaps` uses stable ids — `crux` (no CrUX eligibility), `gsc-cwv` (no
  Search Console API), `inp-field` (no field INP) today; new ids are added
  as new gaps are recorded.
- New fields may be added; `schemaVersion` bumps only on breaking change.
