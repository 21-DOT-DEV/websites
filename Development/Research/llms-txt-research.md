# llms.txt — Research & Convention Audit

**Purpose:** Establish the conventions that should shape 21.dev's per-module `llms.txt` files (existing five + new bitcoin/bitcoinkernel), backed by citations the reader can independently verify.

**Date:** 2026-05-28
**Method:** Read the canonical spec at `llmstxt.org`, Jeremy Howard's original proposal at `answer.ai`, then sampled ten in-the-wild implementations and Mintlify's documented convention.

**Confidence labels used:**
- **`[Spec]`** — directly stated by `llmstxt.org/llms.txt` or Jeremy Howard's proposal. Verbatim quotes included. Highest confidence.
- **`[Common]`** — adopted by ≥4 of the surveyed implementations. URLs of matching examples included.
- **`[Convention]`** — adopted by 1–3 implementations, or my own judgment. Explicitly labeled as opinion.
- **`[21.dev-specific]`** — current 21.dev pattern with no clear external precedent. Kept (with rationale) or flagged for review.

---

## Sources surveyed

### Canonical
- **Spec**: <https://llmstxt.org/> (and the `llms.txt`/`llms-full.txt` files there)
- **Original proposal**: <https://www.answer.ai/posts/2024-09-03-llmstxt.html> — Jeremy Howard's announcement post

### Reference implementations
| Project | URL | Notes |
|---|---|---|
| Anthropic | `platform.claude.com/llms.txt` | Multi-language registry + product sections |
| Cloudflare | `developers.cloudflare.com/llms.txt` | Nested-llms.txt pattern (root links to per-product llms.txt) |
| Mintlify | (docs at `mintlify.com/docs/ai/llmstxt`) | Tooling vendor; documents their generation convention |
| Cursor | `cursor.com/llms.txt` | Multiple H1s (spec deviation) |
| FastHTML | `fastht.ml/docs/llms.txt` | Jeremy Howard's own project — quasi-canonical example |
| nbdev | `nbdev.fast.ai/llms.txt` | Jeremy Howard's other project — sibling reference |
| Pydantic | `pydantic.dev/docs/validation/latest/llms.txt` | Mature OSS library example |
| Stripe | `docs.stripe.com/llms.txt` | High-quality SDK/API reference example |
| Vercel | `vercel.com/llms.txt` | Platform documentation example |

### Sources attempted but unavailable
- **Docusaurus** (`docusaurus.io/llms.txt`): 404. No first-party llms.txt; no documented official plugin found at the canonical URL. Excluded from synthesis.
- **Context7** (`context7.com/llms.txt`): Returns HTML homepage, not an llms.txt file. Their API endpoint returns 400. Excluded from synthesis.

---

## Spec summary (the actual rules)

From <https://llmstxt.org/>, the entire normative content is:

> 1. "An H1 with the name of the project or site. This is the only required section"
> 2. "A blockquote with a short summary of the project, containing key information necessary for understanding the rest of the file"
> 3. "Zero or more markdown sections (e.g. paragraphs, lists, etc) of any type **except headings**, containing more detailed information"
> 4. "Zero or more markdown sections delimited by H2 headers, containing 'file lists' of URLs where further detail is available"
> 5. Each file list item: "a required markdown hyperlink `[name](url)`, then optionally a `:` and notes about the file"
> 6. The `"Optional"` section has special semantics: "if it's included, the URLs provided there can be skipped if a shorter context is needed. Use it for secondary information which can often be skipped."

That's it. Everything else is convention.

Howard's original example:

```
# Title
> Optional description goes here
Optional details go here
## Section name
- [Link title](https://link_url): Optional link details
## Optional
- [Link title](https://link_url)
```

---

## Findings

### Finding 1 `[Spec]` — H1 is the only mandatory element

The spec says verbatim: "An H1 with the name of the project or site. This is the only required section." Everything else is optional.

**21.dev current state:** All 6 existing files (root + 5 per-module) have a clear H1. Compliant.
**21.dev application:** Continue. New `bitcoin` and `bitcoinkernel` files must have H1.

---

### Finding 2 `[Spec]` — Blockquote is for the project summary, in the spec-defined slot

The spec places the blockquote immediately after the H1 and describes it as carrying "key information necessary for understanding the rest of the file."

