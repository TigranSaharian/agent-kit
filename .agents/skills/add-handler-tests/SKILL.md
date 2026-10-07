---
name: add-handler-tests
description: Adds or changes focused DiPro MediatR handler unit tests using the existing xUnit and Moq conventions. Use for command-handler tests, query-handler tests, regression coverage, or test updates.
---
# Add or change DiPro handler tests

Reference implementation: `DiPro.Wallet.Tests/WalletTests/CreateWalletCommandHandlerTests.cs`. Follow `.github/instructions/tests.instructions.md` and the test-completion gate in `.ai/WORKFLOW.md`.

1. **Confirm a supported test home.** Locate the closest existing test project by project references. Do not create a new test project, testing stack, package, shared fixture, or database harness unless the request explicitly includes it. If the module has no suitable project, report that instead of placing tests in an unrelated module.
2. **Capture the baseline before editing.** Build the test project and run its existing suite using the repository's verification workflow. Record exact commands, exit codes, discovered/pass/fail counts, and pre-existing failures. Treat `.ai/project/VERIFIED.md` as historical evidence only within its freshness window.
3. **Define observable cases.** Cover the happy path, each meaningful early return or domain rejection, and collaborator behavior that protects the business rule. Do not claim these unit tests cover FluentValidation, authorization, unit of work, EF, MassTransit, or other pipeline behavior.
4. **Match local structure.** Use one `<Handler>Tests` class in the aggregate folder. Build mocks and the system under test in the constructor, keep shared values in fields, and use a small `CreateValidCommand` or `CreateValidQuery` helper.
5. **Use repository assertions.** Name tests `Handle_Should<Outcome>_When<Condition>`. Assert `Result.Succeeded`; for failures compare against `ApplicationErrorMessages` constants, not string literals. Verify meaningful calls with `Times.Once` and accept `It.IsAny<CancellationToken>()`.
6. **Keep tests deterministic and safe.** Mock repositories, query services, clocks, and clients at established boundaries. Use synthetic non-sensitive values; never copy production identity, card, balance, token, or customer data into fixtures.
7. **Run the final test gate.** After the last edit, run the class in isolation:

   `dotnet test <project>.csproj --filter FullyQualifiedName~<ClassName>`

   Confirm that expected tests were discovered and all new/changed tests passed. Then run the project-level suite with `--no-build` and compare it with the recorded baseline. One focused repair-and-rerun cycle is allowed by default.

The task is pending verification—not complete—if the final isolated tests were not run, discover zero tests, fail, abort, or cannot be distinguished from the baseline. Report exact commands, counts, new versus pre-existing failures, and coverage limitations.

<!-- generated: do not edit directly; edit .ai/project/skills/<name>/SKILL.md and run scripts/sync-skills.ps1 -->
