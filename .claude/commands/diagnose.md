---
description: "Non-destructive comprehensive health audit of OpenSpec, gates, skills, and MCP infrastructure"
argument-hint: "[optional: specific check to focus on, or leave empty for full audit]"
---

# /diagnose: Comprehensive Health Check -- OpenSpec + Gates + Skills + MCPs

## Mission

Perform a non-destructive, read-only audit of every layer of the AI Development Base: OpenSpec configuration, active change lifecycle artifacts, quality gate setups, git hook scripts, security tooling, skill inventory, MCP server connectivity, spec drift status, and per-phase artifact completeness. This command writes nothing, modifies nothing, and makes no code changes. It produces a single unified health report with pass/fail/warn status for each check and actionable remediation steps for anything that is not passing.

## Core Principle

**Don't touch, just look.** Every check is read-only. No file creation, no config modification, no side effects. If a check reveals a problem, the output describes exactly what is wrong and how to fix it -- but the fix itself requires a separate command (typically a tracked change via `/discover`). This command can be run at any time, in any phase, at any level, with zero risk.

## Process

### Check 1: .claude/CLAUDE.md Health

Verify the AI instruction file is present, well-structured, and current:

- Does `.claude/CLAUDE.md` exist?
- Does it contain the required sections: project overview, build/test commands, architecture summary, constraints?
- Is there an "Active Changes" section tracking current change lifecycle entries?
- Does the file modification date suggest it is reasonably current (not stale)?

```
[PASS/FAIL/WARN] .claude/CLAUDE.md: <details>
```

### Check 2: Active Change Lifecycle Scan

Scan `specs/` for all active (non-archived) change entries:

- List all `specs/<change-id>/` directories
- For each, report current status by reading the change metadata:
  - `proposed` -- PRD exists but not yet planned
  - `planned` -- plan exists but not yet executed
  - `executed` -- code complete but not yet archived
- Report orphaned artifacts (e.g., a plan without a PRD, a task file without a plan)
- Check for consistency between `specs/prd/` and `specs/plan/` naming conventions

```
[PASS/FAIL/WARN] Active Changes: <N> active changes found
  - <change-id>: status=<status>, artifacts=<list>
```

### Check 3: Gate Configuration

Audit the quality gate infrastructure:

- Does `.githooks/config` exist and is it parseable?
- List all configured gate toggles (HOOK_TDD_GATE, HOOK_COVERAGE, HOOK_SECURITY, etc.) and their current values
- Verify `.githooks/lib/gates.sh` is syntactically valid (run `bash -n`)
- Run `run_phase_gates 0 ""` to test basic gate dispatch (directory structure + hook activation)
- Report which gates are enabled at the current `enableLevel`

```
[PASS/FAIL/WARN] Gate Configuration: <N>/18 gate functions defined
  Config file: <present/missing>
  Syntax: <valid/invalid>
  Enabled gates at current level (L<N>): <list>
```

### Check 4: Hook Script Health

Validate all git hook scripts:

- Run `bash -n` on each: `pre-commit`, `commit-msg`, `pre-push`, `lib/gates.sh`, `lib/l2-checks.sh`, `lib/utils.sh`
- Verify all hook scripts are executable (`chmod +x`)
- Confirm `git config core.hooksPath` equals `.githooks`
- List which hooks are active per the current level in `settings.json`

```
[PASS/FAIL/WARN] Hook Scripts:
  pre-commit: <syntax-ok/fail>, <executable-yes/no>
  commit-msg: <syntax-ok/fail>, <executable-yes/no>
  pre-push: <syntax-ok/fail>, <executable-yes/no>
  hooksPath: <.githooks/correct/incorrect>
```

### Check 5: Security Tooling Availability

Check for security scanning tooling required by hooks:

- `gitleaks`: `command -v gitleaks`
- `semgrep`: `command -v semgrep`
- `npm audit` or `pip-audit`: dependency scanning availability
- `oasdiff`: API contract breaking change detection availability

For each missing tool, output the installation command.

```
[PASS/FAIL/WARN] Security Tooling:
  gitleaks: <available/not-installed> -- install: <cmd>
  semgrep: <available/not-installed> -- install: pip install semgrep
  oasdiff: <available/not-installed> -- install: go install github.com/tufin/oasdiff/cmd/oasdiff@latest
```

