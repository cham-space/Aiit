#!/bin/bash
# ============================================================
# AI Development Base — Quality Gates
# .githooks/lib/gates.sh
#
# 17 quality gate functions that enforce development process
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

# --------------------------------------------------------------------
# resolve_spec_file change_id filename subdir
# Tries multiple path layouts for spec files:
#   specs/<subdir>/<change_id>.md  (flat layout, /discover default)
#   specs/<change_id>/<filename>   (nested layout)
# Prints the resolved path or empty string.
# --------------------------------------------------------------------
resolve_spec_file() {
  local change_id="$1"
  local filename="$2"
  local subdir="${3:-}"
  if [[ -z "$change_id" ]]; then
    return
  fi
  if [[ -n "$subdir" && -f "specs/${subdir}/${change_id}.md" ]]; then
    echo "specs/${subdir}/${change_id}.md"
  elif [[ -f "specs/${change_id}/${filename}" ]]; then
    echo "specs/${change_id}/${filename}"
  fi
}

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

  local prd_file
  prd_file=$(resolve_spec_file "$change_id" "prd.md" "prd")
  if [[ -z "$prd_file" ]]; then
    fail_msg "  PRD COMPLETENESS: PRD file not found"
    echo "    Looked in: specs/prd/${change_id}.md"
    echo "    Looked in: specs/${change_id}/prd.md"
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

  local prd_file
  prd_file=$(resolve_spec_file "$change_id" "prd.md" "prd")
  if [[ -z "$prd_file" ]]; then
    fail_msg "  TESTABILITY: PRD file not found"
    return 1
  fi

  # Extract acceptance criteria sections (commonly between "Acceptance Criteria"
  # and the next heading).
  local ac_section
  ac_section=$(awk '/Acceptance Criteria|Acceptance Criteria:/,/^#/{print}' "$prd_file" 2>/dev/null || true)

  if [[ -z "$ac_section" ]]; then
    fail_msg "  TESTABILITY: No 'Acceptance Criteria' section found in PRD"
    echo "    Add a '## Acceptance Criteria' section with quantifiable, measurable conditions."
    echo "    Examples: 'response time < 200ms', '95% accuracy', 'supports 1000 concurrent users'"
    return 1
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
# granularity and that the plan structure is sound.
# ====================================================================
gate_task_granularity() {
  local change_id="$1"

  echo "  [GATE] Task Granularity for change: $change_id"

  # 1. plan.md must exist
  local plan_file
  plan_file=$(resolve_spec_file "$change_id" "plan.md" "plan")
  if [[ -z "$plan_file" ]]; then
    fail_msg "  TASK GRANULARITY: plan file not found"
    echo "    Looked in: specs/plan/${change_id}.md"
    echo "    Looked in: specs/${change_id}/plan.md"
    return 1
  fi

  # 2. tasks.md must exist
  local tasks_file
  tasks_file=$(resolve_spec_file "$change_id" "tasks.md")
  if [[ -z "$tasks_file" ]]; then
    fail_msg "  TASK GRANULARITY: tasks file not found"
    echo "    Looked in: specs/${change_id}/tasks.md"
    return 1
  fi

  # 3. Count tasks
  local task_count
  task_count=$(grep -cE '^[-*] \[ \]|^[-*] \[X\]|^[-*] \[x\]' "$tasks_file" 2>/dev/null || echo "0")

  if [[ "$task_count" -eq 0 ]]; then
    fail_msg "  TASK GRANULARITY: no checklist tasks found in tasks.md"
    echo "    Tasks should use '- [ ]' checklist format."
    return 1
  fi

  echo "    Found ${task_count} tasks in tasks.md"

  local warnings=0

  # 4. Too few tasks
  if [[ "$task_count" -lt 2 ]]; then
    warn_msg "  TASK GRANULARITY: only ${task_count} task — PRD may not be sufficiently decomposed"
    warnings=$((warnings + 1))
  fi

  # 5. Too many tasks
  if [[ "$task_count" -gt 30 ]]; then
    warn_msg "  TASK GRANULARITY: ${task_count} tasks — consider grouping related tasks"
    warnings=$((warnings + 1))
  fi

  # 6. Check for dependency annotations
  local dep_count
  dep_count=$(grep -ciE 'depends on|blocked by|requires|after ' "$tasks_file" 2>/dev/null || echo "0")
  if [[ "$dep_count" -eq 0 && "$task_count" -gt 1 ]]; then
    warn_msg "  TASK GRANULARITY: no dependency annotations found between ${task_count} tasks"
    warnings=$((warnings + 1))
  fi

  echo "    Dependencies annotated: ${dep_count}"

  if [[ $warnings -gt 0 ]]; then
    pass_msg "  TASK GRANULARITY: ${task_count} tasks, ${warnings} warning(s) — review recommended"
  else
    pass_msg "  TASK GRANULARITY: ${task_count} tasks with ${dep_count} dependency annotations"
  fi
  return 0
}

