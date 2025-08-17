---
description: Compile Tailwind CSS for the target site.
auto_execution_mode: 1
---

# Tailwind Compile

1. Run Tailwind CLI command for the target site:
   ```bash
   swift package --disable-sandbox tailwindcss \
     --input Resources/<SiteName>/static/style.css \
     --output Websites/<SiteName>/static/style.output.css \
     --config Resources/<SiteName>/tailwind.config.cjs
   ```

2. For 21-dev site specifically:
   ```bash
   swift package --disable-sandbox tailwindcss \
     --input Resources/21-dev/static/style.css \
     --output Websites/21-dev/static/style.output.css \
     --config Resources/21-dev/tailwind.config.cjs
   ```

3. Verify output file is created at `Websites/<SiteName>/static/style.output.css`.
4. Ensure command matches CI configuration exactly.