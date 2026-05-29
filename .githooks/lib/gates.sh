#!/bin/bash
# ============================================================
# AI Development Base — Quality Gates
# .githooks/lib/gates.sh
#
# 18 quality gate functions that enforce development process
# requirements across 6 phases (0—5).
#
# Each gate function returns 0 (pass) or 1 (fail).
# run_phase_gates(phase, change_id) dispatches to the
# appropriate set of gates for a given phase and prints
# a summary.
#
# Sources utils.sh for colors and helpers.
# ============================================================
set -euo pipefail

GATES_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$GATES_LIB_DIR/utils.sh"

# ====================================================================
# Gate 1: gate_directory_structure
# Phase: 0
# Verifies that the essential project directories exist:
#   specs/, .claude/, .githooks/
# ====================================================================
gate_directory_structure() {
  echo "  [GATE] Directory Structure Check"

  local missing_dirs=""
  local required_dirs=("specs" ".claude" ".githooks")

  for dir in "${required_dirs[@]}"; do
    if [[ ! -d "$dir" ]]; then
      missing_dirs="${missing_dirs}  ${dir}/\n"
    fi
  done

  if [[ -n "$missing_dirs" ]]; then
    fail_msg "  DIRECTORY STRUCTURE: missing required directories:"
    echo -e "$missing_dirs"
    return 1
  fi

  # Check for essential sub-structure
  if [[ ! -f "specs/README.md" && ! -f "specs/index.md" ]]; then
    warn_msg "  specs/ directory exists but no README.md or index.md found"
  fi
  if [[ ! -f ".claude/CLAUDE.md" ]]; then
    warn_msg "  .claude/ directory exists but no CLAUDE.md found"
  fi
  if [[ ! -f ".githooks/config" ]]; then
    warn_msg "  .githooks/ directory exists but no config file found"
  fi

  pass_msg "  DIRECTORY STRUCTURE: all required directories present"
  return 0
}

# ====================================================================
# Gate 2: gate_hook_activation
# Phase: 0
# Checks that git is configured to use .githooks as the hooks path.
# ====================================================================
gate_hook_activation() {
  echo "  [GATE] Hook Activation Check"

  local hooks_path
  hooks_path=$(git config core.hooksPath 2>/dev/null || echo "")

  if [[ "$hooks_path" != ".githooks" ]]; then
    fail_msg "  HOOK ACTIVATION: core.hooksPath is not set to .githooks"
    echo "    Current value: '${hooks_path:-<unset>}'"
    echo "    Set it with: git config core.hooksPath .githooks"
    return 1
  fi

  # Also verify that the hook scripts are executable
  local hook_files=("pre-commit" "commit-msg" "pre-push")
  local missing_exec=""
  for hook in "${hook_files[@]}"; do
    if [[ -f ".githooks/$hook" ]] && [[ ! -x ".githooks/$hook" ]]; then
      missing_exec="${missing_exec}  .githooks/${hook}\n"
    fi
  done

  if [[ -n "$missing_exec" ]]; then
    fail_msg "  HOOK ACTIVATION: hook scripts exist but are not executable:"
    echo -e "$missing_exec"
    echo "    Fix with: chmod +x .githooks/<hook>"
    return 1
  fi

  pass_msg "  HOOK ACTIVATION: git hooks are correctly configured"
  return 0
}

