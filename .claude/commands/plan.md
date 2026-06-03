---
description: "Decompose PRD spec into executable tasks with dependency DAG; produces plan, API contract, design spec, and test strategy"
argument-hint: "[change-id]"
---

# /plan: Start Phase 2 -- From PRD Spec to Executable Task Plan

## Mission

Take the committed PRD spec from Phase 1 and decompose it into an executable implementation plan. This command drives the entire Phase 2 (Plan) cycle: read the PRD, decompose into tasks with a dependency DAG, and optionally produce parallel spec artifacts (API contract, design spec, test strategy). All outputs are gated for quality before advancing to Phase 3.

## Core Principle

**Plan before code.** Every line of implementation code must trace back to a task in the plan. No task should be ambiguous — each must have clear acceptance criteria, dependencies, and verification method.

## Process

### Step 0: Pre-Condition Check

Before planning, verify:

1. `specs/prd/<change-id>.md` MUST exist and be in `proposed` status.
2. Run `run_phase_gates 1 "<change-id>"` to confirm Phase 1 gates pass.
3. Check state: `bash .claude/scripts/aiit-state.sh get <change-id> phase` should return `discover`.

If any pre-condition fails, stop. Direct the user back to `/discover` first.

### Step 1: Decompose PRD into Tasks

Activate the `writing-plans` skill. Read the PRD and produce:

1. **Task list** — Each task should be:
   - Independent (or with explicit dependencies)
   - Verifiable (clear done criteria)
   - ≤ 2 hours of estimated work
   - Mapped to PRD acceptance criteria

2. **Dependency DAG** — Express task dependencies:
   ```
   T1 → T3 → T5
   T2 → T3
   T4 → T5
   ```

3. **File scope** — List all files that will be created or modified.

Write the plan to `specs/plan/<change-id>.md` with:
```markdown
# Plan: <change-title>
## Tasks
### Task 1: <name>
- Dependencies: None
- Files: <list>
- Verification: <how to verify>
- Maps to AC: <PRD acceptance criterion reference>
## Dependency Graph
<mermaid diagram or text DAG>
## File Scope
<list of all files to be created/modified>
```

### Step 2: Parallel Spec Production (L2+)

For L2+ projects, produce these specs in parallel:

| Spec | Skill | Output |
|------|-------|--------|
| API Contract | `api-contract-first` | `specs/api/<change-id>.yaml` (OpenAPI) |
| Design Spec | `frontend-design` | `specs/design/<change-id>.md` |
| Test Strategy | — | `specs/test/<change-id>.md` |

For L0-L1, these are optional.

### Step 3: Run Phase 2 Gates

Execute `run_phase_gates 2 "<change-id>"`. This runs:

| Gate | What It Checks |
|------|----------------|
| `gate_task_granularity` | Tasks exist, count 2-30, have dependencies |
| `gate_no_cyclic_deps` | No circular dependencies |
| `gate_spec_alignment` | Plan covers PRD concepts |

If any gate fails, return to Step 1 and fix the plan. Do NOT skip gates.

### Step 4: Commit the Plan

Once all Phase 2 gates pass:
```bash
git add specs/plan/<change-id>.md
git add specs/api/<change-id>.yaml 2>/dev/null || true
git add specs/design/<change-id>.md 2>/dev/null || true
git add specs/test/<change-id>.md 2>/dev/null || true
git commit -m "spec: add plan for <change-id> -- <brief summary>"
```

### Step 5: Transition State

Update the workflow state to `execute`:

```bash
# Transition discover → plan
bash .claude/scripts/aiit-guard.sh check discover plan "<change-id>" --apply

# Transition plan → execute
bash .claude/scripts/aiit-guard.sh check plan execute "<change-id>" --apply

# Verify
bash .claude/scripts/aiit-state.sh get <change-id> phase
# Should output: execute
```

Commit the state update:
```bash
git add specs/<change-id>/.aiit.yaml
git commit -m "chore: transition <change-id> to execute phase"
```

## Hard Gate

All three Phase 2 gates must return PASS. The plan must be committed. State must be transitioned to `execute`. Do not hand off to Phase 3 (`/execute`) until these conditions are satisfied.

## Output

```
specs/plan/<change-id>.md    — Task plan with dependency DAG
specs/api/<change-id>.yaml   — API contract (L2+, optional)
specs/design/<change-id>.md  — Design spec (L2+, optional)
specs/test/<change-id>.md    — Test strategy (L2+, optional)
```

State: `<change-id>` phase = `execute`
