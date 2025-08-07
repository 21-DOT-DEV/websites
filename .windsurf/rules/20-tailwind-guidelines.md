---
trigger: glob
globs: Resources/**/tailwind.config.* , Resources/**/static/style.css
description: >
Tailwind CSS configuration & styling rules for Slipstream sites. Covers shared
preset, per-site configs, entry CSS location, and utility-first guidelines.
---

Tailwind CSS Guidelines

Configuration Strategy
	•	Shared preset: All sites extend Tailwind/preset.js via the extends key.
	•	Per-site config path: Resources/<SiteName>/tailwind.config.cjs.
	•	Plugin policy: Plugin-free baseline—no @tailwindcss/* or custom plugins unless explicitly approved in a future rule.

Required content globs for every config

Do not include Swift sources; class names live only in rendered resources.

content: [
  "./Resources/**/*.html",
  "./Resources/**/*.{md,markdown}",
  "./Resources/**/*.txt",
  "./Tailwind/**/*.js" // shared preset & optional helpers
]

Entry CSS File
	•	Location & name (strict): Resources/<SiteName>/static/style.css.
	•	Each entry file must contain exactly:

@tailwind base;
@tailwind components;
@tailwind utilities;


	•	Adding main.css, tailwind.css, or other entry names violates the rule.

Utility-First Styling Principles
	1.	Prefer Tailwind utilities over custom CSS classes.
	2.	Avoid arbitrary values ([height:123px]) unless design tokens or preset utilities cannot express the requirement.
	3.	Extract repeated class mixes into Tailwind components or CSS @apply only when repetition harms readability.
	4.	Keep custom CSS limited to typography resets, third-party embeds, or browser quirks.

File Organization Recap

Tailwind/
  preset.js           # shared theme, tokens, plugins (future)
Resources/
  21-dev/
    static/style.css  # entry CSS for 21-dev
    tailwind.config.cjs
  bitcoin-how/
    static/style.css
    tailwind.config.cjs
Websites/             # build output (ignored)

CI Validation
	•	GitHub Actions should run tailwindcss -c Resources/<Site>/tailwind.config.cjs --minify as part of the build to ensure configs & content globs compile successfully.

Cascade should prompt a fix or abort generation if new files violate the path/name rules or introduce disallowed plugins.