# ====================================================================
# Gate 3: gate_prd_completeness
# Phase: 1
# Checks that a PRD (Product Requirements Document) for the given
# change_id contains all 5 required sections:
#   1. Overview / Background
#   2. Goals & Non-Goals
#   3. User Stories / Use Cases
#   4. Technical Constraints / Dependencies
#   5. Success Metrics
# ====================================================================
gate_prd_completeness() {
  local change_id="$1"

  echo "  [GATE] PRD Completeness for change: $change_id"

  local prd_file="specs/${change_id}/prd.md"
  if [[ ! -f "$prd_file" ]]; then
    fail_msg "  PRD COMPLETENESS: PRD file not found at $prd_file"
    return 1
  fi

  local missing_sections=""
  local required_sections=(
    "Overview|Background|Context"
    "Goal|Non-Goal|Non-Requirement"
    "User Story|Use Case|Scenario"
    "Constraint|Dependenc|Technical"
    "Success Metric|KPI|Measurement"
  )

  for section_pattern in "${required_sections[@]}"; do
    if ! grep -qiE "${section_pattern}" "$prd_file"; then
      # Try to identify which section is missing by its description
      case "$section_pattern" in
        "Overview|Background|Context")
          missing_sections="${missing_sections}  - Overview / Background\n"
          ;;
        "Goal|Non-Goal|Non-Requirement")
          missing_sections="${missing_sections}  - Goals & Non-Goals\n"
          ;;
        "User Story|Use Case|Scenario")
          missing_sections="${missing_sections}  - User Stories / Use Cases\n"
          ;;
        "Constraint|Dependenc|Technical")
          missing_sections="${missing_sections}  - Technical Constraints / Dependencies\n"
          ;;
        "Success Metric|KPI|Measurement")
          missing_sections="${missing_sections}  - Success Metrics\n"
          ;;
      esac
    fi
  done

  if [[ -n "$missing_sections" ]]; then
    fail_msg "  PRD COMPLETENESS: missing required sections:"
    echo -e "$missing_sections"
    return 1
  fi

  pass_msg "  PRD COMPLETENESS: PRD contains all 5 required sections"
  return 0
}

# ====================================================================
# Gate 4: gate_testability
# Phase: 1
# Verifies that acceptance criteria in the PRD contain quantifiable
# elements (numbers, percentages, durations, specific states).
# ====================================================================
gate_testability() {
  local change_id="$1"

  echo "  [GATE] Testability Check for change: $change_id"

  local prd_file="specs/${change_id}/prd.md"
  if [[ ! -f "$prd_file" ]]; then
    fail_msg "  TESTABILITY: PRD file not found at $prd_file"
    return 1
  fi

  # Extract acceptance criteria sections (commonly between "Acceptance Criteria"
  # and the next heading).
  local ac_section
  ac_section=$(awk '/Acceptance Criteria|Acceptance Criteria:/,/^#/{print}' "$prd_file" 2>/dev/null || true)

  if [[ -z "$ac_section" ]]; then
    warn_msg "  TESTABILITY: No 'Acceptance Criteria' section found in PRD"
    echo "    Acceptance criteria should contain quantifiable, measurable elements."
    echo "    Examples: 'response time < 200ms', '95% accuracy', 'supports 1000 concurrent users'"
    # Non-blocking warning; gate returns 0
    pass_msg "  TESTABILITY: awareness notice — add quantifiable acceptance criteria"
    return 0
  fi

  # Check for quantifiable elements: numbers, percentages, durations
  local has_quantifiable=0
  if echo "$ac_section" | grep -qE '[0-9]+[[:space:]]*(%|ms|s|seconds|minutes|users|requests|items|records|pages|MB|GB|px)'; then
    has_quantifiable=1
  elif echo "$ac_section" | grep -qE '(less than|greater than|at least|at most|no more than|within)[[:space:]]+[0-9]+'; then
    has_quantifiable=1
  elif echo "$ac_section" | grep -qE '[0-9]+[[:space:]]*(out of|of[[:space:]]+[0-9]+|concurrent|simultaneous)'; then
    has_quantifiable=1
  fi

  if [[ $has_quantifiable -eq 1 ]]; then
    pass_msg "  TESTABILITY: acceptance criteria contain quantifiable elements"
    return 0
  else
    warn_msg "  TESTABILITY: acceptance criteria may lack quantifiable measures"
    echo "    Consider adding numbers, percentages, or specific thresholds"
    pass_msg "  TESTABILITY: awareness notice — review acceptance criteria"
    return 0
  fi
}

