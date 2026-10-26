---
description: <Project> <area> guidance
applyTo: "**/<glob matching the files this applies to>"
---
Pattern for a path-scoped rule. Copy to `.github/instructions/<name>.instructions.md`, set a real `applyTo` glob (`scripts/check-agent-kit.ps1` flags globs that match nothing), then run `scripts/sync-agent-profiles.ps1` to generate the Cursor rule.

## Layout
<Where things go in this area.>

## Conventions
- <Rule, with a golden example file: `<path>`>

## Do not
- <Common mistake agents make here>
