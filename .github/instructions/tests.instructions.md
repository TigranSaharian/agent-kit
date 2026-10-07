---
description: DiPro test-project guidance
applyTo: "**/*Tests/**/*.cs"
---
Golden example: `DiPro.Wallet.Tests/WalletTests/CreateWalletCommandHandlerTests.cs`.

## The stack (do not add to it)
xunit 2.5.3, Moq 4.20.72, coverlet.collector 6.0.0, `Microsoft.NET.Test.Sdk` 17.8.0, `net8.0`. No FluentAssertions, no AutoFixture, no in-memory EF provider by default. Adding a package to a test project is a dependency change and needs explicit approval.

Only five test projects exist: `DiPro.Customer.Tests` (holding `DiPro.Customers.Tests.csproj`), `DiPro.FileStore.Tests`, `DiPro.Identity.Tests`, `DiPro.Kernel.Tests`, `DiPro.Wallet.Tests`. If the module you changed has none, **say so in your report** rather than scaffolding a new test project unprompted.

## Know the baseline before you run
The suite is **red on a clean checkout**. The per-project numbers are in "Recorded test baseline" in `.ai/project/VERIFIED.md`, with the verification date and stale-past date; treat them as unverified once stale, and re-capture the baseline before every task.

So: capture the baseline for the suite you are touching **before** editing, compare after, and attribute failures honestly. Never write "tests pass" for Customers or Wallet without naming the pre-existing failures. Do not fix these as a side effect of an unrelated task — report them.

## Conventions
- Class per handler: `<Handler>Tests`, in a folder named after the aggregate (`WalletTests/`, `WalletPolicyTests/`).
- Method name `Handle_Should<Outcome>_When<Condition>` — for example `Handle_ShouldReturnFailure_WhenWalletPolicyNotFound`.
- Mocks are `Mock<IInterface>` fields assigned in the constructor, with the system under test built there too. Shared inputs go in `private const` / `private readonly` fields; build requests with a small `CreateValidCommand(...)` helper rather than repeating literals.
- Assert on the `Result`: `Assert.False(result.Succeeded)` plus `Assert.Equal(ApplicationErrorMessages.<Area>.Errors.<Key>, result.Errors[0].Message)`. Reference the message constant, never a literal string.
- Verify collaborator interactions that matter with `Times.Once`; pass `It.IsAny<CancellationToken>()`.
- Cover the failure paths, not just the happy path — the existing tests lead with the rejection cases.
- Handlers under test are units: mock repositories and query services. These tests do not touch a database, RabbitMQ, or the MediatR pipeline, so behavior supplied by the pipeline (validation, unit of work, authorization) is **not** covered here. Do not assert on it.

## Completion: tests must be run

A test task is not done until the verification actor defined in `.ai/WORKFLOW.md`, "Test completion gate", has run the new tests and they pass. In separated-role adapters, implementers cannot run commands and the Coordinator sequences the Verifier; in a single-agent host, a terminal-capable current agent may perform verification after editing. Project commands: the new class alone with `dotnet test <project>.csproj --filter FullyQualifiedName~<ClassName>`; then the requested or project-level suite, compared with the baseline above.

## Running
`dotnet test <project>.csproj --no-build` after building. Report the exact command and the pass/fail counts you actually saw.
