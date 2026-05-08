---
description: "Quick emergency fix with minimal scope -- L0 mode, no full planning cycle, quality gates still apply"
argument-hint: "[problem description]"
---

# /hotfix: L0 Emergency Fix -- Targeted Repair Without Full Planning

## Mission

Deliver a targeted, minimal fix for a production issue without the full Phase 1-5 planning cycle. Hotfix operates at L0 (zero-config) level: it bypasses the PRD and plan phases but NOT the quality gates. The fix must be narrow in scope, tested, and documented. If the fix requires more than 3 files, introduces a new API, needs a database migration, or changes a spec, the command must redirect to `/discover` for a proper tracked change.

## Core Principle

**Speed does not excuse sloppiness.** A hotfix is a surgical strike, not a free pass. TDD still applies (test the bug, then fix it). Pre-commit hooks still run. The fix must be reproducible, root-caused, and verified. The only thing relaxed is the planning overhead -- not the code quality.

## Process

### Step 0: Scope Check (Hard Boundary)

Before any code changes, validate the hotfix scope against these constraints:

| Constraint | Limit | If Exceeded |
|-----------|-------|-------------|
| Files changed | <= 3 files | Redirect to `/discover` for a proper PRD spec |
| New API surface | None | Redirect to `/discover` |
| Database migration | None | Redirect to `/discover` |
| Spec change | None (no PRD/plan/spec file modification) | Redirect to `/discover` |
| Estimated fix time | < 2 hours | If larger, this is not a hotfix -- redirect to `/discover` |

If ANY constraint is violated, output: "This exceeds hotfix scope. Redirecting to `/discover` to create a proper tracked change." Then stop.

### Step 1: Reproduce the Bug

1. Activate `systematic-debugging` skill in diagnostic mode.
2. Gather the exact steps to reproduce from the user or from error logs.
3. Reproduce the failure locally or against a staging environment.
4. Capture the reproduction evidence:
   - Error message / stack trace
   - Input that triggers the bug
   - Expected vs. actual behavior
5. Document reproduction as: "Bug confirmed: <one-line description>. Reproduced via: <steps>."

### Step 2: Root Cause Analysis

1. Trace the code path from the trigger point to the failure.
2. Identify the exact line(s) where behavior diverges from expectation.
3. Determine WHY the divergence exists (logic error, missing null check, race condition, config drift, dependency version mismatch).
4. Document root cause as: "Root cause: <file>:<line> -- <explanation of why the bug exists>."

### Step 3: Write the Regression Test (RED)

Write a test that:
- Reproduces the exact bug condition from Step 1
- Asserts the CORRECT behavior (which currently fails)
- Is minimal and focused on this specific bug only

Run the test and confirm it FAILS. Document the RED output:
```
Test: <test-file>:<test-name>
Result: FAIL
Failure: <key assertion error>
```

### Step 4: Apply the Minimal Fix (GREEN)

Write the minimal code change to pass the regression test:
- Change only the file(s) identified in the root cause analysis
- Do NOT refactor adjacent code, rename variables, or "clean up while we're here"
- Do NOT expand scope beyond the bug fix

Run the regression test and confirm it PASSES. Document the GREEN output:
```
Test: <test-file>:<test-name>
Result: PASS
Fix: <file>:<line> -- changed <before> to <after>
```

### Step 5: Run Full Regression Suite

Run the entire test suite to ensure the fix does not break anything:
```
# Example
npx vitest run
```

If any previously passing test now fails, the fix is not minimal enough -- investigate and adjust. Do not proceed with regressions.

### Step 6: Smoke Test (Manual or Automated)

Verify the fix works in a realistic environment:
1. If Playwright MCP is available: run critical-path smoke tests against the affected flow.
2. If not: describe a manual smoke test the user should perform.
3. Document the smoke test result: "Smoke test: <test description> -- PASS/FAIL."

### Step 7: Commit

```
git add <test-file> <source-file(s)>
git commit -m "fix: <brief bug description>

Root cause: <file>:<line> -- <explanation>
TDD Log:
- RED: <test-file> -- failed reproducing the bug
- GREEN: same test -- passed after fix
Smoke test: PASS
Hotfix scope: <N> file(s) changed"
```

The pre-commit hook runs: format, lint, type-check, secret-scan. The commit-msg hook enforces `fix:` prefix. Note: the TDD_GATE hook runs but hotfix is exempt from the strict "test must be in same commit" check when `enableLevel` is L0.

## Safety Rules

1. **Narrow scope is paramount.** The moment a hotfix threatens to touch a 4th file or introduce a new concept, stop and redirect.
2. **TDD is non-negotiable.** The regression test is the proof that the bug existed and that the fix works. Without it, there is no way to prevent regression.
3. **No silent refactoring.** Even if the adjacent code is ugly, leave it alone. Refactoring belongs in a planned change.
4. **Hotfix is not a shortcut for features.** If the "bug" is actually a missing feature (something that never worked), this is a change -- redirect to `/discover`.

## Hard Gate

Before the commit is accepted:
- Scope check MUST pass (<= 3 files, no API/DB migration, no spec change)
- Regression test MUST exist and MUST have been observed to both FAIL (reproducing the bug) and PASS (after fix)
- Full test suite MUST pass with zero regressions
- Smoke test MUST pass

## Output

```
## Hotfix Summary

**Bug**: <one-line description>
**Root Cause**: <file>:<line> -- <explanation>
**Fix**: <file>:<line> -- changed <before> to <after>
**Files Changed**: <N> file(s)
**Scope**: Hotfix (L0)

### TDD Log
- **RED**: `<test-file>` -- `<test-name>` FAILED: `<assertion error>`
- **GREEN**: `<test-file>` -- `<test-name>` PASSED

### Smoke Test Log
- **Test**: <description>
- **Result**: PASS
- **Evidence**: <Playwright trace path or manual test confirmation>

### Commit
- **SHA**: `<commit-hash>`
- **Message**: `fix: <description>`

### Recommendation
<If the fix should become a tracked change for root cause elimination, suggest /discover>
```
