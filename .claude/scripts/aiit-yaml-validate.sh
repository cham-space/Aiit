#!/bin/bash
# ============================================================
# AI Development Base — Schema Validator
# .claude/scripts/aiit-yaml-validate.sh
#
# Validates .aiit.yaml files for:
#   - Required fields (change_id, workflow, phase)
#   - Enum values (phase, workflow, build_mode, isolation)
#   - Unknown/typo fields
#   - File path references (design_doc, plan, verification_report)
#
# Usage:
#   aiit-yaml-validate.sh                        # Validate all active
#   aiit-yaml-validate.sh <path-to-yaml>         # Validate specific file
#   aiit-yaml-validate.sh --strict               # Fail on warnings too
# ============================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/aiit-env.sh"

# Valid enum values
VALID_PHASES="discover plan execute verify release archived"
VALID_WORKFLOWS="full hotfix tweak"
VALID_BUILD_MODES="sequential subagent-driven"
VALID_ISOLATION="branch worktree none"
VALID_RESULTS="pending pass fail"

# Known fields (top-level and nested)
KNOWN_TOP_FIELDS="change_id workflow phase phase_started_at execute verify archived pause_point migration"
KNOWN_EXECUTE_FIELDS="tasks_total tasks_completed current_task build_mode isolation"
KNOWN_VERIFY_FIELDS="result report"
KNOWN_MIGRATION_FIELDS="deliverables key_decisions lessons files_changed tests_added"

HAS_ERROR=0
HAS_WARNING=0

# --- validate_enum -------------------------------------------------------
# Check if a value is in a space-separated list.
# ------------------------------------------------------------------------
validate_enum() {
  local field="$1"
  local value="$2"
  local valid_list="$3"

  if [[ -z "$value" || "$value" == "null" ]]; then
    return 0
  fi

  for valid in $valid_list; do
    if [[ "$value" == "$valid" ]]; then
      return 0
    fi
  done

  echo "  [FAIL] ${field}: invalid value '${value}' (valid: ${valid_list})"
  HAS_ERROR=1
  return 1
}

# --- validate_file_path --------------------------------------------------
# Check if a referenced file path exists.
# ------------------------------------------------------------------------
validate_file_path() {
  local field="$1"
  local path="$2"

  if [[ -z "$path" || "$path" == '""' || "$path" == "null" || "$path" == "''" ]]; then
    return 0
  fi

  # Strip quotes
  path="${path#\"}"
  path="${path%\"}"
  path="${path#\'}"
  path="${path%\'}"

  if [[ ! -f "$path" ]]; then
    echo "  [WARN] ${field}: referenced file does not exist: ${path}"
    HAS_WARNING=1
  fi
}

# --- validate_yaml -------------------------------------------------------
# Validate a single .aiit.yaml file.
# ------------------------------------------------------------------------
validate_yaml() {
  local file="$1"

  if [[ ! -f "$file" ]]; then
    echo "  [FAIL] File not found: $file"
    HAS_ERROR=1
    return 1
  fi

  echo "  Validating: $file"

  # --- Check required fields ---
  local change_id workflow phase
  change_id=$(get_yaml_value_safe "$file" "change_id")
  workflow=$(get_yaml_value_safe "$file" "workflow")
  phase=$(get_yaml_value_safe "$file" "phase")

  if [[ -z "$change_id" ]]; then
    echo "  [FAIL] Missing required field: change_id"
    HAS_ERROR=1
  fi

  if [[ -z "$workflow" ]]; then
    echo "  [FAIL] Missing required field: workflow"
    HAS_ERROR=1
  else
    validate_enum "workflow" "$workflow" "$VALID_WORKFLOWS"
  fi

  if [[ -z "$phase" ]]; then
    echo "  [FAIL] Missing required field: phase"
    HAS_ERROR=1
  else
    validate_enum "phase" "$phase" "$VALID_PHASES"
  fi

  # --- Check enum fields ---
  local build_mode isolation verify_result
  build_mode=$(get_yaml_value_safe "$file" "execute.build_mode")
  isolation=$(get_yaml_value_safe "$file" "execute.isolation")
  verify_result=$(get_yaml_value_safe "$file" "verify.result")

  [[ -n "$build_mode" ]] && validate_enum "execute.build_mode" "$build_mode" "$VALID_BUILD_MODES"
  [[ -n "$isolation" ]] && validate_enum "execute.isolation" "$isolation" "$VALID_ISOLATION"
  [[ -n "$verify_result" ]] && validate_enum "verify.result" "$verify_result" "$VALID_RESULTS"

  # --- Check file path references ---
  local report
  report=$(get_yaml_value_safe "$file" "verify.report")
  validate_file_path "verify.report" "$report"

  # --- Check for unknown fields ---
  check_unknown_fields "$file"
}

