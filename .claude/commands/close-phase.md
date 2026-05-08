---
description: "Compress phase knowledge into a Migration Journal, auto-archive via openspec archive, update CLAUDE.md, and cleanup"
argument-hint: "[change-id]"
---

# /close-phase: Start Phase 5 -- Archive the Change, Update CLAUDE.md, Compress Knowledge

## Mission

Finalize a completed change by distilling its phase knowledge into a Migration Journal, auto-archiving all artifacts via `openspec archive <change-id>` into `archive/<change-id>/`, updating CLAUDE.md's active changes registry, and cleaning up the working `specs/<change-id>/` directory. This command ensures that nothing is deleted -- knowledge is compressed and moved to the archive -- and that the project's CLAUDE.md always reflects the current state of active work.

## Core Principle

**Compress, don't delete.** Every artifact produced during the change lifecycle (PRD, plan, tasks, test logs, TDD Log, smoke test report, verification report, review notes) is valuable. This command compresses that knowledge into a Migration Journal summary stored in the archive, then uses `openspec archive` to move the full record. Nothing is `rm -rf`'d. Everything is preserved in `archive/<change-id>/` for future reference, audit, and learning.

## Pre-Conditions

Before running this command, ALL of the following must be true:

1. All Phase 3 tasks are complete with TDD Log evidence.
2. Phase 4 verification (all 7 steps) has passed:
   - Contract check (oasdiff)
   - Security scan (semgrep + SCA)
   - E2E smoke test (Playwright or manual log)
   - Visual regression (if frontend)
   - Full diagnostics (TypeScript LSP zero errors)
   - Code review (vs spec, gaps/redundancy/drift)
   - Final `openspec validate` (spec-code consistency)
3. `run_phase_gates 4 "<change-id>"` returns all PASS (Coverage, Contract, Security, Smoke Test).
4. Zero P0 bugs open against this change.
5. All code merged to the target branch (main/master).

If any pre-condition fails, output exactly what is missing and stop. Do not proceed with partial archival.

## Process

### Step 1: Detect All Phase Artifacts

Scan the change's working directory and collect all artifact paths:

```
specs/<change-id>/
  prd.md
  plan.md
  tasks.md
  plan-scope.txt
  changed-files.txt
specs/prd/<change-id>.md
specs/plan/<change-id>.md
specs/api/<change-id>.yaml            (if exists)
specs/design/<change-id>.md          (if exists)
specs/test/<change-id>.md            (if exists)
specs/release/<change-id>.md         (if exists)
```

Build a manifest of every file. This manifest will be included in the Migration Journal.

### Step 2: Extract and Compress Knowledge

For each phase artifact, extract the essential knowledge and compress it into a Migration Journal:

#### Migration Journal Template

```
# Migration Journal: <change-id>
Archived: <timestamp>
Status: archived

## Problem Solved
<1 paragraph distilled from PRD Overview & Background>

## What Was Built
<Bulleted list of deliverables from the plan>

## Key Decisions
<Table of decisions made during execution with rationale>
| Decision | Rationale | Phase |
|----------|-----------|-------|
| <what>   | <why>    | <N>   |

## Lessons Learned
<What went well, what was painful, what would we do differently next time>

## Artifact Manifest
<Full list of all files in the archive with descriptions>
| File | Phase | Description |
|------|-------|-------------|
| prd.md | 1 | Original PRD spec |
| plan.md | 2 | Task plan + DAG |
| ... | ... | ... |

## TDD Summary
<Aggregated from per-task TDD Logs>
| Task | RED | GREEN | Refactor | Spec Drift |
|------|-----|-------|----------|------------|
| T1   | YES | YES   | YES      | ALIGNED    |
| ...  | ... | ...   | ...      | ...        |

## Verification Summary
<Aggregated Phase 4 results>
| Check | Result | Evidence |
|-------|--------|----------|
| Contract | PASS | <link> |
| Security | PASS | <link> |
| Smoke Test | PASS | <link> |
| ... | ... | ... |
```

### Step 3: Present Migration Journal for Review

Display the complete Migration Journal to the user. Prompt:

> "This Migration Journal captures everything we learned during this change. Please review:
> - Are the Key Decisions accurate?
> - Are the Lessons Learned complete?
> - Is there anything we should add before archiving?
> 
> Reply 'approve' to proceed with archiving, or give me corrections."

Do not proceed until the user explicitly approves.

