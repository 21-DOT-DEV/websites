---
trigger: always_on
description: >
  Global conventions and scope rules for all Windsurf tasks in this repository.
  Applies to every site and code path unless explicitly overridden by more specific rules.
---

# Conventions and Scope

## Clarify First
- If a task is ambiguous or missing inputs (site name, file path, environment variables, configuration), **ask clarifying questions before making changes**.
- Confirm assumptions explicitly if multiple valid interpretations exist.

## Limit Scope & Prevent Churn
- Do **NOT** modify unrelated files or perform large refactors unless explicitly requested.
- Avoid formatting-only changes unless they fix an inconsistency defined in these rules.
- Keep suggestions and edits directly relevant to the user’s request.

## Consistent Communication
- Follow the style and terminology defined in `99-glossary-terminology.md` for all outputs.
- Keep code comments and generated documentation concise, accurate, and aligned with project tone.

## Rule & Workflow Alignment
- Apply relevant rules from `.windsurf/rules/` for all changes.
- When procedural steps are required, **reference and run** the appropriate workflow from `.windsurf/workflows/`.

## Multi-Site Awareness
- Assume this repository may contain multiple independent sites.
- Always confirm the target site before applying changes that affect site-specific configuration, code, or assets.
