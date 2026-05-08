---
description: "Execute plan tasks in topological order with TDD iron rule; openspec diff monitors spec drift"
argument-hint: "[change-id]"
---

# /execute: Start Phase 3 -- TDD Implementation Loop with Spec Drift Guard

## Mission

Execute every task from `specs/plan/<change-id>.md` in strict topological order, applying the TDD iron rule to every line of production code. This command drives the entire Phase 3 (Execute) cycle: read the plan DAG, enforce test-first discipline, run per-task gates, detect spec drift via `openspec diff`, and produce verifiable Red-Green evidence for each task. At L2+, independent tasks run concurrently via isolated git worktrees and parallel subagents.

## Core Principle

**TDD is non-negotiable.** A test MUST be written, committed, and observed to FAIL before any implementation code is written for that task. If implementation code appears before a failing test, delete the implementation and restart the task. This is the "TDD Iron Rule" enforced by both this command and the pre-commit `TDD_GATE` hook.

## Process

### Step 0: Pre-Condition Check

Before anything else, verify:

1. `specs/plan/<change-id>.md` MUST exist with a valid task list and dependency DAG.
2. The change MUST be in `planned` status.
3. Run `run_phase_gates 2 "<change-id>"` to confirm Phase 2 gates (Task Granularity, No Cyclic Deps, Spec Alignment) all pass.

If any pre-condition fails, stop. Direct the user back to Phase 2 (Plan). Do not proceed with a partial or missing plan.

### Step 1: Read and Topologically Sort Tasks

1. Read `specs/plan/<change-id>.md` to extract the full task list with dependency edges.
2. Build a directed acyclic graph (DAG) of tasks.
3. Produce a topologically sorted execution queue.
4. Display the queue to the user for confirmation: "I will execute tasks in this order: T1 -> T2 -> T3 (parallel with T4) -> T5. Confirm?"

### Step 2: Per-Task TDD Loop

For each task in topological order, execute this sub-cycle:

#### 2a. Write the Test (RED)

Write the test file for this task FIRST. The test must:
- Be minimal and focused on the task's specific behavior
- Handle the task's acceptance criteria and edge cases
- Be named according to the project's test convention (e.g., `*.test.ts`, `*_test.py`)

Run the test suite for this file ONLY:
```
# Example: run the new test file in isolation
npx vitest run path/to/test.test.ts
```

**Hard Check**: The new test MUST fail. If it passes without implementation code, the test is inadequate -- rewrite it. Document the failure output as **RED evidence**.

#### 2b. Write Minimal Implementation (GREEN)

Write the absolute minimum code to make the failing test pass. No extra abstraction, no speculative features, no "while we're here" improvements. The implementation:
- Must stay within the file scope declared in `specs/<change-id>/plan-scope.txt`
- Must NOT touch files outside the plan scope

Run the test suite for the task:
```
npx vitest run path/to/test.test.ts
```

**Hard Check**: The test MUST pass. If it does not, fix the implementation -- not the test. Document the passing output as **GREEN evidence**.

#### 2c. Refactor (Internal Quality)

With the test green, improve the internal structure without changing external behavior:
- Remove duplication
- Improve naming
- Simplify logic

Run the full test suite to confirm no regressions:
```
npx vitest run
```

If any previously passing test now fails, revert the refactor and investigate.

#### 2d. Spec Drift Check

Run `openspec diff <change-id>` to compare implementation state against the spec. The L2 `check_spec_drift` function categorizes drift as:
- **ALIGNED** -- proceed to commit
- **MEDIUM** -- minor deviations; review with user, decide whether to update spec or revert changes
- **HIGH** -- significant divergence; BLOCK the commit, resolve the gap before continuing

#### 2e. Commit (Atomic)

Stage and commit the task's test + implementation together:
```
git add <test-file> <source-file>
git commit -m "feat(<change-id>): <task-description>

TDD Log:
- RED: test/<test-file> -- failed with: <key assertion failure>
- GREEN: same test -- passed after implementing <brief description>
- Spec drift: ALIGNED"
```

The pre-commit hook runs: format -> lint -> type-check -> secret-scan -> TDD_GATE. The commit-msg hook enforces conventional commit format. If any hook fails, fix and re-commit.

### Step 3: L2+ Parallel Mode (Conditional)

When `enableLevel >= L2` AND at least 2 tasks have all dependencies satisfied:

1. Activate `subagent-driven-development` skill.
2. For each ready task, create an isolated git worktree (via `using-git-worktrees` skill).
3. Dispatch a subagent per task with its own worktree, running the full Step 2 TDD loop independently.
4. Subagents report back with their TDD Log (RED + GREEN evidence + spec drift status).
5. Integrate results sequentially: merge each completed worktree, resolve conflicts if any.

Parallel mode is opportunistic -- it accelerates throughput but does not relax the TDD iron rule. Every agent follows Steps 2a-2e exactly.

## Hard Gate

Three named gates block task completion. All three must pass before moving to the next task:

| Gate | Enforced By | What Blocks |
|------|------------|-------------|
| **TDD Gate** | pre-commit `TDD_GATE` hook + command discipline | Source file committed without corresponding test file staged |
| **File Scope Gate** | L2 `check_file_scope` in `l2-checks.sh` | Any changed file not listed in `specs/<change-id>/plan-scope.txt` |
| **Spec Drift Gate** | L2 `check_spec_drift` via `openspec diff` | HIGH-level divergence between implementation and spec |

No task is "done" until all three gates return PASS for that task's commit.

## Output

For each task executed, produce:

```
## Task: <task-id> -- <task-name>

### TDD Log
- **RED**: `<test-file>` -- ran at <timestamp>, failed with assertion:
  ```
  <key failure output>
  ```
- **GREEN**: `<test-file>` -- ran at <timestamp>, passed. Implementation: `<source-file>`, `<lines changed>` lines.
- **REFACTOR**: `<changes made>`, full suite: `<N>/<N>` passed.
- **SPEC DRIFT**: `openspec diff` result: `<ALIGNED/MEDIUM/HIGH>`

### Commit
- SHA: `<commit-hash>`
- Message: `feat(<change-id>): <description>`
```

Aggregate summary after all tasks complete:

```
## Phase 3 Execution Complete

| Task | RED Evidence | GREEN Evidence | Spec Drift | Commit |
|------|-------------|----------------|------------|--------|
| T1   | YES         | YES            | ALIGNED    | abc123 |
| T2   | YES         | YES            | ALIGNED    | def456 |
| ...  | ...         | ...            | ...        | ...    |

All Phase 3 gates: TDD PASS, File Scope PASS, Spec Drift PASS
Change status: executed
```