### Step 4: Update CLAUDE.md

1. Read the current `.claude/CLAUDE.md`.
2. Remove `<change-id>` from the "Active Changes" section.
3. Add a brief entry to the "Completed Changes" section (or create one if it does not exist):
   ```
   - <change-id>: <one-line summary> -- archived <date>
   ```
4. If the Migration Journal contains architecture-level lessons learned that affect the project overview (e.g., "switch from X to Y"), update the relevant CLAUDE.md sections to reflect the new state.
5. Commit the CLAUDE.md update:
   ```
   git add .claude/CLAUDE.md
   git commit -m "docs: update CLAUDE.md -- archive <change-id>"
   ```

### Step 5: Run openspec archive

Execute the automated archival:

```
openspec archive <change-id>
```

This command:
- Moves all `specs/<change-id>/` artifacts to `archive/<change-id>/`
- Consolidates flat spec files (`specs/prd/<change-id>.md`, `specs/plan/<change-id>.md`, etc.) into the archive
- Sets the change status to `archived`
- Preserves the full file structure for audit trail

If `openspec archive` is not available, manually:
```
mkdir -p archive/<change-id>
cp -r specs/<change-id>/* archive/<change-id>/
cp specs/prd/<change-id>.md archive/<change-id>/ 2>/dev/null || true
cp specs/plan/<change-id>.md archive/<change-id>/ 2>/dev/null || true
# ... repeat for api/, design/, test/, release/
```

Add the Migration Journal to the archive:
```
cp migration-journal-<change-id>.md archive/<change-id>/MIGRATION.md
```

### Step 6: Cleanup

Remove the working artifacts after confirming they are safely in `archive/<change-id>/`:

```
rm -rf specs/<change-id>
rm -f specs/prd/<change-id>.md
rm -f specs/plan/<change-id>.md
rm -f specs/api/<change-id>.yaml
rm -f specs/design/<change-id>.md
rm -f specs/test/<change-id>.md
rm -f specs/release/<change-id>.md
```

**Safety Check**: Before any `rm`, verify the corresponding file exists in `archive/<change-id>/`. If the archive copy is missing, do NOT delete. Copy it first.

### Step 7: Commit the Archive

```
git add archive/<change-id>/
git add specs/  # for any deleted spec files
git commit -m "chore: archive change <change-id>

Migration Journal: archive/<change-id>/MIGRATION.md
Full record: archive/<change-id>/"
```

### Step 8: Run Final Phase 5 Gates

Execute `run_phase_gates 5 "<change-id>"` for a final audit:
- `gate_full_diagnostics` -- aggregate diagnostic pass
- `gate_all_gates_pass` -- meta-gate confirming all prior phases passed
- `gate_destructive_op` -- no destructive operations in cleanup
- `gate_archive` -- verifies `archive/<change-id>/` contains `prd.md` and `tasks.md` at minimum

All must PASS.

## Key Difference from Other Base Systems

AICAM and similar bases use `.agents/` directory for archival and require manual migration scripts. THIS base:
- Uses **OpenSpec archive**: `openspec archive <change-id>` handles the full move automatically.
- Archives to **`archive/<change-id>/`**, not `.agents/` or custom paths.
- Produces a **Migration Journal** (compressed knowledge) rather than a raw changelog.
- Updates **CLAUDE.md** as part of the archival process, keeping the AI context current.
- Enforces Phase 5 gates via `run_phase_gates 5` before completion.

## Hard Gate

- All 4 Phase 5 gates (`run_phase_gates 5`) must PASS
- `archive/<change-id>/MIGRATION.md` (Migration Journal) must exist
- `archive/<change-id>/prd.md` and `archive/<change-id>/tasks.md` must exist
- CLAUDE.md must be updated and committed
- All working `specs/<change-id>/` artifacts must be cleaned up (not left as orphans)

## Output

```
## Archived Change: <change-id>

### Archive Location
archive/<change-id>/

### Migration Journal
archive/<change-id>/MIGRATION.md

### CLAUDE.md Update
Active Changes: <change-id> removed
Completed Changes: <change-id> added

### Phase 5 Gate Results
| Gate | Result |
|------|--------|
| Full Diagnostics | PASS |
| All Gates Pass | PASS |
| Destructive Op | PASS |
| Archive | PASS |

### Final Status
Change <change-id> is now ARCHIVED. Full record preserved at archive/<change-id>/.
```