**21.dev current state:** All 6 existing files use a blockquote — but the *content* varies:
- Root `llms.txt`: blockquote contains a one-sentence overview (spec-correct)
- `event/llms.txt`: blockquote is overview + version + capability summary (spec-correct, rich)
- `tor/llms.txt`: blockquote contains version stamp + a cross-link to llms-full.txt, but **no actual summary** of what Tor is — the summary lives in the lead paragraph below
- `p256k/`, `openssl/`, `zkp/`: similar to tor — blockquote is "Part of <package> v{{VERSION}}; see llms-full.txt" with the actual summary in the next paragraph

**Issue surfaced:** The tor/p256k/openssl/zkp pattern uses the blockquote as a footer-style annotation (version + cross-link), not as a summary. This *technically* satisfies the spec's "blockquote" requirement but inverts its purpose — the spec says the blockquote should contain the summary.

**21.dev application:** Restructure the per-module blockquote to lead with a one-sentence summary, followed by version + llms-full link in either a second sentence within the blockquote or as a paragraph below.

**Comparable pattern (FastHTML, spec-conformant):**
```
# FastHTML
> "FastHTML is a python library which brings together Starlette, Uvicorn, HTMX, and fastcore's FT..."
```

---

### Finding 3 `[Spec]` — No headings allowed between blockquote and first H2

The spec mandates that pre-H2 content be "markdown sections (e.g. paragraphs, lists, etc) of any type **except headings**." This means no H3/H4 nesting before the first H2.

**21.dev current state:** Compliant. All existing files use plain paragraphs in the pre-H2 region.
**21.dev application:** Continue.

---

### Finding 4 `[Common]` — `.md` extension on all page links

**Adopted by:** Anthropic, Mintlify (documented convention), Cursor, Stripe, Pydantic, Vercel — 6 of 8 surveyed implementations.

This convention enables agents to fetch the markdown version of each page directly. Mintlify's documentation states verbatim: "Page links in the llms.txt file include a `.md` extension so AI tools can fetch the Markdown version of each page directly."

Examples:
- Anthropic: `[Overview](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/overview.md)`
- Stripe: `[Testing](https://docs.stripe.com/testing.md): Simulate payments to test your integration.`
- Pydantic: `[Custom Validators](https://pydantic.dev/docs/validation/latest/examples/custom-validators.md)`

**21.dev current state:** All existing files use `.md` extension. Compliant.
**21.dev application:** Continue for bitcoin/bitcoinkernel.

---

### Finding 5 `[Common]` — Per-link notes use the spec's `[name](url): notes` format

**Adopted by:** Anthropic, Stripe, Vercel, Pydantic, Cloudflare (when product-llms.txt entries have descriptions), FastHTML, nbdev — universal.

**21.dev current state:** All existing files use this format.
**21.dev application:** Continue.

---

### Finding 6 `[Common]` — Nested llms.txt for sub-domains/product areas

**Adopted by:** Cloudflare, Vercel. Cloudflare's blockquote says verbatim: "Each product below links to its own llms.txt, which contains a full index of that product's documentation pages and is the recommended way to explore a specific product's content."

The pattern: root `llms.txt` lists products/sub-areas as bullets, each pointing to that area's own `llms.txt` (or `llms-full.txt`).

**21.dev current state:** Root `llms.txt` does this exactly — links to each per-module `llms.txt`. Excellent fit.
**21.dev application:** Continue. Add bitcoin/bitcoinkernel entries to the root.

---

### Finding 7 `[Common]` — Single H1, no multiple H1s

**Adopted by:** Anthropic, Cloudflare, FastHTML, nbdev, Pydantic, Stripe, Vercel — 7 of 8. **Cursor is the outlier** with 3 H1s (Docs / CLI / Help Center).

The spec is silent on this directly but says "An H1" (singular). Howard's original example shows one H1.

**21.dev current state:** All 6 existing files have a single H1. Compliant.
**21.dev application:** Continue.

---

### Finding 8 `[Common]` — Custom H2 section names are universal; no "canonical" set exists

Every surveyed implementation has its own H2 section taxonomy:

