# Agent workflow and handoffs

## Purpose and enforcement boundary

This is provider-neutral guidance. It describes the intended task flow; the active host must provide agent delegation and model controls for those actions to happen automatically. Markdown cannot grant tools, start agents, switch providers, or enforce a hard token/spend cap. See `.ai/MODEL_ASSIGNMENTS.md` and `.ai/TOKEN_POLICY.md`.

## Coordinator procedure

For each user prompt, the Coordinator owns the task and final response:

1. **Intake:** Restate the desired outcome internally. Identify scope, acceptance criteria, risk, affected areas, and whether the user requested explanation/review only or implementation.
2. **Load only relevant context:** Read `AGENTS.md`, the project-context sections needed for this task, matching path instructions, and a skill only if its trigger matches. Inspect repository state before editing when tools allow it. Do not read every role and skill by default.
3. **Check task quality:** Acceptance criteria should be observable and testable. Detect missing behavior, constraints, or definitions. Ask the user only if an unresolved point could materially change behavior, data, contracts, security, business meaning, or scope. Otherwise state a bounded assumption and proceed.
   - **Authorization boundary:** a clear, in-scope request already authorizes its ordinary implementation — do not ask a second time for what the user already asked for. Pause for separate, explicit approval only when the work touches a high-impact trigger named in a project overlay (for example `.ai/project/ALWAYS_ON_GUARDRAILS.md`) — such as auth/authz behavior, schema/migrations, public contracts, dependencies, queue topology, or shared-framework code — and that specific action is not already named in the request. When such a trigger appears mid-task, state exactly what needs approval and why before continuing, and do not ask again for that same approved action within the task.
4. **Classify task weight, then choose the route and model tier:** Assign a weight (Mechanical, Light, Medium, or Heavy) using the rubric below, then follow the weight routing table, the routing matrix, and `.ai/MODEL_ASSIGNMENTS.md`. The weight decides which agent starts the work. Use the smallest team that can satisfy the acceptance criteria. Keep low-risk work direct; do not invoke the whole role roster by default.
5. **Set a token plan:** Estimate small/medium/high effort, decide which context each role needs, and set a runtime cap if available. Keep prompts bounded and avoid parallel agents on dependent work.
6. **Delegate with a complete brief:** State outcome, acceptance criteria, scope, constraints, relevant paths/context, permitted actions, requested model tier, and concise output format. Do not delegate unresolved decisions as if they were settled. Create a recorded task brief (`.ai/tasks/`) only when the work will span more than one delegate handoff, more than one session, or multiple people — a single-session, single-delegate task does not need one.
7. **Implement and verify:** For code changes with a suitable test suite, Coordinator delegates a baseline run to Verifier before edits when the host separates roles; Verifier reports the baseline to Coordinator, and Coordinator then delegates implementation. After edits, Coordinator sends the final state to Verifier for the narrowest useful checks and baseline comparison. Verifier reports evidence to Coordinator and does not authorize or directly assign implementation. Implementers do not run commands where host permissions separate these roles. In a single-agent host with edit and terminal capability, the current agent may implement and verify, but must keep the phases distinct and report only commands it actually ran. Use a single bounded fix-and-reverify pass by default.
8. **Quality review:** Review the result against each acceptance criterion. Use an independent Reviewer for Heavy changes or when requested; routine changes do not need a redundant review agent. If the host cannot provide independent review, state that limitation in the report.
9. **Report once:** Give changed areas, exact verification evidence, assumptions, unresolved issues, and remaining risks. Never claim a role or check ran without its result.

## Task weight and who starts

The Coordinator always receives the request first, classifies it in one short internal step, and then starts the agent that matches the weight. Take the **highest** weight any signal points to.

| Weight | Signals | Typical examples |
|---|---|---|
| **Mechanical** | No behavior change; wording, formatting, comments, test data | Docs edit, rename in text, formatting |
| **Light** | One file or one small unit; behavior fully specified; no high-impact trigger; trivial to revert | Small bug fix, one-method change, adding a simple test |
| **Medium** | A few files in one module; follows an existing pattern; real business logic but no high-impact trigger | Scoped feature, handler change, routine debugging |
| **Heavy** | Any high-impact trigger named by the project overlay (auth, schema/migrations, public or integration contracts, dependencies, queue topology, shared framework code, money/identity/personal data); new module or subsystem; cross-module change; production operations; unclear requirements with material impact | Contract change, migration, new module |

Test-writing follows the same rubric: tests for one handler or unit are Light; tests spanning several files in one module, or needing shared fixtures or helpers, are Medium.

