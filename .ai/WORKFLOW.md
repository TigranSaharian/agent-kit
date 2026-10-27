# Agent workflow and handoffs

Provider-neutral task flow. The host must provide delegation and model controls for any of it to happen automatically; Markdown cannot grant tools, start agents, switch models, or enforce a spend cap. Host specifics live in the adapters: Copilot in `.ai/MODEL_ASSIGNMENTS.md` (Copilot runtime mapping) and `.github/COPILOT_VALIDATION.md`, Cursor in `.ai/adapters/CURSOR.md`. Token rules are in `.ai/TOKEN_POLICY.md`; kit maintenance is in `.ai/CORE_SETUP.md`.

## Coordinator procedure

The Coordinator owns every user prompt and the final response.

1. **Intake.** Identify the outcome, acceptance criteria, scope, risk, and whether the user wants an answer or a change. Answer questions and explanations directly, without routing or delegation.
2. **Load only relevant context.** Before code edits, read the project guardrails, the path instructions matching the files in scope, and a skill only when its trigger matches. Do not read every role, skill, or overlay file by default.
3. **Check the request.** Ask the user only when an unresolved point could materially change behavior, data, contracts, security, business meaning, or scope. Otherwise state a bounded assumption and proceed.
4. **Classify weight and route** with the tables below, and size the plan with `.ai/TOKEN_POLICY.md`. Use the smallest team that meets the acceptance criteria.
5. **Delegate with a complete brief:** outcome, acceptance criteria, scope and exclusions, relevant paths, permitted actions, any approved high-impact action, and the report format. Do not delegate unresolved decisions. Record a brief in `.ai/tasks/` only when work spans several handoffs, sessions, or people.
6. **Implement and verify** as described in "Verification". Allow one bounded repair-and-reverify pass by default.
7. **Review** the result against each acceptance criterion. Add an independent Reviewer for Heavy work or when requested.
8. **Report once:** changed areas, exact verification evidence, assumptions, unresolved issues, and remaining risks. Never claim a role, model, or check ran without its result, and never present a plan as completed work.

## Authorization boundary

A clear, in-scope request already authorizes its ordinary implementation; do not ask again for what the user asked for. Pause for separate, explicit approval only when the work touches a high-impact trigger named by the project overlay (for example in `.ai/project/ALWAYS_ON_GUARDRAILS.md`) and the request does not already name that specific action. When a trigger appears mid-task, state exactly what needs approval and why before continuing, and do not ask again for the same approved action within the task.

## Task weight

Take the **highest** weight any signal points to.

| Weight | Signals | Typical examples |
|---|---|---|
| **Mechanical** | No behavior change; wording, formatting, comments, test data | Docs edit, rename in text, formatting |
| **Light** | One file or one small unit; behavior fully specified; no high-impact trigger; trivial to revert | Small bug fix, one-method change, a simple test |
| **Medium** | A few files in one module; follows an existing pattern; real business logic; no high-impact trigger | Scoped feature, handler change, routine debugging |
| **Heavy** | Any high-impact trigger named by the overlay; new module or subsystem; cross-module change; production operations; unclear requirements with material impact | Contract change, migration, new module |

Tests for one handler or unit are Light; tests spanning several files in one module, or needing shared fixtures or helpers, are Medium. Work becomes Heavy as soon as a high-impact trigger appears. A failed first attempt raises the weight one level for the single repair pass.

## Routing

| Weight | Starts the work | Verification | Review |
|---|---|---|---|
| Mechanical | The Coordinator directly when it can edit; otherwise Utility (Fast tier). Utility also suits bulk mechanical edits | Only what the change needs | None |
| Light | Light implementer (Fast tier) | As in "Verification" when a suitable suite exists | None unless requested |
| Medium | Standard implementer (Balanced tier) | Baseline before, narrow checks after | Only if requested or risk surfaces |
| Heavy | Architect (Strong tier or best available), then the standard implementer | Baseline before, narrow checks after | **Required**, independent |

- **Unclear business intent:** PO/BM first, or one material question to the user, before any implementation.
- **New business module or major subsystem:** Architect first, starting from the overlay's module template when one exists (for example `.ai/project/MODULE_TEMPLATE.md`).
- **Escalation:** a delegate whose work exceeds its weight stops and reports; the Coordinator reclassifies out loud and obtains any required approval.
- **Tiers:** risk can raise a tier regardless of role; the weight decides who starts. If the host cannot honor a tier, say so and use the best available option only when appropriate.
- **Independent review** comes from a context separate from the author, preferably a different model family; the host adapter defines the pairing. If the host cannot provide it, state that limitation.
- **No delegation available:** a current agent with edit and terminal access implements and verifies directly and says no delegate ran. A read-only agent gives the weight, intended route, and a self-contained brief, and marks the work pending.

## Verification

- **Who runs commands.** Where the host separates roles, implementers never run builds or tests. Use the Verifier for baselines and for long suite or solution runs, which keeps their output out of the Coordinator's context. A Coordinator with terminal access may run a single isolated test class, a single-project build, or kit sync checks itself. Creating or editing implementation files, including generated migrations, stays with the implementer. In a single-agent host the current agent implements and verifies, keeping the phases distinct.
- **Baseline first.** Capture the affected suite's result before code edits. If the changed project has no suite, say so and verify with the narrowest build instead of inventing a baseline.
- **After edits,** run the narrowest useful checks, compare them with the baseline, and report pre-existing failures as such.
- **Unrelated test changes already in the worktree.** Run `git status` before the baseline. Name every already-modified test file outside the files this task changes, whether it sits in the suite being run or in another project, in the baseline and in the final report. When the diff or file shows the test class or test name, report that name too. State whether the verification command covers it; if it is outside the executed suite, say it was unrun and do not infer a result. Do not fix it unless the user asked.

### Test completion gate

Applies to every task that adds or changes a test; the user does not need to ask.

1. Capture the affected suite's baseline before edits.
2. The implementer writes the tests. Where the host separates roles it cannot run them and must not claim it did.
3. Run the new tests in isolation with the project's filter command. Every expected test must be discovered and pass; zero discovered, a compile error, or any failure means not done.
4. On failure, allow one repair pass, then repeat step 3. If it still fails, stop and report; never report success.
5. Run the requested or project-level suite and compare it with the baseline. Baseline failures are reported as pre-existing and never excuse a failing new test. If the host aborts mid-suite, say the run is incomplete.
6. Report exact commands, exit codes, and pass/fail counts. If nobody available can run the tests, report the task as pending verification, not complete.

## Handoffs

- Only the Coordinator asks the user questions and delivers the final response. Delegates report to it and never start another delegate.
- Use one writer at a time. Parallelize only independent read-only research that reduces total work.
- Pass paths and relevant excerpts, not whole documents or conversation history, and ask for concise, structured findings.
- Ask before expanding scope or effort beyond the agreed plan.