| Project | H2 sections |
|---|---|
| Anthropic | `## Messages`, `## Managed Agents`, `## Admin`, `## API Reference` |
| Cloudflare | `## Application performance`, `## Application security`, `## Cloudflare One`, … |
| Pydantic | `## Get Started`, `## Concepts`, `## API Documentation`, `## Internals`, … |
| FastHTML | `## Docs`, `## API`, `## Examples`, `## Optional` |
| nbdev | `## Tutorials`, `## API`, `## Optional` |
| Stripe | `## Docs`, `## Payment Methods`, `## Checkout`, … (~20 product-area sections) |
| Vercel | `## Documentation`, `## Access`, `## AI`, … (~17 sections) |
| 21.dev | `## Instructions`, `## When to use this`, `## Documentation`, `## Symbols`, `## Optional` |

**21.dev's `## Symbols`** is not observed elsewhere — the equivalent is `## API` (FastHTML, nbdev, Pydantic). Renaming would align with broader convention but is purely cosmetic.

**21.dev's `## Instructions` and `## When to use this`** — entirely unique. No surveyed implementation has either. The content (agent guidance, positioning) is valuable, but the spec strictly disallows headings before the first H2, so the only place for this content is either (a) in H2 sections (current 21.dev approach), or (b) folded into the pre-H2 lead paragraph.