A Light or Medium task becomes Heavy when work reveals a high-impact trigger. A failed first attempt escalates the weight by one level for the single repair pass.

| Weight | Starts the work | Verification | Review |
|---|---|---|---|
| Mechanical | Utility (Fast tier) | Only what the change needs | None |
| Light | Light implementer (Fast tier) | Verifier when a suitable suite exists | None unless requested |
| Medium | Standard implementer (Balanced tier); PO/BM first only if intent is unclear | Verifier: baseline before, narrow checks after | Only if requested or risk surfaces |
| Heavy | Architect first (Strong tier, or the best available), then a standard implementer; PO/BM first if intent is unclear | Verifier: baseline before, narrow checks after | **Required**, independent review |

The profile names and the concrete models behind each tier live in `.ai/MODEL_ASSIGNMENTS.md` (Copilot runtime mapping) and `.ai/adapters/copilot-models.json`.

The table describes separated-role adapters. In the Copilot adapter, the read-only Coordinator sends Mechanical work to Utility. On a single-agent host where the current agent has edit capability and no adapter requires profile routing, the current agent may perform a one-line mechanical edit directly.


## Test completion gate

Applies to every task that adds or changes a test. Decide this yourself; the user does not need to ask. The task is not complete until the designated verification actor—Verifier in a separated-role host, or the current agent in a single-agent host—has run the tests after the final edit and they pass.

1. The verification actor captures a baseline of the affected test suite before edits.
2. The implementer writes the tests. In a separated-role adapter, implementers cannot run commands and must not claim they did; in a single-agent host, the current agent may continue to verification after editing.
3. The verification actor runs the new tests in isolation (the project's run-one-class or filter command). All expected tests must be discovered and pass; zero discovered, a compile error, or any failure means not done.
4. On failure, one repair pass goes to an implementer, then step 3 repeats. If it still fails, stop and report; never report success.
5. The verification actor runs the requested or project-level suite and compares it with the baseline. Failures already in the baseline are reported as pre-existing and never excuse a failure in the new tests. If the host aborts mid-suite, say the run is incomplete.
6. The final report names the exact commands, exit codes, and pass/fail counts from the verification actor. If no Verifier or terminal-capable current agent is available, report the task as pending verification, not complete.

## Routing matrix

| Request/task shape | Route | Typical tier |
|---|---|---|
| Explanation, exploration, or review-only request | Analyze and report; do not edit | Fast or Balanced; Strong for high-impact analysis |
| Small, clear documentation or mechanical edit | Coordinator directly when tools permit; otherwise Utility | Fast |
| Bounded feature or bug fix with clear behavior | Light-weight fixes go to Implementer-Light; Medium fixes go to the standard implementer; verify proportionately | Fast for Light; Balanced for Medium |
| Unclear business intent or acceptance criteria | PO/BM to identify the gap; ask user if material ambiguity remains | Balanced |
| Cross-module design, public contract, persistence, security, money/identity, or production operations | Architect before implementation; obtain any required user decision | Strong when reasoning or failure impact is high |
| Adding a new business module or major subsystem | Architect first; consult a project overlay's module template if one exists (e.g. `.ai/project/MODULE_TEMPLATE.md`) | Strong |
| High-impact change or explicitly requested independent review | Reviewer after implementation and verification | Strong when impact warrants it |

Risk can raise a task’s tier regardless of role. A high-impact task may need a Strong implementer/reviewer; it does not automatically need every specialist. The weight table above takes precedence when the two disagree about who starts. If the host cannot honor the requested tier, say so and use its best available option only when appropriate.

## Handoff and token discipline

- Coordinator is the only role that asks the user questions and delivers the final response. Delegates report to Coordinator.
- Pass relevant excerpts and paths, not entire repository documents or conversation history.
- Ask for concise, structured findings and request quotations only to resolve a concrete decision.
- Use one implementer. Parallelize only independent read-only research when it will reduce total work.
- Do not permit recursive delegation unless the task and runtime specifically require it.
- Stop after one focused repair/reverification cycle by default. Ask before expanding scope or effort beyond the agreed plan.

## Copilot adapter

Copilot-specific setup and smoke checks are documented in `.github/COPILOT_VALIDATION.md`. The `.github/agents/` profiles are intended for VS Code and Copilot CLI; their tool support and invocation differ by host. Automatic agent selection and GPT/Claude routing are runtime behavior, not guaranteed by this workflow. Current Copilot limits and steps must be confirmed in that checklist.
