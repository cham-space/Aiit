#!/bin/bash
# ============================================================
# AI Development Base — Shared Hook Utility Library
# .githooks/lib/utils.sh
#
# Sourced by all git hooks. Provides:
#   - Color definitions for terminal output
#   - hook_enabled() toggle check against .githooks/config
#   - detect_ecosystem() language/platform detection
#   - pass_msg / fail_msg / warn_msg output helpers
# ============================================================
set -euo pipefail

# --- Color Definitions ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'  # No Color

# --- Hook Config ---
# .githooks/config is a bash snippet that exports toggle variables.
# Example content:
#   HOOK_FORMAT=1
#   HOOK_LINT=1
#   HOOK_UNIT_TEST=0
HOOK_CONFIG=".githooks/config"
if [[ -f "$HOOK_CONFIG" ]]; then
  source "$HOOK_CONFIG"
fi

# --- hook_enabled -----------------------------------------------------------
# Usage: hook_enabled "CHECK_NAME"
# Looks for an env var HOOK_<CHECK_NAME>.  If the variable is unset or set
# to "1" the check is considered enabled.  Any other value (e.g. "0")
# disables the check.
# ----------------------------------------------------------------------------
hook_enabled() {
  local check_name="$1"
  local var_name="HOOK_${check_name}"
  [[ -z "${!var_name:-}" || "${!var_name}" == "1" ]]
}

# --- detect_ecosystem -------------------------------------------------------
# Prints one or more ecosystem identifiers that apply to the current repo.
# Callers can check via:  eco=$(detect_ecosystem)
# ----------------------------------------------------------------------------
detect_ecosystem() {
  if [[ -f "package.json" ]]; then echo "npm"; fi
  if [[ -f "pyproject.toml" || -f "setup.py" ]]; then echo "python"; fi
  if [[ -f "go.mod" ]]; then echo "go"; fi
  if [[ -f "Cargo.toml" ]]; then echo "rust"; fi
}

# --- Output Helpers ---------------------------------------------------------
pass_msg() { echo -e "${GREEN}[PASS]${NC} $1"; }
fail_msg() { echo -e "${RED}[FAIL]${NC} $1"; }
warn_msg() { echo -e "${YELLOW}[WARN]${NC} $1"; }
