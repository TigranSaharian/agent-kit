---
name: add-cqrs-use-case
description: Adds or changes an end-to-end DiPro command or query use case, including its handler, validation, authorization, persistence/read path, controller endpoint, and focused tests. Use for CQRS handlers, API operations, commands, or queries.
---
# Add or change a DiPro CQRS use case

Reference module: `DiPro.Wallet`. Also inspect the closest use case in the target module; its audience and aggregate matter more than superficial naming.

1. **Define the operation before editing.** Identify the owning module and aggregate, caller (`Admin`, `Wallet`, internal, or integration event), inputs, result, authorization, sensitive fields, and whether state changes. Treat API shape, authorization, schema, dependencies, and shared Libra edits as approval triggers under `.ai/project/ALWAYS_ON_GUARDRAILS.md` unless the request already names that action.
2. **Choose the request type deliberately.** A state-changing request must end in `Command`; a read must end in `Query`. `UnitOfWorkBehavior` uses this suffix to decide whether to save changes. Put the request record and handler together under `<Aggregate>/Commands/` or `<Aggregate>/Queries/`.
3. **Keep business rules in the correct layer.** Put aggregate invariants and state transitions in Domain. The handler orchestrates repositories, query services, and domain methods and returns `Result` or `Result<T>`. Store failures in the area's `ApplicationErrorMessages`; do not inline messages or call `SaveChangesAsync`.
4. **Use the correct data path.** Commands load and mutate aggregates through Domain-owned repositories. Queries use Application-owned query services over `ReadOnlyDbContext` and return DTOs/read models, never aggregates. Add Infrastructure implementations and registrations only when the needed abstraction does not exist.
5. **Add validation and authorization.** Put an `AbstractValidator<T>` in `Validators/`, using `PropertyConstraints` and application validation messages. Put `[Authorize]` on the request when required; do not rely on controller attributes. If the result contains personal or financial data, apply the area's `IPermissionMapper`.
6. **Expose HTTP only when requested.** Add the action to the controller for the correct audience. It builds the request, calls `ISender.Send` with the cancellation token, and returns `result.ToActionResult()`—no business logic or data access.
7. **Check registration and boundaries.** Validators and entity configurations are assembly-scanned; application services, query services, repositories, and permission mappers require the module's established DI registration. Do not introduce cross-module Domain or Infrastructure references.
8. **Test and verify.** If a suitable test project exists, follow `add-handler-tests`; otherwise report the gap. Follow `verify-dipro-change`, building the narrowest changed project and comparing applicable tests with their pre-edit baseline.

Report the operation, affected layers, authorization and sensitive-data decisions, exact verification results, and any approval-sensitive contract or persistence work.

<!-- generated: do not edit directly; edit .ai/project/skills/<name>/SKILL.md and run scripts/sync-skills.ps1 -->