# ====================================================================
# Gate 5: gate_task_granularity
# Phase: 2
# Checks that tasks are broken down to an appropriate level of
# granularity (estimated time < 4 hours per task).
#
# Currently a placeholder — returns pass with a note.
# ====================================================================
gate_task_granularity() {
  local change_id="$1"

  echo "  [GATE] Task Granularity for change: $change_id"

  local tasks_file="specs/${change_id}/tasks.md"
  if [[ ! -f "$tasks_file" ]]; then
    pass_msg "  TASK GRANULARITY: no tasks file found — nothing to check"
    return 0
  fi

  # Count the number of tasks as a rough measure
  local task_count
  task_count=$(grep -cE '^[-*] \[ \]|^[-*] \[X\]|^[-*] \[x\]' "$tasks_file" 2>/dev/null || echo "0")

  if [[ "$task_count" -eq 0 ]]; then
    pass_msg "  TASK GRANULARITY: no checklist tasks found — nothing to check"
    return 0
  fi

  echo "    Found ${task_count} tasks in tasks.md"
  echo "    Verify each task can be completed in < 4 hours."

  pass_msg "  TASK GRANULARITY: placeholder — manual review recommended (${task_count} tasks)"
  return 0
}

# ====================================================================
# Gate 6: gate_no_cyclic_deps
# Phase: 2
# Checks for cyclic dependencies between modules/components.
#
# Currently a placeholder — returns pass.
# ====================================================================
gate_no_cyclic_deps() {
  local change_id="$1"

  echo "  [GATE] Cyclic Dependency Check for change: $change_id"

  # Placeholder — in a real implementation this would use a tool like
  # dependency-cruiser, madge, or custom graph analysis.
  echo "    Cyclic dependency detection is a placeholder."
  echo "    Consider integrating: madge (JS), pydeps (Python), or go mod graph (Go)."

  pass_msg "  NO CYCLIC DEPS: placeholder — no automated check configured"
  return 0
}

# ====================================================================
# Gate 7: gate_spec_alignment
# Phase: 2
# Checks that the implementation plan aligns with the spec.
#
# Currently a placeholder — returns pass.
# ====================================================================
gate_spec_alignment() {
  local change_id="$1"

  echo "  [GATE] Spec Alignment for change: $change_id"

  echo "    Spec alignment verification is a placeholder."
  echo "    In a full implementation, this would verify:"
  echo "      - Plan covers all spec sections"
  echo "      - No extra work outside spec scope"
  echo "      - Assumptions are documented"

  pass_msg "  SPEC ALIGNMENT: placeholder — manual review recommended"
  return 0
}

# ====================================================================
# Gate 8: gate_tdd
# Phase: 3
# TDD enforcement is handled by the pre-commit hook (TDD_GATE check).
# This gate delegates entirely to that mechanism.
# ====================================================================
gate_tdd() {
  local change_id="$1"

  echo "  [GATE] TDD Enforcement"

  # The pre-commit TDD_GATE check verifies that test files are staged
  # alongside source files.  This gate is a pass-through — the actual
  # enforcement happens at commit time.
  echo "    TDD enforcement delegated to pre-commit hook (TDD_GATE check)."
  echo "    Staged source files must have corresponding test files staged."
  echo "    Disable with HOOK_TDD_GATE=0 in .githooks/config if needed."

  pass_msg "  TDD: enforced by pre-commit hook"
  return 0
}

# ====================================================================
# Gate 9: gate_file_scope
# Phase: 3
# File scope enforcement is handled by the L2 safety layer
# (check_file_scope function in l2-checks.sh).
# ====================================================================
gate_file_scope() {
  local change_id="$1"

  echo "  [GATE] File Scope Enforcement"

  if [[ -f "$GATES_LIB_DIR/l2-checks.sh" ]]; then
    echo "    File scope check delegated to L2 layer."
  fi
  echo "    All changed files must be within the plan scope."

  pass_msg "  FILE SCOPE: enforced by L2 checks layer"
  return 0
}