### Check 6: Skills Inventory

Validate the Superpowers + custom skill inventory:

- List all skills registered in `.claude/settings.json` `phaseSkillMapping`
- Compare against the canonical list from WORKFLOW.md
- Flag any skills referenced in phase configs that are not available
- Check for deprecated skill aliases (e.g., `superpowers:brainstorm:brainstorm` vs `superpowers:brainstorming`)
- Report skill coverage per phase: "Phase 1 has 3/3 skills available"

```
[PASS/FAIL/WARN] Skills Inventory:
  Total registered: <N>
  Missing from WORKFLOW.md reference: <list>
  Deprecated aliases detected: <list>
  Phase coverage: P0=<N>/<M>, P1=<N>/<M>, ..., P5=<N>/<M>
```

### Check 7: MCP Server Availability

Test connectivity to all configured MCP servers:

- **Playwright**: Check if browser_navigate, browser_snapshot tools respond
- **Figma**: Check if get_design_context, get_screenshot tools respond
- **Serena**: Check if find_symbol, get_symbols_overview tools respond
- **TypeScript LSP**: Check if get_diagnostics, get_all_diagnostics tools respond
- **Pencil**: Check if get_editor_state, open_document tools respond (if configured)

For each MCP, test a read-only call. Report pass/fail and the server's reported status.

```
[PASS/FAIL/WARN] MCP Servers:
  Playwright: <available/unavailable> -- <note>
  Figma: <available/unavailable> -- <note>
  Serena: <available/unavailable> -- <note>
  TypeScript LSP: <available/unavailable> -- <note>
  Pencil: <available/unavailable/skip> -- <note>
```

### Check 8: Spec Drift Status (Per Active Change)

For each active change with implementation code present:

- Run `openspec diff <change-id>` to assess ALIGNED/MEDIUM/HIGH drift
- Check `specs/<change-id>/plan-scope.txt` exists (if executed/planned)
- Report drift and scope documentation status per change

```
[PASS/FAIL/WARN] Spec Drift:
  <change-id>: ALIGNED | scope-documented: YES
  <change-id>: MEDIUM | scope-documented: NO -- action: create plan-scope.txt
```

### Check 9: Phase Artifact Completeness

For each active change, cross-reference artifacts against the expected set for its current status:

| Status | Expected Artifacts |
|--------|-------------------|
| `proposed` | `specs/prd/<change-id>.md` |
| `planned` | above + `specs/plan/<change-id>.md`, `specs/<change-id>/tasks.md` |
| `executed` | above + `specs/<change-id>/changed-files.txt`, test files, source files |
| `archived` (redirects to `archive/`) | all above + `archive/<change-id>/` |

Flag missing artifacts per change.

```
[PASS/FAIL/WARN] Phase Artifacts:
  <change-id> (planned): PRD=OK, Plan=OK, Tasks=OK, API-spec=MISSING, Design-spec=MISSING
```

## Hard Gate

This command has no hard gate -- it is a pure diagnostic and always completes. However, it MUST NOT modify any file. If any check would require a write operation to complete, skip that sub-check and mark it as `[WARN] -- requires write access`. The health report is always produced regardless of failures found.

## Output

```
# AI Development Base -- Health Report
Generated: <timestamp>
Level: L<N>

## Summary
<Pass>/<Total> checks passing. <Fail> critical failures. <Warn> warnings.

## Detailed Results

### 1. .claude/CLAUDE.md Health
[PASS/FAIL/WARN] <details>

### 2. Active Change Lifecycle
[PASS/FAIL/WARN] <details -- include per-change status table>

### 3. Gate Configuration
[PASS/FAIL/WARN] <details>

### 4. Hook Script Health
[PASS/FAIL/WARN] <details>

### 5. Security Tooling
[PASS/FAIL/WARN] <details>

### 6. Skills Inventory
[PASS/FAIL/WARN] <details>

### 7. MCP Servers
[PASS/FAIL/WARN] <details>

### 8. Spec Drift Status
[PASS/FAIL/WARN] <details>

### 9. Phase Artifact Completeness
[PASS/FAIL/WARN] <details>

## Remediation Recommendations
<Numbered list of concrete, executable fix commands for each FAIL/WARN item>
```
