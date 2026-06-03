---
description: "Run 7-step verification: contract, security, smoke test, diagnostics, code review; produce verification report"
argument-hint: "[change-id]"
---

# /verify: Start Phase 4 -- Seven-Step Verification

## Mission

Execute a comprehensive seven-step verification of the completed implementation from Phase 3. This command drives the entire Phase 4 (Verify) cycle: run contract checks, security scans, smoke tests, full diagnostics, code review, and spec validation. Produce a verification report and transition the state to `release`.

## Core Principle

**Evidence before claims.** Every verification step must produce concrete evidence (pass/fail output, test results, scan reports). Verbal "it looks good" is not verification. If a step cannot produce evidence, it must be explicitly marked as skipped with justification.

## Process

### Step 0: Pre-Condition Check

Before verification, verify:

1. `specs/plan/<change-id>.md` MUST exist with a completed task list (all checkboxes checked).
2. Check state: `bash .claude/scripts/aiit-state.sh get <change-id> phase` should return `execute`.
3. Run `run_phase_gates 3 "<change-id>"` to confirm Phase 3 gates pass.

If any pre-condition fails, stop. Direct the user back to `/execute` first.

### Step 1: Contract Check (L2+)

For changes that modify API contracts:

```bash
# Check if API spec exists
ls specs/api/<change-id>.yaml 2>/dev/null

# If exists, run breaking change detection
oasdiff breaking <base-spec> specs/api/<change-id>.yaml
```

**Evidence**: oasdiff output (breaking changes or clean).
**Skip if**: No API spec exists, no API changes.

### Step 2: Security Scan (L2+)

```bash
# SAST scan
semgrep --config=auto

# Dependency audit
npm audit --audit-level=moderate   # or pip-audit, cargo audit
```

**Evidence**: semgrep results + audit results.
**Skip if**: Tools not installed (mark as WARN).

### Step 3: Smoke Test

```bash
# Build check
npm run build  # or mvn compile, go build, cargo check

# Run test suite
npm test       # or mvn test, go test, cargo test
```

**Evidence**: Build output + test results.
**Fail if**: Build fails or any test fails.

### Step 4: Full Diagnostics

For TypeScript projects:
```bash
# TypeScript LSP diagnostics
# Use MCP: typescript-lsp get_all_diagnostics
```

For other languages, run the project's type-check or lint command.

**Evidence**: Zero errors (warnings OK).
**Fail if**: Any type errors found.

### Step 5: Code Review

Activate the `code-review` skill or `requesting-code-review` skill. Review:
- All changes against the plan spec
- Unintended changes outside file scope
- Code quality issues
- Missing edge cases

**Evidence**: Code review summary with findings.
**Fail if**: Critical issues found (fix before proceeding).

### Step 6: Spec Validation

```bash
# Final spec consistency check
openspec validate specs/plan/<change-id>.md
openspec diff <change-id>
```

**Evidence**: openspec output (ALIGNED or drift level).
**Fail if**: HIGH drift detected.

### Step 7: Write Verification Report

Compile all evidence into a verification report:

Write to `specs/release/<change-id>.md`:
```markdown
# Verification Report: <change-title>

**Change ID:** <change-id>
**Date:** <date>
**Status:** verified

## Gate Results
| Gate | Result | Evidence |
|------|--------|----------|
| Contract | PASS/FAIL/SKIP | <summary> |
| Security | PASS/FAIL/SKIP | <summary> |
| Smoke Test | PASS/FAIL | <test results> |
| Full Diagnostics | PASS/FAIL | <diagnostics> |
| Code Review | PASS/FAIL | <review summary> |
| Spec Validation | PASS/FAIL | <drift level> |

## Summary
<1-2 paragraph summary of verification results>
```

### Step 8: Set Verification Report and Transition

```bash
# Set the verification report path in state
bash .claude/scripts/aiit-state.sh set <change-id> verify.report "specs/release/<change-id>.md"

# Transition execute → verify
bash .claude/scripts/aiit-guard.sh check execute verify "<change-id>" --apply

# Transition verify → release
bash .claude/scripts/aiit-guard.sh check verify release "<change-id>" --apply

# Verify final state
bash .claude/scripts/aiit-state.sh get <change-id> phase
# Should output: release
```

Commit everything:
```bash
git add specs/release/<change-id>.md
git add specs/<change-id>/.aiit.yaml
git commit -m "spec: verification report for <change-id>"
```

## Hard Gate

All seven verification steps must produce evidence. The verification report must be written and committed. State must be transitioned to `release`. Do not hand off to Phase 5 (`/close-phase`) until these conditions are satisfied.

## Output

```
specs/release/<change-id>.md  — Verification report with evidence
```

State: `<change-id>` phase = `release`, verify.report = path to report
