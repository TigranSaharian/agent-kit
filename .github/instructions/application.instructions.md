---
description: DiPro application-project guidance
applyTo: "**/*.Application/**/*.cs"
---
**This glob also matches `DiPro.Application/`, which is `Libra.Application` — the shared framework holding `IModule`, the MediatR pipeline behaviors, and authorization.** Changing it affects every module. Stop and get explicit approval before editing there.

Golden examples: `DiPro.Wallet.Application/Wallets/Commands/CreateWalletCommand.cs`, `.../Queries/GetWalletQuery.cs`, `.../Validators/CreateWalletCommandValidator.cs`.

## Shape
- Command/query record and its handler live in the **same file**: `public sealed record CreateWalletCommand(...) : IRequest<Result>;` followed by `CreateWalletCommandHandler`.
- Handlers use primary-constructor dependency injection and return `Result` or `Result<T>` from `Libra.Result.Primitives`.
- Group by aggregate first: `<Aggregate>/Commands/`, `/Queries/`, `/Validators/`, `/DTOs/`, `/ReadModels/`, `/DomainEventHandlers/`, `/Interfaces/`, `/Mappers/`.

## The `Command` / `Query` suffix is load-bearing
`UnitOfWorkBehavior` checks whether the request type name ends in `Query`; if it does, `SaveChangesAsync` is skipped entirely. A write named `...Query` will not persist, and a read named `...Command` will open a write transaction. Name accordingly and never rename across that boundary casually.

## Rules
- Return failure as `return new Error(ApplicationErrorMessages.<Area>.Errors.<Key>);` — implicit conversion handles the rest. Keep every message in the area's `ApplicationErrorMessages` class; no inline strings.
- **Do not call `SaveChangesAsync`.** The pipeline commits. Handlers call `repository.AddAsync(...)` / mutate a loaded aggregate and return.
- Reads use `I<Thing>QueryService` (read models / DTOs, `NoTracking`). Writes use `I<Aggregate>Repository`. Do not load an aggregate to serve a read.
- Put `[Authorize]` from `Libra.Application.Identity.Attributes` on the request record when the operation requires an authenticated caller; `AuthorizationBehavior` enforces it. Do not rely on controller attributes alone.
- Validators are `AbstractValidator<T>` in `Validators/`, one file per request, messages from `ApplicationErrorMessages.<Area>.Validations` and limits from the domain's `PropertyConstraints`. They are auto-registered by assembly scan — no manual wiring.
- Accept and forward `CancellationToken` on every async call.
- Register new mappers and application services in the module's `DependencyInjection.AddApplicationLayer`.
- Domain event handlers (`INotificationHandler<T>`) live in `<Aggregate>/DomainEventHandlers/` and are where a domain event turns into a published integration event or a projection update.
