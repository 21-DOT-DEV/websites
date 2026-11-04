# Agent guide — `Sources/21-dev/`

The `21.dev` site executable target. Root `AGENTS.md` rules apply.

## Conventions

- Each page is a struct exposing a static `page` property; `@main` sits on
  `SiteGenerator` and the route dictionary lives in `SiteRoutes` (entries
  like `"packages/p256k/index.html": P256KPage.page`) — keep page content
  free of routing logic.
- Blog content lives in `Resources/21-dev/blog/` and is rendered by
  `BlogService`/`MarkdownRenderer`; post frontmatter and naming follow the
  existing files.
- Content style: semantic HTML, sufficient contrast, descriptive link text
  (no "click here"), complete runnable code samples, `alt` text on all images.
- Site-wide defaults (name, tagline, URLs) come from `Shared/SiteDefaults` —
  don't hardcode them in pages.
- Site-specific assets belong in `Resources/21-dev/`; anything shared goes up
  to `DesignSystem` instead.
- Stylesheets are linked relatively (`./static/style.css`); output lands in
  `Websites/21-dev/` and is never committed.
- New pages: file in `Pages/` (e.g. `Pages/P256K.swift` → `P256KPage`), struct
  with `static var page`, then a route entry in `SiteRoutes`' dictionary;
  verify with `nocorrect swift run 21-dev`.
- After generating, check output: `index.html` plus every route present,
  stylesheet refs relative (`./static/`), images carry `alt`, `charset`/
  `viewport`/`title` meta present, no broken internal links.
