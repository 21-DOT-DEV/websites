# Agent guide — `Resources/`

Per-site assets: `Resources/<SiteName>/` mirrors the site it serves. Root
`AGENTS.md` rules apply.

## Conventions

- **Cloudflare config is source, not output.** `_headers.dev`/`_headers.prod`
  and `_redirects` are the editable policy; the build pipeline selects and
  copies the environment source to the deployed `_headers`, and `util headers
  validate` checks it — never edit generated copies (ADR 0005).
- **`tailwind.config.cjs`** lives per site and extends `Tailwind/preset.js`;
  `content` globs point at generated HTML (`./Websites/<Site>/**/*.html`),
  never at Swift sources. `static/style.input.css` holds exactly the three
  `@tailwind` directives.
- **`functions/`** holds Cloudflare Pages middleware/handlers per site — keep
  them small and free of duplicated policy; shared behavior belongs in `util`.
- Blog/content markdown carries the same frontmatter shape as existing posts;
  `llms.txt`, `robots.txt`, `site.webmanifest`, and `well-known/` are served
  as-is — changes there are content changes, review them as such.
- `external-archives.json` in `docs-21-dev` validates against
  `external-archives.schema.json` — keep them in sync.
