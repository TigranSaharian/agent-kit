# DiPro business module template

Use this as the starting layout and checklist when adding a business module to DiPro. It describes the repository's current conventions; it is guidance, not a code generator. Before scaffolding, compare with the Wallet reference module and the existing module closest to the new module's needs. Keep optional capabilities out until required.

## Standard project set

A full business module typically has these projects:

```text
DiPro.<Module>/                         # Host-facing API and module composition
DiPro.<Module>.Domain/                  # Domain model and abstractions
DiPro.<Module>.Application/             # Use cases and application contracts
DiPro.<Module>.Infrastructure/          # Persistence and external implementations
DiPro.<Module>.IntegrationEvents/       # Published cross-module contracts, when needed
DiPro.<Module>.Tests/                   # Tests, when included in scope and supported
```

Not every module needs all projects. `Aggregator` and `Orchestration` are composition modules with only the host-facing and Application projects. Some modules do not publish integration events. Follow the closest existing module rather than creating empty projects to satisfy this diagram.

## Folder layout

```text
DiPro.<Module>/
├── Controllers/
│   ├── Admin/                           # If there are admin endpoints
│   ├── <Audience>/                      # If there are other HTTP audiences
│   └── Common/                          # Module-specific base controllers, if needed
├── Requests/                            # Optional .http request samples
├── <Module>Module.cs                    # Implements IModule; composition entry point
├── ResultExtensions.cs                  # HTTP mapping for application Results
└── DiPro.<Module>.csproj

DiPro.<Module>.Domain/
├── Common/
│   ├── Exceptions/                      # Shared domain exception types, if needed
│   ├── Interfaces/                      # Shared abstractions, if needed
│   └── ValueObjects/                    # Shared value objects, if needed
└── <Aggregate>/                         # Repeat per aggregate/bounded area
    ├── Entities/
    ├── ValueObjects/
    ├── DomainEvents/
    ├── Interfaces/                      # Repository/domain-service abstractions
    ├── Exceptions/
    ├── DomainServices/                  # Only for rules spanning aggregates
    ├── DomainMessages.cs
    └── PropertyConstraints.cs

DiPro.<Module>.Application/
├── DependencyInjection.cs               # Application-layer registrations, if needed
└── <Aggregate>/                         # Group by aggregate, then by pattern
    ├── Commands/                        # Request and handler together where established
    ├── Queries/
    ├── Validators/
    ├── DTOs/
    ├── ReadModels/
    ├── Interfaces/                      # Query-service/application abstractions
    ├── Mappers/                          # If needed
    ├── DomainEventHandlers/              # If needed
    └── ApplicationErrorMessages.cs

DiPro.<Module>.Infrastructure/
├── Data/
│   ├── ApplicationDbContext.cs           # If module owns persistence
│   └── ReadOnlyDbContext.cs              # If module has query/read paths
├── EntityTypeConfigurations/             # If using EF Core
├── Migrations/                           # If module owns an EF schema
├── Repositories/                         # Domain repository implementations
├── Services/                             # Query services and infrastructure adapters
├── Messaging/                            # Only if messaging is needed
│   ├── Consumers/
│   ├── Definitions/
│   └── <Module>MassTransitRegistration.cs
├── Extensions/
│   └── MessagingRegistrationExtensions.cs # Explicit consumer registration, if used
├── BackgroundJobs/                       # If needed
├── DependencyInjection.cs                # Infrastructure registrations
└── DiPro.<Module>.Infrastructure.csproj

DiPro.<Module>.IntegrationEvents/
└── <Event>IntegrationEvent.cs             # Only events this module owns and publishes

DiPro.<Module>.Tests/
└── <Aggregate>Tests/
    └── <Handler>Tests.cs                  # Follow existing test-project conventions
```

Folders are examples, not a requirement to create empty directories. Domain and Application code is grouped by aggregate first, then pattern. Use the existing capitalization and naming conventions of the closest module.

## Dependency boundaries

The intended dependency direction is:

```text
DiPro.<Module>                  → Application + Infrastructure + IntegrationEvents
DiPro.<Module>.Application      → Domain + shared Libra abstractions
DiPro.<Module>.Infrastructure   → Application + Domain + required platform/client projects
DiPro.<Module>.Domain           → shared domain primitives only
DiPro.<Module>.IntegrationEvents → shared integration-event base/contracts only
```

- Domain must not depend on EF Core, MediatR, MassTransit, ASP.NET Core, configuration, or Infrastructure.
- Application owns use cases and abstractions; Infrastructure implements persistence and external-system details.
- Do not reference another module's Domain or Infrastructure. For cross-module behavior, use owned integration-event contracts and consumers, or compose through `DiPro.Host/Aggregator` where appropriate.
- Add only project references and packages that the module needs. Shared Libra projects under `DiPro.Domain/`, `DiPro.Application/`, `DiPro.Result/`, and `DiPro.Observability/` are cross-module framework code and have special approval guardrails.

## Module creation checklist

1. **Establish ownership and shape.** Define the module boundary, its aggregates/use cases, data ownership, callers, and whether it needs HTTP endpoints, persistence, tests, or integration events. Reuse existing modules where the capability already belongs.
2. **Create only needed projects.** Follow the standard names above and copy project settings/references from the closest existing module. Do not copy Wallet-only dependencies or optional capabilities blindly.
3. **Implement layers inward.** Put invariants and domain events in Domain; use cases and request validation in Application; database/external implementations in Infrastructure; transport endpoints and `IModule` composition in the host-facing project.
4. **Set up persistence only if owned.** Follow the module schema, `ApplicationDbContext`/`ReadOnlyDbContext`, configuration, outbox, migrations, and local EF tool conventions in project context and path instructions. Schema and migration work is high impact and subject to `.ai/project/ALWAYS_ON_GUARDRAILS.md`.
5. **Set up messaging only if needed.** Keep `<Module>MassTransitRegistration.cs` for the module's MassTransit registration. Add consumers and definitions only when consuming events, and explicitly register each consumer in `MessagingRegistrationExtensions.cs`. A published event is a contract owned by its publishing module.
6. **Register at the host.** Add the module to the solution and wire it into the host's module loading/composition and required service/configuration registration. Check `DiPro.Host` and existing module registration rather than assuming project creation is enough.
7. **Add local configuration and tests.** Follow existing configuration-key shape and test conventions. Confirm whether a suitable test project exists; do not add dependencies or a new testing stack without appropriate approval.
8. **Verify the result.** Capture a relevant test baseline before implementation, build the narrowest useful projects, run applicable tests, check project-reference boundaries, and report exact commands/results and limitations.

## Reference modules

- `DiPro.Wallet` is the richest end-to-end reference, including persistence, consumers, projections, jobs, domain events, and endpoints. Treat those capabilities as examples, not mandatory template parts.
- `DiPro.Aggregator` and `DiPro.Orchestration` demonstrate composition modules without their own persistence or full domain layer.
- Use `.ai/project/PROJECT_CONTEXT.md` and the matching `.github/instructions/` files for detailed local conventions and high-impact constraints.