# ====================================================================
# Gate 6: gate_no_cyclic_deps
# Phase: 2
# Checks for cyclic dependencies between tasks in the plan.
# Detects self-references and bidirectional dependencies.
# ====================================================================
gate_no_cyclic_deps() {
  local change_id="$1"

  echo "  [GATE] Cyclic Dependency Check for change: $change_id"

  local tasks_file
  tasks_file=$(resolve_spec_file "$change_id" "tasks.md")
  if [[ -z "$tasks_file" ]]; then
    pass_msg "  NO CYCLIC DEPS: no tasks file — nothing to check"
    return 0
  fi

  # Extract lines with dependency annotations
  local deps
  deps=$(grep -inE 'depends on|blocked by|requires' "$tasks_file" 2>/dev/null || true)

  if [[ -z "$deps" ]]; then
    pass_msg "  NO CYCLIC DEPS: no dependency annotations found — nothing to check"
    return 0
  fi

  local dep_count
  dep_count=$(echo "$deps" | wc -l | tr -d ' ')
  echo "    Found ${dep_count} dependency annotation(s)"

  # Detect self-references: same task ID appears as both subject and dependency
  local self_ref=""
  while IFS= read -r line; do
    # Extract task identifiers (e.g., "T1", "Task 1", "Task A")
    local ids
    ids=$(echo "$line" | grep -oE '(T[0-9]+|Task[- ]?[A-Za-z0-9]+|Step[- ]?[A-Za-z0-9]+)' 2>/dev/null || true)
    if [[ -n "$ids" ]]; then
      local first last
      first=$(echo "$ids" | head -1)
      last=$(echo "$ids" | tail -1)
      if [[ -n "$first" && -n "$last" && "$first" == "$last" ]]; then
        self_ref="${self_ref}  Line: $(echo "$line" | head -c 80)\n"
      fi
    fi
  done <<< "$deps"

  if [[ -n "$self_ref" ]]; then
    fail_msg "  NO CYCLIC DEPS: self-referencing dependency detected:"
    echo -e "$self_ref"
    return 1
  fi

  # Detect bidirectional dependencies: A depends on B AND B depends on A
  local bidirectional=""
  local checked=""
  while IFS= read -r line; do
    local ids
    ids=$(echo "$line" | grep -oE '(T[0-9]+|Task[- ]?[A-Za-z0-9]+|Step[- ]?[A-Za-z0-9]+)' 2>/dev/null || true)
    if [[ -n "$ids" ]]; then
      local from to
      from=$(echo "$ids" | head -1)
      to=$(echo "$ids" | tail -1)
      if [[ -n "$from" && -n "$to" && "$from" != "$to" ]]; then
        local pair="${from}->${to}"
        local reverse="${to}->${from}"
        # Skip if already checked this pair
        if echo "$checked" | grep -qF "$pair"; then
          continue
        fi
        checked="${checked} ${pair}"
        # Check if reverse dependency exists
        if echo "$deps" | grep -q "$to" && echo "$deps" | grep -q "$from"; then
          local has_reverse
          has_reverse=$(echo "$deps" | grep "$to" | grep -c "$from" 2>/dev/null || echo "0")
          if [[ "$has_reverse" -gt 0 ]]; then
            bidirectional="${bidirectional}  ${from} <-> ${to}\n"
          fi
        fi
      fi
    fi
  done <<< "$deps"

  if [[ -n "$bidirectional" ]]; then
    fail_msg "  NO CYCLIC DEPS: bidirectional dependency detected:"
    echo -e "$bidirectional"
    return 1
  fi

  pass_msg "  NO CYCLIC DEPS: no simple cycles detected (${dep_count} deps checked)"
  return 0
}

