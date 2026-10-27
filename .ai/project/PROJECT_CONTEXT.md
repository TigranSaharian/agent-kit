# <Project name> project context

> Template. Replace every `<...>` and delete the guidance lines. Record only facts you verified in the code, and note the verification date in `.ai/project/VERIFIED.md`.

## What this project is

<Two or three sentences: what the system does and who uses it. No business rules.>

## Architecture

- Style: <layered / modular monolith / microservices / ...>
- Main technologies: <language, framework, database, messaging>
- Shared framework or libraries every module depends on: <names and where they live>

## Repository map

| Path | Purpose |
|---|---|
| `<src/...>` | <what lives here> |
| `<tests/...>` | <what lives here> |

## Module / feature anatomy

<Which projects or folders make up one module or feature, and which direction dependencies may point. See `MODULE_TEMPLATE.md` for the full layout.>

## Conventions that agents get wrong

<List the local habits that differ from framework defaults or common practice. Each item: the rule, and the file that shows it.>

- <Convention> (example: `<path>`)

## Verification

Commands that were actually run, with their results:

| Purpose | Command | Result |
|---|---|---|
| Build | `<command>` | <pass / known warnings> |
| Tests | `<command>` | <counts and known baseline failures> |

## Where to put things

| You are adding | Put it in |
|---|---|
| <thing> | `<path>` |