# --- get_yaml_value_safe -------------------------------------------------
# Get a value from yaml file directly (no state context needed).
# ------------------------------------------------------------------------
get_yaml_value_safe() {
  local file="$1"
  local key="$2"
  python3 - "$file" "$key" <<'PYEOF' 2>/dev/null || echo ""
import sys, re
file, key = sys.argv[1], sys.argv[2]
parts = key.split('.')
with open(file) as f:
    lines = f.readlines()
if len(parts) == 1:
    for line in lines:
        m = re.match(rf'^{re.escape(parts[0])}:\s*(.*)$', line)
        if m:
            val = m.group(1).strip()
            if (val.startswith('"') and val.endswith('"')) or (val.startswith("'") and val.endswith("'")):
                val = val[1:-1]
            print(val)
            sys.exit(0)
else:
    parent, child = parts[0], parts[1]
    in_parent = False
    for line in lines:
        if re.match(rf'^{re.escape(parent)}:\s*$', line):
            in_parent = True
            continue
        if in_parent:
            if re.match(r'^[a-z]', line):
                break
            m = re.match(rf'^\s+{re.escape(child)}:\s*(.*)$', line)
            if m:
                val = m.group(1).strip()
                if (val.startswith('"') and val.endswith('"')) or (val.startswith("'") and val.endswith("'")):
                    val = val[1:-1]
                print(val)
                sys.exit(0)
print("")
PYEOF
}

# --- check_unknown_fields ------------------------------------------------
# Check for unknown/typo fields in the yaml file.
# ------------------------------------------------------------------------
check_unknown_fields() {
  local file="$1"

  # Extract top-level fields
  local top_fields
  top_fields=$(grep -E '^[a-z_]+:' "$file" 2>/dev/null | sed 's/:.*//' || true)

  for field in $top_fields; do
    if ! echo "$KNOWN_TOP_FIELDS" | grep -qw "$field"; then
      echo "  [WARN] Unknown top-level field: '${field}'"
      HAS_WARNING=1
    fi
  done

  # Check nested fields under execute/
  local in_execute=0
  while IFS= read -r line; do
    if [[ "$line" =~ ^execute: ]]; then
      in_execute=1
      continue
    fi
    if [[ $in_execute -eq 1 ]]; then
      if [[ "$line" =~ ^[a-z] ]]; then
        in_execute=0
        continue
      fi
      # Strip leading whitespace, then extract field name before colon
      local trimmed="${line#"${line%%[![:space:]]*}"}"
      local nested_field="${trimmed%%:*}"
      # Skip empty lines and comments
      if [[ -n "$nested_field" && "$nested_field" != \#* ]]; then
        if ! echo "$KNOWN_EXECUTE_FIELDS" | grep -qw "$nested_field"; then
          echo "  [WARN] Unknown field under execute: '${nested_field}'"
          HAS_WARNING=1
        fi
      fi
    fi
  done < "$file"
}

# --- Main ---------------------------------------------------------------
main() {
  local strict=0
  local target=""

  for arg in "$@"; do
    case "$arg" in
      --strict) strict=1 ;;
      *) target="$arg" ;;
    esac
  done

  echo ""
  echo "=============================================="
  echo "  AIIT YAML Schema Validation"
  echo "=============================================="
  echo ""

  if [[ -n "$target" ]]; then
    # Validate specific file
    validate_yaml "$target"
  else
    # Validate all .aiit.yaml files
    local found=0
    for yaml_file in $(find specs -name ".aiit.yaml" 2>/dev/null | sort); do
      validate_yaml "$yaml_file"
      found=1
    done
    if [[ $found -eq 0 ]]; then
      echo "  No .aiit.yaml files found."
    fi
  fi

  echo ""
  echo "=============================================="
  if [[ $HAS_ERROR -gt 0 ]]; then
    echo "  [FAIL] ${HAS_ERROR} error(s), ${HAS_WARNING} warning(s)"
    echo "=============================================="
    echo ""
    exit 1
  elif [[ $HAS_WARNING -gt 0 && $strict -eq 1 ]]; then
    echo "  [WARN] ${HAS_WARNING} warning(s) (--strict mode)"
    echo "=============================================="
    echo ""
    exit 1
  else
    echo "  [PASS] ${HAS_WARNING} warning(s)"
    echo "=============================================="
    echo ""
    exit 0
  fi
}

main "$@"
