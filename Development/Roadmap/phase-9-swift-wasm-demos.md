# Phase 9 — Swift WASM Demos

**Status:** Not Started
**Priority:** Medium-High (stated product priority — interactive demonstrations of the org's own packages)
**Last Updated:** 2026-11-05

## Phase Goal

Demonstrate the organization's packages running client-side in the browser via WebAssembly — flagship proof that the libraries are real, portable, and usable — delivered through a reproducible Swift→WASM build pipeline.

## Features

### Feature 1 — WASM Demo Build Pipeline
- **Name:** WASM Demo Build Pipeline
- **Status:** Not Started
- **Purpose & user value:** A repeatable path from a Swift package target to a deployed `.wasm` artifact + JS glue on 21.dev. Without the pipeline, each demo is a one-off; with it, additional package demos become configuration.
- **Success metrics:**
  - A demo target/product exists in `Package.swift` (or a standalone companion package outside the main build — decide in the spec)
  - Build step produces `.wasm` + JavaScriptKit glue and places artifacts into generated site output
  - CI builds the artifact reproducibly (pinned toolchain + WASM SDK) or fetches a pinned artifact — never silently skipped
  - Artifact is content-hashed and cached `immutable` (aligns with the 21.dev asset-hashing work in Phase 3)
  - Demo page loads the artifact on all three target browsers (Safari, Chrome, Firefox)
- **Dependencies:** None blocking. Relevant policy: embedded Swift → WASM requires the swift.org toolchain + WASM SDK — a scoped exception to the "Xcode-bundled toolchain only" rule, recorded in the feature spec; CSP needs `wasm-unsafe-eval` added to `script-src` for the demo page (or scoped CSP for the demo path).
- **Notes:** Keep the demo package's build out of the site's normal `swift build` path — a standalone manifest (the `Projects/`-style pattern the sister repos use) avoids slowing the main build and makes the toolchain exception explicit.

### Feature 2 — P256K In-Browser Demo
- **Name:** P256K In-Browser Demo
- **Status:** Not Started
- **Purpose & user value:** Visitors run real secp256k1 operations entirely client-side — generate a key pair, sign a message, verify a signature — powered by the actual `P256K` package compiled to WASM. The single most credible demo the org can ship: the flagship product executing in the browser with nothing sent to a server.
- **Success metrics:**
  - Demo page on 21.dev (e.g., `/demos/p256k/`) with a small interactive widget: key generation, sign, verify
  - All operations execute in-browser via the compiled WASM artifact — zero network calls (verifiable in dev tools)
  - Page states plainly what runs where ("running P256K x.y.z compiled to WASM; nothing leaves your browser")
  - Works on Safari, Chrome, Firefox at reasonable binary size (embedded-Swift output is ~70–100 kB compressed; WASI output is larger — choose per artifact-size budget)
  - Linked from the P256K package page as the "try it" surface
- **Dependencies:** WASM Demo Build Pipeline (Feature 1). `P256K` is already WASM-ready — it compiles for WASM today; the work here is packaging + UI, not porting.
- **Notes:** Keep the first widget deliberately small — one operation set, one page. Later candidates for the same pipeline (recorded in `backlog.md` when proven): other org packages' client-side demos, interactive docs examples.

## Phase Dependencies & Sequencing

- Feature 1 (pipeline) → Feature 2 (P256K demo).
- Independent of all other phases; DesignSystem provides page chrome but is not a blocking dependency.
- Aligns with Phase 3 asset-hashing (hashed `.wasm` artifacts get `immutable` caching) and Phase 3 Feature 11 (demo pages should stay crawler-parseable — WASM content needs a server-rendered fallback description for GEO anyway).

## Phase Metrics

This phase primarily contributes to product-level metrics for **Developer Trust**, **Package Adoption**, and **Technical Credibility**, especially:

- Demo page engagement (loads, interactions) via the edge-analytics baseline from Phase 7.
- Zero server-side computation for demo operations — everything client-side by construction.
- WASM artifact size kept inside the performance budget established by Phase 3 Feature 8.