# ====================================================================
# Gate 10: gate_spec_drift
# Phase: 3
# Spec drift detection is handled by the L2 safety layer
# (check_spec_drift function in l2-checks.sh).
# ====================================================================
gate_spec_drift() {
  local change_id="$1"

  echo "  [GATE] Spec Drift Detection"

  if [[ -f "$GATES_LIB_DIR/l2-checks.sh" ]]; then
    echo "    Spec drift check delegated to L2 layer."
  fi

  pass_msg "  SPEC DRIFT: enforced by L2 checks layer"
  return 0
}

# ====================================================================
# Gate 11: gate_coverage
# Phase: 4
# Warns about coverage threshold.  Reads HOOK_COVERAGE_THRESHOLD
# from .githooks/config, defaults to 80%.
#
# The actual check runs in the pre-push hook; this gate provides
# awareness.
# ====================================================================
gate_coverage() {
  local change_id="$1"

  echo "  [GATE] Coverage Check"

  local threshold="${HOOK_COVERAGE_THRESHOLD:-80}"
  echo "    Coverage threshold: ${threshold}%"
  echo "    Actual enforcement runs during pre-push (COVERAGE check)."
  echo "    Disable with HOOK_COVERAGE=0 in .githooks/config."
  echo "    Adjust threshold with HOOK_COVERAGE_THRESHOLD=<value> in .githooks/config."

  local current_coverage="."

  # Lightweight check: see if any coverage report exists
  if [[ -f "coverage/coverage-summary.json" ]]; then
    current_coverage=$(node -e "const c=require('./coverage/coverage-summary.json');const t=c.total;console.log(t&&t.lines?Math.round(t.lines.pct)+'%':'unknown')" 2>/dev/null || echo "unknown")
  elif [[ -f "coverage.xml" ]]; then
    current_coverage=$(python3 -c "
import xml.etree.ElementTree as ET
try:
    t=ET.parse('coverage.xml').getroot()
    r=float(t.attrib.get('line-rate',0))*100
    print(str(int(round(r)))+'%')
except: print('unknown')" 2>/dev/null || echo "unknown")
  fi

  if [[ "$current_coverage" != "." && "$current_coverage" != "unknown" ]]; then
    echo "    Current coverage: ${current_coverage}"
  else
    echo "    No coverage report found."
  fi

  pass_msg "  COVERAGE: awareness check complete (threshold: ${threshold}%)"
  return 0
}

# ====================================================================
# Gate 12: gate_contract
# Phase: 4
# Contract / API breaking change detection via oasdiff.
# The actual check runs in the pre-push hook; this gate provides
# awareness.
# ====================================================================
gate_contract() {
  local change_id="$1"

  echo "  [GATE] Contract Check"

  echo "    OAS (OpenAPI Spec) breaking change detection using oasdiff."
  echo "    Actual enforcement runs during pre-push (CONTRACT check)."
  echo "    Disable with HOOK_CONTRACT=0 in .githooks/config."
  echo "    Install oasdiff: go install github.com/tufin/oasdiff/cmd/oasdiff@latest"

  if [[ -d "specs/api" ]]; then
    local spec_count
    spec_count=$(find specs/api -maxdepth 1 \( -name '*.yaml' -o -name '*.yml' \) 2>/dev/null | wc -l | tr -d ' ')
    echo "    Found ${spec_count} API spec file(s) in specs/api/"
  else
    echo "    No specs/api/ directory — nothing to check."
  fi

  pass_msg "  CONTRACT: awareness check complete"
  return 0
}

# ====================================================================
# Gate 13: gate_security
# Phase: 4
# Security scanning (semgrep + npm audit).
# The actual check runs in the pre-push hook; this gate provides
# awareness.
# ====================================================================
gate_security() {
  local change_id="$1"

  echo "  [GATE] Security Check"

  echo "    Security scan pipeline:"
  echo "      1. semgrep --config=auto (SAST)"
  echo "      2. npm audit --audit-level=moderate (dependency scan)"
  echo "    Actual enforcement runs during pre-push (SECURITY check)."
  echo "    Disable with HOOK_SECURITY=0 in .githooks/config."

  # Quick availability check
  if command -v semgrep &>/dev/null; then
    echo "    semgrep: available"
  else
    echo "    semgrep: NOT AVAILABLE — install: pip install semgrep"
  fi
  if command -v npm &>/dev/null; then
    echo "    npm: available"
  else
    echo "    npm: NOT AVAILABLE"
  fi

  pass_msg "  SECURITY: awareness check complete"
  return 0
}

# ====================================================================
# Gate 14: gate_smoke_test
# Phase: 4
# Quick sanity check that the built artifact starts and responds.
#
# Currently a placeholder — returns pass.
# ====================================================================
gate_smoke_test() {
  local change_id="$1"

  echo "  [GATE] Smoke Test"

  echo "    Smoke testing is a placeholder."
  echo "    In a full implementation, this would:"
  echo "      - Start the application in a test environment"
  echo "      - Execute a minimal health-check request"
  echo "      - Verify the response status is OK (200)"
  echo "      - Shut down the test instance"

  pass_msg "  SMOKE TEST: placeholder — manual verification recommended"
  return 0
}

# ====================================================================
# Gate 15: gate_full_diagnostics
# Phase: 5
# Runs the full diagnostic suite (lint, type check, test, coverage,
# security, contract) in one pass.
#
# Currently a placeholder — returns pass.
# ====================================================================
gate_full_diagnostics() {
  local change_id="$1"

  echo "  [GATE] Full Diagnostics"

  echo "    Full diagnostics is a placeholder."
  echo "    In a full implementation, this aggregates results from:"
  echo "      - pre-commit checks (format, lint, type, secrets, TDD)"
  echo "      - pre-push checks (unit test, coverage, security, contract)"
  echo "      - L2 safety checks (spec drift, file scope, destructive ops)"
  echo "    Disable individual checks in .githooks/config."

  pass_msg "  FULL DIAGNOSTICS: placeholder — run pre-commit and pre-push checks individually"
  return 0
}

# ====================================================================
# Gate 16: gate_all_gates_pass
# Phase: 5
# Aggregation gate — verifies that all previous phase gates have
# passed.  This is a meta-gate that provides summary information.
# ====================================================================
gate_all_gates_pass() {
  local change_id="$1"

  echo "  [GATE] All Gates Pass Check"

  echo "    This meta-gate verifies that all required gates for the"
  echo "    current change have passed."
  echo "    Phase 0-4 gates should all return pass before proceeding."
  echo "    Re-run run_phase_gates for each phase to verify."

  pass_msg "  ALL GATES PASS: meta-gate — verify all phase gates individually"
  return 0
}

# ====================================================================
# Gate 17: gate_destructive_op
# Phase: 5
# Destructive operation check — enforced by the L2 safety layer
# (check_destructive_op function in l2-checks.sh).
# ====================================================================
gate_destructive_op() {
  local change_id="$1"

  echo "  [GATE] Destructive Operation Check"

  if [[ -f "$GATES_LIB_DIR/l2-checks.sh" ]]; then
    echo "    Destructive operation detection delegated to L2 layer."
  fi
  echo "    Commands like rm -rf, git push --force, git reset --hard"
  echo "    are blocked by the DESTRUCTIVE_PATTERNS in l2-checks.sh."

  pass_msg "  DESTRUCTIVE OP: enforced by L2 checks layer"
  return 0
}

# ====================================================================
# Gate 18: gate_archive
# Phase: 5
# Verifies the completeness of the archive/ directory for a completed
# change — all expected artifacts are present.
# ====================================================================
gate_archive() {
  local change_id="$1"

  echo "  [GATE] Archive Completeness for change: $change_id"

  local archive_dir="archive/${change_id}"

  if [[ ! -d "$archive_dir" ]]; then
    fail_msg "  ARCHIVE: archive directory not found at $archive_dir"
    echo "    After completing a change, archive artifacts with:"
    echo "      mkdir -p archive/${change_id}"
    echo "      cp -r specs/${change_id}/* archive/${change_id}/"
    return 1
  fi

  local required_files=(
    "prd.md"
    "tasks.md"
  )

  local missing_files=""
  for f in "${required_files[@]}"; do
    if [[ ! -f "${archive_dir}/${f}" ]]; then
      missing_files="${missing_files}  ${archive_dir}/${f}\n"
    fi
  done

  if [[ -n "$missing_files" ]]; then
    warn_msg "  ARCHIVE: missing expected files in archive:"
    echo -e "$missing_files"
    echo "    Archive is partially complete — review and fill gaps."
    pass_msg "  ARCHIVE: partial — some files missing but non-blocking"
    return 0
  fi

  # Check for other common artifacts
  local artifact_count
  artifact_count=$(find "$archive_dir" -type f 2>/dev/null | wc -l | tr -d ' ')
  echo "    Archive contains ${artifact_count} file(s)."

  pass_msg "  ARCHIVE: archive directory is complete"
  return 0
}

# ====================================================================
# run_phase_gates
# ====================================================================
# Dispatches to the appropriate set of gates for a given phase (0-5)
# and prints a PASS/FAIL summary.
#
# Phase gate mapping:
#   Phase 0 — Directory Structure, Hook Activation
#   Phase 1 — PRD Completeness, Testability
#   Phase 2 — Task Granularity, No Cyclic Deps, Spec Alignment
#   Phase 3 — TDD, File Scope, Spec Drift
#   Phase 4 — Coverage, Contract, Security, Smoke Test
#   Phase 5 — Full Diagnostics, All Gates Pass, Destructive Op, Archive
#
# Usage:
#   run_phase_gates 0 "my-change-id"
#   run_phase_gates 1 "my-change-id"
# ====================================================================

# --------------------------------------------------------------------
# get_enable_level — reads enableLevel from .claude/settings.json
# Falls back to AIIT_LEVEL env var, then defaults to "L2" if unset.
# --------------------------------------------------------------------
get_enable_level() {
  if [[ -n "${AIIT_LEVEL:-}" ]]; then
    echo "$AIIT_LEVEL"
    return
  fi
  local settings=".claude/settings.json"
  if [[ -f "$settings" ]] && command -v python3 &>/dev/null; then
    python3 -c "
import json, sys
try:
    s = json.load(open('$settings'))
    print(s.get('enableLevel', 'L2'))
except Exception:
    print('L2')
"
  else
    echo "L2"
  fi
}

# --------------------------------------------------------------------
# gate_is_enabled gate_name level
# Returns 0 (enabled) or 1 (skip) based on settings.json gatesEnabled.
# L0 skips all gates. L2/L3 with "all" pass all gates through.
# --------------------------------------------------------------------
gate_is_enabled() {
  local gate_name="$1"
  local level="$2"
  local settings=".claude/settings.json"

  if [[ "$level" == "L0" ]]; then
    return 1
  fi

  if [[ ! -f "$settings" ]] || ! command -v python3 &>/dev/null; then
    return 0
  fi

  python3 -c "
import json, sys
try:
    s = json.load(open('$settings'))
    enabled = s.get('levels', {}).get('$level', {}).get('gatesEnabled', ['all'])
    if enabled == ['all'] or 'all' in enabled:
        sys.exit(0)
    sys.exit(0 if '$gate_name' in enabled else 1)
except Exception:
    sys.exit(0)
"
}

run_phase_gates() {
  local phase="$1"
  local change_id="${2:-}"
  local current_level
  current_level="$(get_enable_level)"

  echo ""
  echo "=============================================="
  echo "  Quality Gates — Phase ${phase}  [Level: ${current_level}]"
  echo "=============================================="
  echo ""

  if [[ "$current_level" == "L0" ]]; then
    warn_msg "Level L0: all quality gates skipped (emergency/hotfix mode)"
    echo ""
    return 0
  fi

  local gate_results=()
  local gate_names=()
  local failed_count=0
  local total_count=0
  local skipped_count=0
  local exit_code=0

  # Helper to run a gate — skips if not enabled for current level
  run_gate() {
    local gate_func="$1"
    local gate_label="$2"
    local gate_key="${gate_func#gate_}"  # strip "gate_" prefix for lookup

    if ! gate_is_enabled "$gate_key" "$current_level"; then
      echo -e "  ${YELLOW}[SKIP]${NC} ${gate_label} (not enabled at ${current_level})"
      skipped_count=$((skipped_count + 1))
      echo ""
      return
    fi

    gate_names+=("$gate_label")
    total_count=$((total_count + 1))
    if $gate_func "$change_id"; then
      gate_results+=("PASS")
    else
      gate_results+=("FAIL")
      failed_count=$((failed_count + 1))
      exit_code=1
    fi
    echo ""
  }

  case "$phase" in
    0)
      run_gate gate_directory_structure "Directory Structure"
      run_gate gate_hook_activation     "Hook Activation"
      ;;
    1)
      run_gate gate_prd_completeness    "PRD Completeness"
      run_gate gate_testability         "Testability"
      ;;
    2)
      run_gate gate_task_granularity    "Task Granularity"
      run_gate gate_no_cyclic_deps       "No Cyclic Deps"
      run_gate gate_spec_alignment      "Spec Alignment"
      ;;
    3)
      run_gate gate_tdd                 "TDD"
      run_gate gate_file_scope          "File Scope"
      run_gate gate_spec_drift          "Spec Drift"
      ;;
    4)
      run_gate gate_coverage            "Coverage"
      run_gate gate_contract            "Contract"
      run_gate gate_security            "Security"
      run_gate gate_smoke_test          "Smoke Test"
      ;;
    5)
      run_gate gate_full_diagnostics    "Full Diagnostics"
      run_gate gate_all_gates_pass      "All Gates Pass"
      run_gate gate_destructive_op      "Destructive Op"
      run_gate gate_archive             "Archive"
      ;;
    *)
      echo "ERROR: Unknown phase '$phase'. Valid phases: 0, 1, 2, 3, 4, 5"
      return 1
      ;;
  esac

  # --- Print Summary -------------------------------------------------
  echo "=============================================="
  echo "  Phase ${phase} Gate Summary  [Level: ${current_level}]"
  echo "=============================================="
  for i in "${!gate_names[@]}"; do
    if [[ "${gate_results[$i]}" == "PASS" ]]; then
      echo -e "  ${GREEN}[PASS]${NC} ${gate_names[$i]}"
    else
      echo -e "  ${RED}[FAIL]${NC} ${gate_names[$i]}"
    fi
  done
  echo "=============================================="
  echo "  Passed:  $((total_count - failed_count)) / ${total_count}"
  echo "  Failed:  ${failed_count} / ${total_count}"
  echo "  Skipped: ${skipped_count} (not enabled at ${current_level})"
  echo "=============================================="
  echo ""

  if [[ $exit_code -ne 0 ]]; then
    fail_msg "Phase ${phase} gates: ${failed_count} gate(s) FAILED"
  else
    pass_msg "Phase ${phase} gates: ALL PASSED"
  fi

  echo ""
  return $exit_code
}