# ====================================================================
# Gate 7: gate_spec_alignment
# Phase: 2
# Checks that the implementation plan aligns with the PRD spec.
# Verifies structural alignment: both files exist, key PRD concepts
# appear in the plan.
# ====================================================================
gate_spec_alignment() {
  local change_id="$1"

  echo "  [GATE] Spec Alignment for change: $change_id"

  # 1. Both PRD and plan must exist
  local prd_file plan_file
  prd_file=$(resolve_spec_file "$change_id" "prd.md" "prd")
  plan_file=$(resolve_spec_file "$change_id" "plan.md" "plan")

  if [[ -z "$prd_file" ]]; then
    fail_msg "  SPEC ALIGNMENT: PRD not found"
    return 1
  fi
  if [[ -z "$plan_file" ]]; then
    fail_msg "  SPEC ALIGNMENT: plan not found"
    return 1
  fi

  # 2. Extract User Story titles from PRD
  local story_count
  story_count=$(grep -ciE '^\s*[-*]\s*(As a |As an )' "$prd_file" 2>/dev/null || echo "0")
  echo "    PRD User Stories: ${story_count}"

  if [[ "$story_count" -eq 0 ]]; then
    warn_msg "  SPEC ALIGNMENT: no User Stories found in PRD — cannot verify alignment"
    pass_msg "  SPEC ALIGNMENT: skipped — no User Stories to cross-reference"
    return 0
  fi

  # 3. Extract key concepts from PRD (capitalized multi-word phrases)
  local prd_keywords
  prd_keywords=$(grep -oE '\b[A-Z][a-z]+(\s+[A-Z][a-z]+)+\b' "$prd_file" 2>/dev/null | sort -u | head -20 || true)

  local matched=0
  local total=0
  while IFS= read -r keyword; do
    [[ -z "$keyword" ]] && continue
    # Skip very short or generic terms
    [[ ${#keyword} -lt 6 ]] && continue
    total=$((total + 1))
    if grep -qiF "$keyword" "$plan_file" 2>/dev/null; then
      matched=$((matched + 1))
    fi
  done <<< "$prd_keywords"

  if [[ $total -gt 0 ]]; then
    local pct=$((matched * 100 / total))
    echo "    PRD concept coverage in plan: ${pct}% (${matched}/${total} key terms)"
    if [[ $pct -lt 30 ]]; then
      warn_msg "  SPEC ALIGNMENT: low PRD concept coverage (${pct}%) — plan may not cover all requirements"
    else
      pass_msg "  SPEC ALIGNMENT: plan covers ${pct}% of PRD key concepts"
    fi
  else
    pass_msg "  SPEC ALIGNMENT: no extractable key concepts — skipped"
  fi
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
  elif [[ -f "target/site/jacoco/jacoco.csv" ]]; then
    current_coverage=$(python3 -c "
import csv
total_missed=0; total_covered=0
with open('target/site/jacoco/jacoco.csv') as f:
    reader=csv.DictReader(f)
    for row in reader:
        total_missed+=int(row['INSTRUCTION_MISSED'])
        total_covered+=int(row['INSTRUCTION_COVERED'])
total=total_missed+total_covered
print(str(int(round(total_covered*100/total)))+'%') if total>0 else print('unknown')
" 2>/dev/null || echo "unknown")
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
# Build smoke test — verifies the project compiles successfully
# using the detected ecosystem (node/maven/python/go/rust).
# ====================================================================
gate_smoke_test() {
  local change_id="$1"

  echo "  [GATE] Smoke Test (Build Check)"

  local ecosystem
  ecosystem=$(detect_ecosystem 2>/dev/null || echo "unknown")
  ecosystem="${ecosystem:-unknown}"

  echo "    Detected ecosystem: ${ecosystem}"

  local build_output=""
  local build_exit=0

  case "$ecosystem" in
    node|npm)
      if [[ -f "package.json" ]] && grep -q '"build"' package.json 2>/dev/null; then
        echo "    Running: npm run build --silent"
        build_output=$(npm run build --silent 2>&1) || build_exit=$?
      elif [[ -f "package.json" ]] && grep -q '"tsc"\|"typecheck"\|"type-check"' package.json 2>/dev/null; then
        echo "    Running: npx tsc --noEmit"
        build_output=$(npx tsc --noEmit 2>&1) || build_exit=$?
      else
        echo "    No build script found in package.json"
        pass_msg "  SMOKE TEST: no build script — skipped"
        return 0
      fi
      ;;
    maven)
      if [[ -f "pom.xml" ]]; then
        echo "    Running: mvn compile -q"
        build_output=$(mvn compile -q 2>&1) || build_exit=$?
      fi
      ;;
    python)
      if [[ -f "pyproject.toml" ]] || [[ -f "setup.py" ]]; then
        echo "    Running: python -m compileall -q src/"
        if [[ -d "src" ]]; then
          build_output=$(python3 -m compileall -q src/ 2>&1) || build_exit=$?
        else
          echo "    No src/ directory — skipping compile check"
          pass_msg "  SMOKE TEST: no source directory — skipped"
          return 0
        fi
      fi
      ;;
    go)
      if [[ -f "go.mod" ]]; then
        echo "    Running: go build ./..."
        build_output=$(go build ./... 2>&1) || build_exit=$?
      fi
      ;;
    rust)
      if [[ -f "Cargo.toml" ]]; then
        echo "    Running: cargo check 2>&1"
        build_output=$(cargo check 2>&1) || build_exit=$?
      fi
      ;;
    *)
      echo "    No recognized build system — skipping build check"
      pass_msg "  SMOKE TEST: no build system detected — skipped"
      return 0
      ;;
  esac

  if [[ $build_exit -ne 0 ]] || echo "$build_output" | grep -qiE 'error|ERROR|FAILED|fatal'; then
    fail_msg "  SMOKE TEST: build failed (exit code: ${build_exit})"
    echo "    Last 5 lines of build output:"
    echo "$build_output" | tail -5 | sed 's/^/      /'
    return 1
  fi

  pass_msg "  SMOKE TEST: build passed (${ecosystem})"
  return 0
}

