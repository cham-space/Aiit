---
description: "Small change shortcut -- skips brainstorming and full plan, lightweight verification"
argument-hint: "[brief description of the change]"
---

# /tweak: Small Change Shortcut -- Lightweight Workflow for Minor Changes

## Mission

Provide a streamlined workflow for small, well-understood changes that don't warrant the full Discover → Plan → Execute → Verify pipeline. This command skips the brainstorming phase and creates a lightweight plan (≤3 tasks), with TDD optional and verification limited to pre-commit hooks.

## Core Principle

**Speed with discipline.** A tweak is for changes you already understand -- no need for brainstorming or extensive planning. But you still follow basic discipline: lightweight planning, optional TDD, and verification before archive.

## When to Use /tweak

Use `/tweak` for:
- Configuration changes (env vars, settings, constants)
- UI text/copy updates
- Minor documentation improvements
- Small bug fixes where the root cause is already clear
- Refactoring a single function or module

**Do NOT use /tweak for:**
- New features or capabilities
- Changes requiring design decisions
- Multi-module refactoring
- Performance optimizations requiring profiling
- Anything that might touch >5 files

If the change grows beyond scope during execution, stop and redirect to `/discover`.

## Scope Constraints (Hard Boundaries)

| Constraint | Limit | If Exceeded |
|-----------|-------|-------------|
| Files changed | ≤5 files | Redirect to `/discover` |
| Tasks in plan | ≤3 tasks | Redirect to `/discover` |
| Estimated time | <1 hour | If larger, use `/discover` |
| PRD required | No | — |
| Design spec | No | — |
| API contract | No | — |

If ANY constraint is violated, output: "This exceeds tweak scope. Redirecting to `/discover` for a proper tracked change." Then stop.

## Process

### Step 0: Scope Check

Before any work, validate the tweak scope:

1. User provides a brief description of the change
2. Assess: Will this touch ≤5 files? Require ≤3 tasks? Take <1 hour?
3. If yes, proceed. If no, redirect to `/discover`.

### Step 1: Initialize State

Create the change tracking state:

```bash
# Generate change-id: YYYYMMDD-<kebab-case-slug>
bash .claude/scripts/aiit-state.sh init "<change-id>" "tweak"
```

This creates `specs/<change-id>/.aiit.yaml` with:
- `workflow: tweak`
- `phase: execute` (skips discover and plan phases)
- `archived: false`

### Step 2: Lightweight Plan

Create a minimal plan directly in `specs/<change-id>/tasks.md`:

```markdown
# Tasks for <change-id>

## Task 1: <description>
- [ ] <specific action>
- Verification: <how to verify>

## Task 2: <description>
- [ ] <specific action>
- Verification: <how to verify>

## Task 3: <description> (optional)
- [ ] <specific action>
- Verification: <how to verify>
```

**No DAG, no dependencies.** Just a flat list of ≤3 tasks.

Display the plan to the user:
> "Here's the lightweight plan:
> 1. Task 1: ...
> 2. Task 2: ...
> 3. Task 3: ...
>
> Proceed with this plan, or suggest changes?"

Wait for user confirmation.

### Step 3: Execute Tasks

For each task, follow a simplified workflow:

#### 3a. Optional TDD

Unlike `/execute`, TDD is **optional** for tweaks. If the change involves logic that should be tested, write a test first. Otherwise, proceed directly to implementation.

#### 3b. Implement the Change

Make the change, keeping it minimal and focused on the task.

#### 3c. Verify

Run pre-commit hooks to verify the change:
```bash
git add <changed-files>
git commit -m "tweak(<change-id>): <brief description>"
```

The pre-commit hook runs: format → lint → type-check → secret-scan → YAML_VALIDATE.

#### 3d. Update State

After each task:
```bash
bash .claude/scripts/aiit-state.sh set execute.tasks_completed <N>
```

### Step 4: Lightweight Verification

Unlike `/execute` which runs a full 7-step verification, `/tweak` verification is limited to:

1. **Pre-commit hooks pass** (already verified during commits)
2. **Manual smoke test** (if applicable): Verify the change works as expected

No need for:
- Contract gate (no API changes)
- Security scan (unless touching auth/security code)
- E2E smoke test (unless UI-facing)
- Visual regression (no design changes)
- Full diagnostics (overkill for tweaks)

### Step 5: Archive

Once all tasks are complete, archive the change:

```bash
# Transition to release phase
bash .claude/scripts/aiit-guard.sh check execute release "<change-id>" --apply

# Archive
bash .claude/scripts/aiit-archive.sh "<change-id>"
```

Commit the archive:
```bash
git add archive/<change-id>/
git add specs/  # for cleaned up files
git commit -m "chore: archive tweak <change-id>"
```

## Hard Gate

Before considering the tweak complete:
- All tasks in `specs/<change-id>/tasks.md` must be checked off
- All commits must pass pre-commit hooks
- `.aiit.yaml` must show `archived: true`

## Output

```
## Tweak Complete: <change-id>

### Changes Made
- <file1>: <what changed>
- <file2>: <what changed>

### Commits
- <commit-sha>: <commit message>
- <commit-sha>: <commit message>

### Archive
- Location: archive/<change-id>/
- State: archived

### Verification
- Pre-commit hooks: PASS
- Manual smoke test: PASS (if applicable)
```

## Difference from /hotfix

| Aspect | /hotfix | /tweak |
|--------|---------|--------|
| Purpose | Fix a bug | Small feature/improvement |
| Root cause analysis | Required (Step 1) | Not required |
| Regression test | Mandatory | Optional |
| Scope | ≤3 files | ≤5 files |
| Plan | None | Lightweight (≤3 tasks) |
| TDD | Mandatory | Optional |
| Verification | Full regression | Pre-commit + manual |

## Difference from /discover

| Aspect | /discover | /tweak |
|--------|-----------|--------|
| Brainstorming | Yes (full exploration) | No |
| PRD | Yes (7 sections) | No |
| Plan | Full DAG + parallel specs | Lightweight (≤3 tasks) |
| TDD | Mandatory | Optional |
| Verification | 7-step + gates | Pre-commit + manual |
| Use case | New features, complex changes | Small, well-understood changes |
