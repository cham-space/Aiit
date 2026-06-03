#!/bin/bash
# ============================================================
# AI Development Base — Phase Transition Guard
# .claude/scripts/aiit-guard.sh
#
# Validates phase transition preconditions before allowing
# the workflow to advance.
#
# Usage:
#   aiit-guard.sh check <from> <to> <change_id>           # Check only
#   aiit-guard.sh check <from> <to> <change_id> --apply   # Check + update state
#
# Transition rules:
#   discover -> plan:    PRD file must exist
#   plan -> execute:     plan + tasks files must exist
#   execute -> verify:   no incomplete task checkboxes
#   verify -> release:   verification_report path non-empty
# ------------------------------------------------------------------------
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/aiit-env.sh"

HARD_STOP=0

# --- check_file_exists ---------------------------------------------------
# Verify a file exists. Print error if not.
# ------------------------------------------------------------------------
check_file_exists() {
  local description="$1"
  local path="$2"

  if [[ ! -f "$path" ]]; then
    echo "  [HARD STOP] ${description} not found: ${path}"
    HARD_STOP=1
    return 1
  fi
  echo "  [OK] ${description}: ${path}"
  return 0
}

# --- check_no_incomplete_tasks ------------------------------------------
# Verify no incomplete task checkboxes in tasks file.
# ------------------------------------------------------------------------
check_no_incomplete_tasks() {
  local change_id="$1"

  # Find tasks file
  local tasks_file=""
  if [[ -f "specs/${change_id}/tasks.md" ]]; then
    tasks_file="specs/${change_id}/tasks.md"
  elif [[ -f "specs/plan/${change_id}.md" ]]; then
    tasks_file="specs/plan/${change_id}.md"
  fi

  if [[ -z "$tasks_file" ]]; then
    echo "  [WARN] No tasks file found — skipping task completion check"
    return 0
  fi

  # Count incomplete checkboxes
  local incomplete
  incomplete=$(grep -cE '^\s*[-*]\s+\[\s*\]' "$tasks_file" 2>/dev/null || echo "0")

  if [[ "$incomplete" -gt 0 ]]; then
    echo "  [HARD STOP] ${incomplete} incomplete task(s) in ${tasks_file}"
    echo "    Complete all tasks before advancing to verify phase."
    HARD_STOP=1
    return 1
  fi

  echo "  [OK] All tasks completed"
  return 0
}

# --- check_verify_report -------------------------------------------------
# Verify that verification_report path is set and file exists.
# ------------------------------------------------------------------------
check_verify_report() {
  local change_id="$1"

  # Read verify.report from .aiit.yaml
  local report
  report=$("$AIIT_STATE" get verify.report 2>/dev/null || echo "")

  if [[ -z "$report" || "$report" == '""' || "$report" == "null" ]]; then
    echo "  [HARD STOP] verify.report is not set in .aiit.yaml"
    echo "    Run verification and set the report path before advancing."
    HARD_STOP=1
    return 1
  fi

  # Strip quotes
  report="${report#\"}"
  report="${report%\"}"

  if [[ ! -f "$report" ]]; then
    echo "  [HARD STOP] verification report file does not exist: ${report}"
    HARD_STOP=1
    return 1
  fi

  echo "  [OK] Verification report: ${report}"
  return 0
}

# --- check_transition ---------------------------------------------------
# Check preconditions for a phase transition.
# ------------------------------------------------------------------------
check_transition() {
  local from_phase="$1"
  local to_phase="$2"
  local change_id="$3"

  echo ""
  echo "=============================================="
  echo "  Phase Guard: ${from_phase} -> ${to_phase}"
  echo "=============================================="
  echo ""

  HARD_STOP=0

  local transition="${from_phase}_${to_phase}"

  case "$transition" in
    discover_plan)
      # PRD must exist
      local prd_file=""
      if [[ -f "specs/prd/${change_id}.md" ]]; then
        prd_file="specs/prd/${change_id}.md"
      elif [[ -f "specs/${change_id}/prd.md" ]]; then
        prd_file="specs/${change_id}/prd.md"
      fi
      check_file_exists "PRD file" "$prd_file"
      ;;

    plan_execute)
      # plan + tasks must exist
      local plan_file=""
      if [[ -f "specs/plan/${change_id}.md" ]]; then
        plan_file="specs/plan/${change_id}.md"
      elif [[ -f "specs/${change_id}/plan.md" ]]; then
        plan_file="specs/${change_id}/plan.md"
      fi
      check_file_exists "Plan file" "$plan_file"

      local tasks_file=""
      if [[ -f "specs/${change_id}/tasks.md" ]]; then
        tasks_file="specs/${change_id}/tasks.md"
      elif [[ -f "specs/plan/${change_id}.md" ]]; then
        tasks_file="specs/plan/${change_id}.md"
      fi
      if [[ -n "$tasks_file" ]]; then
        echo "  [OK] Tasks file: ${tasks_file}"
      fi
      ;;

    execute_verify)
      # No incomplete tasks
      check_no_incomplete_tasks "$change_id"
      ;;

    verify_release)
      # Verification report must exist
      check_verify_report "$change_id"
      ;;

    *)
      echo "  [WARN] No specific guard for ${from_phase} -> ${to_phase}"
      echo "    Allowing transition (no preconditions defined)."
      ;;
  esac

  echo ""
  if [[ $HARD_STOP -gt 0 ]]; then
    echo "=============================================="
    echo "  [HARD STOP] Transition blocked"
    echo "=============================================="
    echo ""
    echo "  Fix the issues above and retry."
    return 1
  else
    echo "=============================================="
    echo "  [PASS] Transition allowed"
    echo "=============================================="
    echo ""
    return 0
  fi
}

# --- apply_transition ---------------------------------------------------
# Apply the transition: update .aiit.yaml phase field.
# ------------------------------------------------------------------------
apply_transition() {
  local to_phase="$1"

  "$AIIT_STATE" set phase "$to_phase"
  echo "[OK] Updated phase to: ${to_phase}"
}

# --- Main ---------------------------------------------------------------
main() {
  local cmd="${1:-help}"
  shift || true

  case "$cmd" in
    check)
      local from_phase="${1:-}"
      local to_phase="${2:-}"
      local change_id="${3:-}"
      local apply=0

      if [[ "${4:-}" == "--apply" ]]; then
        apply=1
      fi

      if [[ -z "$from_phase" || -z "$to_phase" || -z "$change_id" ]]; then
        echo "Usage: aiit-guard.sh check <from_phase> <to_phase> <change_id> [--apply]"
        exit 1
      fi

      # Run the check
      if check_transition "$from_phase" "$to_phase" "$change_id"; then
        # Check passed
        if [[ $apply -eq 1 ]]; then
          apply_transition "$to_phase"
        fi
        exit 0
      else
        # Check failed
        exit 1
      fi
      ;;

    help|*)
      echo "Usage: aiit-guard.sh <command> [args]"
      echo ""
      echo "Commands:"
      echo "  check <from_phase> <to_phase> <change_id> [--apply]"
      echo ""
      echo "Examples:"
      echo "  aiit-guard.sh check discover plan my-change-id"
      echo "  aiit-guard.sh check plan execute my-change-id --apply"
      ;;
  esac
}

main "$@"
