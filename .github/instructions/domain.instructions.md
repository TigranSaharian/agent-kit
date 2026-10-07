---
description: DiPro domain-project guidance
applyTo: "**/*.Domain/**/*.cs"
---
**This glob also matches `DiPro.Domain/`, which is `Libra.Domain` — the shared framework, not a business module.** Editing it changes the base types for all 15 modules. Stop and get explicit approval before changing anything there.

Golden example: `DiPro.Wallet.Domain/Wallets/Entities/Wallet.cs`.

## Layout
Group by aggregate first, then by pattern: `<Aggregate>/Entities/`, `/ValueObjects/`, `/DomainEvents/`, `/DomainServices/`, `/Interfaces/`, `/Exceptions/`, plus `DomainMessages.cs` and `PropertyConstraints.cs` per aggregate folder.

## Aggregates
- Derive from `Libra.Domain.Primitives.AggregateRoot<TId>` (usually `<long>`).
- Private parameterless constructor for EF, private constructor for real creation, `public static Create(...)` factory. Name arguments at call sites — this codebase uses named arguments heavily.
- All setters `private set`. State changes only through intention-revealing methods (`Activate`, `Restrict`, `Close`, `ReevaluateToGeneral`).
- Raise `AddDomainEvent(new <Thing>DomainEvent(...))` inside the method that makes the change, not by the caller.
- Soft delete via the inherited `SoftDelete()`; do not add an `IsDeleted` flag by hand.

## Invariants
- Enforce in the domain and signal failure by `throw new Invalid<Aggregate>DomainException(DomainMessages.<Aggregate>.<Key>)`. Never return `Result` from domain code — that is the Application layer's job, and `ExceptionHandlingBehavior` translates domain exceptions at the pipeline edge.
- Put message strings in the aggregate's `DomainMessages` class and length/size limits in `PropertyConstraints`. No inline literals.
- Status types are value objects with explicit transition rules (`WalletStatus.CanTransitionTo(...)`), not bare enums. Reuse the existing pattern rather than introducing an enum.
- A domain service (`I<Thing>DomainService` + implementation under `DomainServices/`) is for rules spanning aggregates only.

## Boundaries
- No EF Core, MediatR, MassTransit, ASP.NET, or configuration types in Domain. Repository interfaces are declared here and implemented in Infrastructure.
- Do not reference another module's Domain project. Cross-module facts arrive as integration events.
- Money and balance changes are high-impact: state the invariant you are relying on, and do not relax an existing `Ensure*` guard without explicit approval.
