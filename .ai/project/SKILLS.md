# DiPro skill catalog

Load an individual project skill only when its trigger matches. These procedures are DiPro-specific and are not part of the reusable agent kit.

| Skill | Use when |
|---|---|
| `verify-dipro-change` | Selecting/comparing build and test verification for a DiPro code change |
| `add-masstransit-consumer` | Adding or changing a MassTransit consumer, registration, or related tests |
| `add-cqrs-use-case` | Adding or changing an end-to-end command/query use case or API operation |
| `add-integration-event` | Publishing a cross-module fact through an integration-event contract and outbox |
| `add-ef-core-migration` | Creating and reviewing a module-owned EF Core schema migration |
| `add-handler-tests` | Adding or changing focused MediatR handler unit tests |
| `add-local-projection` | Maintaining a module-local read model from another module's integration events |
| `add-background-job` | Adding or changing a Hangfire background job or recurring schedule |
| `add-external-integration-client` | Adding or changing an outbound client for an external provider or service |

## Canonical source and generated copies

`.ai/project/skills/<name>/SKILL.md` is the **canonical source** for each skill. Edit it there.

Some hosts (Copilot CLI, Claude Code) only discover skills at a fixed location and read the file directly, so a generated mirror of each canonical file also lives under `.agents/skills/<name>/SKILL.md` and `.claude/skills/<name>/SKILL.md`. Each mirror contains the canonical content plus a trailing generated-file banner. The mirrors are **generated, not authored**; never hand-edit one.

After changing a canonical `SKILL.md`, run:

```
scripts/sync-skills.ps1
```

to regenerate the copies, or `scripts/sync-skills.ps1 -CheckOnly` to detect drift (missing or out-of-date copies) without writing anything — use this before a commit or in CI. Other hosts may use different skill locations or may not support skills at all; extend the target list in the script if a new host needs its own copy.

Add a project skill only for a recurring procedure with distinct steps, inputs, checks, and outputs. Avoid duplicating the path instructions or always-on rules.