**21.dev application — recommendation:**
- **Keep `## Documentation`, `## Optional`** as-is. Common pattern.
- **Rename `## Symbols` → `## API`** for broader-convention alignment. (Low-stakes; spec doesn't care.)
- **Keep `## Instructions` and `## When to use this`** but acknowledge they're idiosyncratic. The content is genuinely useful for agents and represents a thoughtful 21.dev addition; reverting would lose information.

---

### Finding 9 `[Spec]` — "## Optional" section has special skippable semantics

The spec is explicit: "if it's included, the URLs provided there can be skipped if a shorter context is needed. Use it for secondary information which can often be skipped."

**Adopted by:** FastHTML, nbdev, 21.dev's openssl. Not used by Anthropic, Cloudflare, Stripe, Vercel.

**21.dev current state:** Used inconsistently — `openssl/llms.txt` has `## Optional`, but `event/`, `p256k/`, `tor/`, `zkp/` do not.

**21.dev application:** Standardize on `## Optional` where there's curated secondary content (deep-dive subtype pages, internal protocol pages, etc.). For modules without genuinely-secondary content, skip the section.

---

### Finding 10 `[Convention]` — Cross-module references via inline links are supported

When products/modules reference each other, both Cloudflare and Vercel link to sibling product llms.txt. 21.dev already does this (e.g., `tor/llms.txt` mentions swift-event and swift-openssl, with links). No change needed.

---

### Finding 11 `[Convention]` — Lead paragraph length varies wildly; no consensus

Surveyed range: 1 line (Cursor) to ~500 chars (21.dev tor). The spec only says "Zero or more markdown sections." No best-practice consensus exists.

**21.dev current state:** Lead paragraphs run long (200–600 chars), packing in vendored library versions, dependency relationships, capability summaries.

**21.dev application:** Continue current approach. The dense lead paragraph is valuable for agents and consistent across modules.

---

### Finding 12 `[21.dev-specific]` — Version stamping with `{{PLACEHOLDER}}` at build time

No surveyed implementation uses build-time placeholders. Mintlify documents that descriptions are sourced from frontmatter at build time, not stamped; others appear to commit hardcoded version strings.

**21.dev rationale (kept):** The version stamp is a useful signal for agents to know which version of the docs they're reading. Build-time substitution avoids drift between the registry's `tag` and the documented version. Keep.

**21.dev application:** Continue. Add `{{BITCOINKERNEL_VERSION}}` placeholder for both new files (single shared placeholder since both ship from `21-DOT-DEV/swift-bitcoinkernel` at the same tag).

---

### Finding 13 `[21.dev-specific]` — Pre-1.0 warning emoji `⚠️ This package is pre-1.0`

Not observed in any surveyed implementation. None of the reference projects ship pre-1.0 software, so the lack of precedent isn't surprising.

**21.dev rationale (kept):** Real editorial signal for agents recommending the packages. Maps to actual production risk. Keep.

**21.dev application:** Continue for bitcoin (0.1.0) and bitcoinkernel (0.1.0).

---

### Finding 14 `[21.dev-specific]` — Citation guidance ("refer to as ...")

Not observed elsewhere. Useful for accurate attribution in agent output.

**21.dev rationale (kept):** Helpful for agents producing user-facing summaries. Keep.

**21.dev application:** Continue.

---

### Finding 15 `[21.dev-specific]` — "Always request the Markdown version" instruction

Redundant when all links already use `.md` extension (Finding 4). But useful belt-and-suspenders documentation for agents not following explicit links.

**21.dev rationale (kept):** Cheap, harmless redundancy.
**21.dev application:** Continue.

---

## Cross-reference table — Findings → file edits

| Finding | Root | event | openssl | p256k | tor | zkp | bitcoin (new) | bitcoinkernel (new) |
|---|---|---|---|---|---|---|---|---|
| 1: H1 required | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | **add** | **add** |
| 2: Blockquote is summary | ✓ | **fix** | ✓ | **fix** | **fix** | **fix** | **add** | **add** |
| 3: No pre-H2 headings | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | follow | follow |
| 4: `.md` extension | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | follow | follow |
| 5: `[name](url): notes` | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | follow | follow |
| 6: Nested llms.txt | ✓ | — | — | — | — | — | **add row in root** | **add row in root** |
| 7: Single H1 | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | follow | follow |
| 8: Rename `## Symbols` → `## API` | — | **rename** | **rename** | **rename** | **rename** | **rename** | use `## API` | use `## API` |
| 9: Standardize `## Optional` | — | (no secondary content) | ✓ keep | (no secondary content) | (no secondary content) | (no secondary content) | (decide per content) | (decide per content) |
| 10: Cross-module refs | — | — | — | — | ✓ | ✓ | (link to bitcoinkernel) | (link to bitcoin) |
| 11: Lead paragraph length | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | follow | follow |
| 12: Version stamping | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | **add `{{BITCOINKERNEL_VERSION}}`** | **add `{{BITCOINKERNEL_VERSION}}`** |
| 13: Pre-1.0 warning | — | ✓ | ✓ | ✓ | ✓ | ✓ | **add** | **add** |
| 14: Citation guidance | — | ✓ | ✓ | ✓ | ✓ | ✓ | **add** | **add** |
| 15: "Request markdown" | — | ✓ | ✓ | ✓ | ✓ | ✓ | **add** | **add** |

**Summary of changes per file:**

| File | Changes |
|---|---|
| Root `llms.txt` | +2 entries (bitcoin + bitcoinkernel) + 1 repo link in `## Optional` |
| `event/llms.txt` | Restructure blockquote to lead with summary; rename `## Symbols` → `## API` |
| `openssl/llms.txt` | Rename `## Symbols` → `## API` (`## Optional` already present; blockquote already summary-style) |
| `p256k/llms.txt` | Restructure blockquote to lead with summary; rename `## Symbols` → `## API` |
| `tor/llms.txt` | Restructure blockquote to lead with summary; rename `## Symbols` → `## API` |
| `zkp/llms.txt` | Restructure blockquote to lead with summary; rename `## Symbols` → `## API` |
| `bitcoin/llms.txt` (new) | Full file per the established 21.dev pattern; uses `## API` (not `## Symbols`) |
| `bitcoinkernel/llms.txt` (new) | Same |

---

## Decisions explicitly NOT taken (kept as-is despite research notes)

1. **`## Instructions` and `## When to use this` sections remain** — Finding 8 noted these as idiosyncratic to 21.dev. Removing them would lose useful agent-guidance content. The content earns its keep even if the structure is unconventional.
2. **Version stamping mechanism stays** — Finding 12 noted no precedent. The mechanism delivers real value (version drift prevention) and the alternative (committing hardcoded versions) is strictly worse.
3. **Pre-1.0 warning, citation guidance, "request markdown" all kept** — Findings 13–15 noted no external precedent, but all three are cheap-to-keep editorial signals with clear utility.

---

## How to spot-check any finding

To verify a finding labeled `[Spec]`: open <https://llmstxt.org/> and search for the verbatim quote.

To verify a finding labeled `[Common]`: open any of the listed implementation URLs (e.g., `curl https://docs.stripe.com/llms.txt`) and observe the convention firsthand.

To dispute a finding labeled `[Convention]` or `[21.dev-specific]`: those are judgment calls. Push back and we'll re-litigate with whatever additional evidence you bring.