# ====================================================================
# Gate 15: gate_full_diagnostics
# Phase: 5
# Re-runs Phase 0-4 gates and aggregates results.
# Any phase with a failing gate blocks Phase 5 completion.
# ====================================================================
gate_full_diagnostics() {
  local change_id="$1"

  echo "  [GATE] Full Diagnostics (Phase 0-4 re-run)"

  local total_fail=0
  local phase_results=""

  for phase in 0 1 2 3 4; do
    local phase_exit=0
    # Run phase gates silently, capture exit code
    _run_phase_silent "$phase" "$change_id" || phase_exit=$?
    if [[ $phase_exit -ne 0 ]]; then
      total_fail=$((total_fail + 1))
      phase_results="${phase_results}    Phase ${phase}: FAIL\n"
    else
      phase_results="${phase_results}    Phase ${phase}: PASS\n"
    fi
  done

  echo -e "$phase_results"
  echo "    Summary: $((5 - total_fail))/5 phases passed"

  if [[ $total_fail -gt 0 ]]; then
    fail_msg "  FULL DIAGNOSTICS: ${total_fail} phase(s) have failing gates"
    return 1
  fi

  pass_msg "  FULL DIAGNOSTICS: all phases passed"
  return 0
}

# ====================================================================
# Gate 16: (removed — gate_all_gates_pass merged into gate_full_diagnostics)
# ====================================================================

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
    echo "      bash .claude/scripts/aiit-archive.sh ${change_id}"
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
  fi

  # Check .aiit.yaml archived state if available
  local aiit_yaml=""
  if [[ -f "${archive_dir}/.aiit.yaml" ]]; then
    aiit_yaml="${archive_dir}/.aiit.yaml"
  elif [[ -f "specs/${change_id}/.aiit.yaml" ]]; then
    aiit_yaml="specs/${change_id}/.aiit.yaml"
  fi

  if [[ -n "$aiit_yaml" ]]; then
    local archived_val
    archived_val=$(python3 - "$aiit_yaml" <<'PYEOF' 2>/dev/null || echo ""
import sys, re
with open(sys.argv[1]) as f:
    for line in f:
        m = re.match(r'^archived:\s*(.*)$', line)
        if m:
            print(m.group(1).strip())
            sys.exit(0)
print("")
PYEOF
)
    if [[ "$archived_val" == "true" ]]; then
      pass_msg "  ARCHIVE: .aiit.yaml confirms archived=true"
    else
      warn_msg "  ARCHIVE: .aiit.yaml archived is not true (value: ${archived_val:-<empty>})"
    fi
  fi

  local artifact_count
  artifact_count=$(find "$archive_dir" -type f 2>/dev/null | wc -l | tr -d ' ')
  echo "    Archive contains ${artifact_count} file(s)."

  if [[ -z "$missing_files" ]]; then
    pass_msg "  ARCHIVE: archive directory is complete"
    return 0
  else
    pass_msg "  ARCHIVE: partial — some files missing but non-blocking"
    return 0
  fi
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
#   Phase 5 — Full Diagnostics, Destructive Op, Archive
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

