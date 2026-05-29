#!/bin/bash
# ============================================================
# AI Development Base — L2 AI Safety Layer
# .githooks/lib/l2-checks.sh
#
# Functions that provide a second safety layer for AI-assisted
# development.  All functions source utils.sh for colors and
# helpers.
#
# Functions:
#   check_spec_drift(change_id)
#   check_file_scope(change_id)
#   check_permission_boundary()
#   check_destructive_op(command_str)
# ============================================================
set -euo pipefail

# Resolve library directory and source utils.
L2_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$L2_LIB_DIR/utils.sh"

# --- check_spec_drift -------------------------------------------------------
# Compares the current implementation state against the spec for a given
# change_id using `openspec diff`.
#
# Outputs a drift assessment level:
#   ALIGNED  — implementation matches spec
#   MEDIUM   — minor deviations detected
#   HIGH     — significant discrepancies found
#
# Returns 0 if ALIGNED or MEDIUM (non-blocking), 1 if HIGH.
# ----------------------------------------------------------------------------
check_spec_drift() {
  local change_id="$1"
  local drift_level="ALIGNED"

  echo "  [L2] Checking spec drift for change: $change_id"

  if ! command -v openspec &>/dev/null; then
    fail_msg "  SPEC DRIFT: openspec CLI not found — install with: npm install -g @fission-ai/openspec"
    return 1
  fi

  # Capture openspec diff output
  local diff_output
  diff_output=$(openspec diff "$change_id" 2>&1) || true

  if echo "$diff_output" | grep -qi "HIGH"; then
    drift_level="HIGH"
  elif echo "$diff_output" | grep -qi "MEDIUM"; then
    drift_level="MEDIUM"
  else
    drift_level="ALIGNED"
  fi

  case "$drift_level" in
    HIGH)
      fail_msg "  SPEC DRIFT: HIGH — significant deviations from spec detected"
      return 1
      ;;
    MEDIUM)
      warn_msg "  SPEC DRIFT: MEDIUM — minor deviations detected; review recommended"
      return 0
      ;;
    *)
      pass_msg "  SPEC DRIFT: ALIGNED — implementation matches spec"
      return 0
      ;;
  esac
}

# --- check_file_scope -------------------------------------------------------
# Verifies that the files changed in a given change_id are within the
# plan's declared scope.  Compares the file list from the change against
# the planned scope file.
#
# Returns 0 if all changes are in scope, 1 if out-of-scope files are
# detected.
# ----------------------------------------------------------------------------
check_file_scope() {
  local change_id="$1"

  echo "  [L2] Checking file scope for change: $change_id"

  local plan_scope_file="specs/${change_id}/plan-scope.txt"
  local changed_files_file="specs/${change_id}/changed-files.txt"

  if [[ ! -f "$plan_scope_file" ]]; then
    warn_msg "  FILE SCOPE: No plan scope file found at $plan_scope_file — skipping scope check"
    return 0
  fi

  # If no changed-files tracking exists, gather from git
  if [[ ! -f "$changed_files_file" ]]; then
    echo "  No changed-files.txt found; generating from git diff..."
    git diff --name-only HEAD~1 > "$changed_files_file" 2>/dev/null || {
      warn_msg "  FILE SCOPE: Could not determine changed files — skipping scope check"
      return 0
    }
  fi

  local out_of_scope=""
  while IFS= read -r changed_file; do
    # Skip empty lines
    [[ -z "$changed_file" ]] && continue
    if ! grep -qF "$changed_file" "$plan_scope_file" 2>/dev/null; then
      out_of_scope="${out_of_scope}  ${changed_file}\n"
    fi
  done < "$changed_files_file"

  if [[ -n "$out_of_scope" ]]; then
    fail_msg "  FILE SCOPE: Out-of-scope files detected:"
    echo -e "$out_of_scope"
    return 1
  else
    pass_msg "  FILE SCOPE: All changed files are within plan scope"
    return 0
  fi
}

# --- check_permission_boundary ----------------------------------------------
# Delegates to Claude Code's native permission system.
# This is a hook placeholder — actual enforcement happens via the
# CLAUDE.md / .claude/settings.json permission rules.
#
# Always returns 0 (non-blocking); violations are handled by the
# Claude Code harness itself.
# ----------------------------------------------------------------------------
check_permission_boundary() {
  echo "  [L2] Checking permission boundaries..."

  # The Claude Code harness enforces permissions via settings.json
  # and CLAUDE.md permission blocks.  This function exists as an
  # explicit checkpoint in the gate chain.
  echo "  Permission boundary enforcement delegated to Claude Code harness."
  echo "  Verify .claude/settings.json and CLAUDE.md permission sections."

  pass_msg "  PERMISSION BOUNDARY: enforced by Claude Code harness"
  return 0
}

# --- check_destructive_op ---------------------------------------------------
# Checks a command string against a set of known destructive patterns.
# If a match is found, the function fails with an explanation.
#
# Destructive patterns include:
#   - rm -rf (or rm -r, rm -rf with variations)
#   - git push --force / git push -f
#   - git reset --hard
#   - git clean -f (or git clean -fd, git clean -fdx)
#   - DROP TABLE, TRUNCATE (SQL)
#   - chmod 777
#
# Usage: check_destructive_op "rm -rf /tmp/build"
#
# Returns 0 if safe, 1 if destructive pattern matched.
# ----------------------------------------------------------------------------
check_destructive_op() {
  local command_str="$1"

  echo "  [L2] Checking command for destructive operations..."

  # Define destructive patterns — any match is treated as a violation
  local DESTRUCTIVE_PATTERNS=(
    'rm[[:space:]]+-rf[[:space:]]'
    'rm[[:space:]]+-fr[[:space:]]'
    'rm[[:space:]]+-r[[:space:]]'
    'rm[[:space:]]+-rf[[:space:]]*/($|/*|[[:space:]])'
    ': > /etc/'
    'git[[:space:]]+push[[:space:]].*--force'
    'git[[:space:]]+push[[:space:]].*-f[[:space:]]'
    'git[[:space:]]+push[[:space:]].*--delete'
    'git[[:space:]]+reset[[:space:]]+--hard'
    'git[[:space:]]+clean[[:space:]].*-f'
    'DROP[[:space:]]+TABLE'
    'DROP[[:space:]]+DATABASE'
    'TRUNCATE[[:space:]]+TABLE'
    'chmod[[:space:]]+777'
    'chmod[[:space:]]+-R[[:space:]]+777'
    'sudo[[:space:]]+rm[[:space:]]'
    'dd[[:space:]]+if='
    'mkfs\.'
    ':(){ :|:& };:'  # fork bomb
  )

  for pattern in "${DESTRUCTIVE_PATTERNS[@]}"; do
    if echo "$command_str" | grep -Eq "$pattern"; then
      fail_msg "  DESTRUCTIVE OP DETECTED: '$command_str' matches destructive pattern '$pattern'"
      echo ""
      echo "  This command appears to be destructive.  Destructive operations"
      echo "  require explicit approval through the L2 safety layer."
      echo ""
      echo "  If this operation is intentional and safe, please:"
      echo "    1. Verify the target path / scope is correct"
      echo "    2. Confirm it is within the change plan scope"
      echo "    3. Re-run with explicit permission override"
      echo ""
      return 1
    fi
  done

  pass_msg "  DESTRUCTIVE OP: safe — no destructive patterns matched"
  return 0
}
