# DiPro verification record

This file is the **single dated fact** for how fresh the DiPro-specific overlay is. `PROJECT_CONTEXT.md`, `.github/instructions/tests.instructions.md`, and the `verify-dipro-change` skill all point here instead of repeating a literal date — update it in one place when you re-verify, instead of hunting down every copy.

## Current record

| Field | Value |
|---|---|
| Last verified | 2026-09-29 |
| Branch | `feature/dp-3357-add-ai-setup` |
| SDK | 10.0.401 |
| Stale past | 2026-10-29 (30 days later), or sooner if the solution, tests, or CI change materially |

## Targeted fact refresh

On 2026-10-07, a repository audit confirmed 104 solution entries in `DiPro.sln` (87 C# projects and 17 solution folders) and nine modules with `MessagingRegistrationExtensions.cs`, including Kernel. This targeted check did not re-run the full build/test baseline and therefore does not advance the `Last verified` date.

## Recorded test baseline (single source of truth)

All other files link here instead of repeating these numbers. Red on a clean checkout; capture a fresh baseline for the suite you touch before editing.

| Test project | Baseline | Observed |
|---|---|---|
| `DiPro.Customer.Tests\DiPro.Customers.Tests.csproj` | 41 passed, 12 failed of 53 | 2026-09-29 |
| `DiPro.Wallet.Tests\DiPro.Wallet.Tests.csproj` | Full run aborts mid-suite (test host stack overflow in `ValueObject<T>.op_Equality`, wallet re-evaluation tests); failing Activate and CreateWalletPolicy tests. Last observed: 11 passed, 5 failed, run incomplete. Earlier clean run: 4 passed, 4 failed of 8 (the two differ because the suite aborts; re-capture) | 2026-10-02 (earlier: 2026-09-29) |
| `DiPro.FileStore.Tests\DiPro.FileStore.Tests.csproj` | 1 passed of 1 | 2026-09-29 |
| `DiPro.Identity.Tests\DiPro.Identity.Tests.csproj` | Run aborts, test host stack overflow | 2026-09-29 |
| `DiPro.Kernel.Tests\DiPro.Kernel.Tests.csproj` | 0 tests discovered | 2026-09-29 |

## When you re-verify

1. Re-run the commands in `PROJECT_CONTEXT.md`'s **Verification** section (`dotnet build DiPro.sln`, the per-project `dotnet test` baseline).
2. Update the table above with the new date, branch, SDK, and a recomputed stale-past date.
3. Update the baseline table above. Other files only link to it, so nothing else needs editing for the numbers (build counts and timings in `PROJECT_CONTEXT.md` are still recorded there).
4. If you changed the canonical skill, run `scripts/sync-skills.ps1` to regenerate its host mirrors.

## Using this record

Before trusting any build/test count or baseline in the overlay, compare today's date to **Stale past** above. Past that date, treat every number as unverified and re-run the commands yourself before citing them.