# --------------------------------------------------------------------
# _run_phase_silent phase change_id
# Runs all gates for a phase without printing summary banners.
# Returns 0 if all pass, 1 if any fail.
# Used by gate_full_diagnostics to aggregate Phase 0-4 results.
# --------------------------------------------------------------------
_run_phase_silent() {
  local phase="$1"
  local change_id="${2:-}"
  local current_level
  current_level="$(get_enable_level)"

  if [[ "$current_level" == "L0" ]]; then
    return 0
  fi

  local exit_code=0

  _run_gate_silent() {
    local gate_func="$1"
    local gate_key="${gate_func#gate_}"

    if ! gate_is_enabled "$gate_key" "$current_level"; then
      return 0
    fi

    # Suppress output, capture exit code
    $gate_func "$change_id" &>/dev/null || exit_code=1
  }

  case "$phase" in
    0)
      _run_gate_silent gate_directory_structure
      _run_gate_silent gate_hook_activation
      ;;
    1)
      _run_gate_silent gate_prd_completeness
      _run_gate_silent gate_testability
      ;;
    2)
      _run_gate_silent gate_task_granularity
      _run_gate_silent gate_no_cyclic_deps
      _run_gate_silent gate_spec_alignment
      ;;
    3)
      _run_gate_silent gate_tdd
      _run_gate_silent gate_file_scope
      _run_gate_silent gate_spec_drift
      ;;
    4)
      _run_gate_silent gate_coverage
      _run_gate_silent gate_contract
      _run_gate_silent gate_security
      _run_gate_silent gate_smoke_test
      ;;
  esac

  return $exit_code
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
