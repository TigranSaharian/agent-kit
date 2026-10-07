# Mandatory DiPro repository guardrails

These are local technical safety constraints for this repository. They supplement the project-neutral agent kit and apply whenever work may touch the listed data, boundaries, or systems.

## Sensitive data

Treat identity-document/passport numbers, national ID data, biometric/liveness results, card numbers/PANs, PINs, balances, transaction amounts/counterparties, phone numbers, and authentication tokens as sensitive. Never log, trace, echo in responses, or place them in exception text, test fixtures, or commits. Do not log request/response bodies from external clients that handle this data.

Before returning a model containing personal or financial fields, check whether an `IPermissionMapper` strips fields according to caller permissions and use it where applicable.

## Authorization scope

A clear request to implement or fix something in ordinary application code (controllers, handlers, domain logic, tests, consumers, etc.) already authorizes that in-scope work. Do not pause to re-confirm what the user already asked for.

Stop and get **explicit, separate approval** before proceeding — even inside an otherwise-authorized task — when the work touches any of the following, unless the user's own request already names that specific action:

- Authentication or authorization behavior
- Persistence schema or migrations
- Public API or integration-event contracts
- Dependencies (adding, removing, or upgrading a package)
- Queue topology or retry/redelivery behavior
- The MediatR pipeline registration or order
- Edits inside `DiPro.Domain/`, `DiPro.Application/`, `DiPro.Result/`, or `DiPro.Observability/` (the shared Libra framework)

When one of these triggers appears mid-task, state exactly what needs approval and why, then ask before continuing. Once the user has approved a specific high-impact action for the current task, do not ask again for that same action.

Treat edits in `DiPro.Domain/`, `DiPro.Application/`, `DiPro.Result/`, and `DiPro.Observability/` as cross-module framework changes (Libra). Treat `*.IntegrationEvents` projects as published contracts. Review migrations as production database changes; never edit an applied migration.

`semgrep-sast` runs in the pipeline. Do not suppress a finding merely to make a build pass.

The path-detectable triggers above are audited after merge by `scripts/check-protected-paths.ps1` using `.ai/project/PROTECTED_PATHS.txt`. That records unapproved changes; it does not replace asking first.

## Test-completion gate

Whenever a task adds or changes a test, follow `.ai/WORKFLOW.md`, "Test completion gate" before reporting it done. In this repository the isolated run is `dotnet test <project>.csproj --filter FullyQualifiedName~<ClassName>`; the known baseline is in `.github/instructions/tests.instructions.md`.
