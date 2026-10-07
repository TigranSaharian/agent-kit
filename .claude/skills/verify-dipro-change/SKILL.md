---
name: verify-dipro-change
description: Selects proportionate verification for a DiPro backend code change. Use after code changes or when asked how to verify a DiPro change.
---
# Verify a DiPro change

## Before you edit: capture the baseline
The DiPro test suite is **red on a clean checkout**, so a failing test after your change proves nothing on its own. Identify the closest test project and record its current result *before* editing.

The recorded baseline is the "Recorded test baseline" table in `.ai/project/VERIFIED.md`, with its verification date and branch. Check that file's "Stale past" date before trusting it — re-run the commands below yourself once it's past that date, and do not trust the numbers on faith.

## Steps
1. Identify the changed project and its closest test project by reading project references. Only five test projects exist; most of the 87 C# projects have none.
2. Build the project you changed first — a full `dotnet build DiPro.sln` takes about 7 minutes and emits ~1150 pre-existing warnings. Do not attribute those to your change.
3. Run the narrowest check: `dotnet test <relevant-test-project.csproj> --no-build`.
4. Compare against the baseline. Report new failures as yours; name pre-existing ones explicitly as not yours.
5. Widen to `dotnet build DiPro.sln` only when the change crosses projects — for example anything touching the Libra framework (`DiPro.Domain/`, `DiPro.Application/`, `DiPro.Result/`, `DiPro.Observability/`) or a shared contract.
6. Record exact commands, exit codes, and counts. Distinguish **not run**, **failed**, and **passed**.

## Limits to state honestly
- CI runs no `dotnet test` step at all, so nothing downstream will catch what you miss.
- Existing tests are unit tests over handlers with mocked dependencies. They do not exercise the MediatR pipeline, the database, or RabbitMQ, so validation, unit-of-work, authorization, and messaging behavior are unverified by them.
- If the module you changed has no test project, say so plainly instead of scaffolding one unprompted.
- Never describe a command you did not run as validated.

<!-- generated: do not edit directly; edit .ai/project/skills/<name>/SKILL.md and run scripts/sync-skills.ps1 -->
