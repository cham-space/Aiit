# Spec Drift Guide

## What Is Spec Drift?

Spec drift occurs when the implementation code diverges from the specification
(PRD, plan, API contract, or test strategy) defined in `specs/<change-id>/`.
This breaks the fundamental contract of AI-assisted development: the spec is
the source of truth, and the code must faithfully implement it.

Drift can happen in either direction:
- **Forward drift**: Code was changed without updating the spec.
- **Reverse drift**: Spec was updated, but code was not regenerated to match.

Both are violations of the Phase 3 iron rule: every line of code must be
traceable back to a spec artifact.

---

## Drift Severity Levels

The `openspec diff <change-id>` command (or the `check_spec_drift` function
in `.githooks/lib/l2-checks.sh`) classifies drift into three levels.

### LOW -- Warning Only

> **Threshold:** Less than 10% of spec points show deviation.
> **Action:** Continue development. Log the deviation in the change's notes.
> **Typical signals:** Whitespace, formatting, minor comment mismatches,
> one or two parameter defaults off.

The hook prints a warning but does not block the commit or phase transition.
Treat LOW drift as a reminder to double-check your work at the next review.

### MEDIUM -- Alert, Review Required

> **Threshold:** 10% to 30% of spec points show deviation.
> **Action:** Pause and review with the user (or team lead for L2+).
> Decide on one of the three resolution options (see below) before
> continuing. The hook prints a prominent warning.

MEDIUM drift means the spec and implementation are telling different stories.
Do NOT ignore it. Even if the deviation is intentional, the spec must be
updated so future readers (and future AI agents) see a consistent picture.

### HIGH -- BLOCK, Must Resolve Before Commit

> **Threshold:** Greater than 30% of spec points show deviation.
> **Action:** **BLOCKED.** The `check_spec_drift` function returns exit code 1,
> which causes `run_phase_gates 4` to fail. You cannot commit, push, or
> advance to the next phase until drift is resolved.

HIGH drift means the implementation and spec have diverged so significantly
that you are effectively building something different from what was planned.
This requires a deliberate decision -- either the plan was wrong (update the
spec) or the implementation went off the rails (revert/rewrite the code).

---

## How to Resolve Drift

### Option A: Update Spec to Match Implementation (Intentional Change)

Use this when the implementation is correct and the spec is stale.

1. Identify which spec artifacts have drifted (PRD, plan, API contract, test
   strategy).
2. Update the spec files in `specs/<change-id>/` to reflect the current
   implementation.
3. Add a changelog entry in the spec documenting why the change was made
   (e.g., "Discovered during implementation that Redis is a better fit than
   PostgreSQL for session storage -- updated plan section 3.2").
4. Re-run `openspec diff <change-id>` -- drift should now be LOW or ALIGNED.

### Option B: Revert Implementation to Match Spec

Use this when the implementation drifted unintentionally or when the spec
represents the authoritative design.

1. Use `git diff` to identify the deviated code sections.
2. Revert those sections to match the spec.
3. If the spec is ambiguous, do NOT revert -- instead switch to Option C
   (see below). Ambiguous specs should be clarified first.
4. Re-run `openspec diff <change-id>` -- drift should be ALIGNED.

### Option C: Split the Difference (Update Both)

Use this when both the spec and the implementation are partially right.

1. Review the spec and implementation side-by-side.
2. Identify which spec points are genuinely wrong (outdated assumptions,
   invalid constraints) and which implementation decisions are wrong
   (hasty shortcuts, misunderstood requirements).
3. Update the spec to correct the wrong spec points.
4. Modify the implementation to match the corrected spec.
5. The result should be a spec and implementation that both represent the
   best design.
6. Re-run `openspec diff <change-id>` -- drift should be ALIGNED.

---

## Common Causes of Drift and Prevention

| Cause | Prevention |
|---|---|
| TDD skipped -- implementation written before spec/test | Phase 3 iron rule: test MUST fail before implementation. The pre-commit TDD_GATE enforces this. |
| Spec too vague -- AC not quantifiable | Phase 1 Testability Gate checks for quantifiable AC. Use specific numbers, percentages, and thresholds. |
| "Quick fix" without spec update | Every change, even a one-line fix, should be reflected in the spec if it changes behavior. For true hotfixes, use L0 and document post-hoc. |
| Subagent working from stale spec | L2+ parallel agents pull the latest spec before each task. Always run `openspec diff` at the start of a subagent task. |
| Scope creep during implementation | Phase 2 File Scope Gate prevents this. If new requirements emerge, return to Phase 1, not Phase 3. |
| Merged branches with conflicting spec changes | Rebase and re-resolve spec conflicts before code conflicts. |
| Design spec changed after implementation began | Phase 2 design spec is committed before Phase 3 begins. Late-breaking design changes require returning to Phase 2. |

---

## Integration with L2 Checks Layer

The `check_spec_drift` function in `.githooks/lib/l2-checks.sh` is the
runtime enforcer. Here is how it integrates:

```
Phase 3 (Execute):
  - After each TDD cycle (red-green-refactor), `openspec diff` runs
    as a post-write hook
  - LOW: continue to next task
  - MEDIUM: warn, log, user decides
  - HIGH: block, must resolve before git commit

Phase 4 (Verify):
  - run_phase_gates 4 calls gate_spec_drift (which delegates to L2)
  - Contract Gate + Security Gate + Smoke Test Gate must all pass
  - If spec drift is still HIGH from Phase 3, the verify phase cannot start

Phase 5 (Release):
  - Final All-Gates-Pass check includes a re-run of spec drift
  - Archive Gate ensures the archived spec matches the merged code
```

The `check_spec_drift` function works as follows:

1. Calls `openspec diff <change-id>` if the `openspec` CLI is available.
2. Parses the output for HIGH / MEDIUM / ALIGNED keywords.
3. HIGH returns exit code 1 (fatal); MEDIUM returns 0 with a warning;
   ALIGNED returns 0 with a pass message.
4. If `openspec` is not installed, the function warns and skips the check
   (non-blocking).

---

## Quick Reference (for CLAUDE.md Extraction)

Spec drift = implementation diverged from spec. Three levels: LOW (<10%, warn, continue), MEDIUM (10-30%, review with user, update spec or revert code), HIGH (>30%, BLOCK, must resolve before commit). Resolve via: A) update spec, B) revert code, C) fix both. Enforced by `check_spec_drift` in `.githooks/lib/l2-checks.sh` via `openspec diff`. Always run before committing in Phase 3, and as part of `run_phase_gates 4` in Phase 4.
