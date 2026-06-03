#!/bin/bash
# ============================================================
# AI Development Base — Unified State Management Interface
# .claude/scripts/aiit-state.sh
#
# Agent's exclusive interface for reading/writing .aiit.yaml.
# All state operations go through this script.
#
# Usage:
#   aiit-state.sh init <change_id> [workflow] [initial_phase]  # Create .aiit.yaml
#   aiit-state.sh set [change_id] <key> <value>                # Set a field
#   aiit-state.sh get [change_id] <key>                        # Read a field
#   aiit-state.sh check [change_id] <condition>                # Check condition
#   aiit-state.sh list                                         # List all active changes
#
# Keys support dot notation: execute.tasks_total
# When change_id is omitted for set/get/check, auto-detects the active change.
# ============================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/aiit-env.sh"

# Valid enum values
VALID_PHASES=("discover" "plan" "execute" "verify" "release" "archived")
VALID_WORKFLOWS=("full" "hotfix" "tweak")
VALID_BUILD_MODES=("sequential" "subagent-driven")
VALID_ISOLATION=("branch" "worktree" "none")

# --- find_yaml ----------------------------------------------------------
# Locate .aiit.yaml for a given change_id.
# Tries: specs/<change_id>/.aiit.yaml
# Prints the path or empty string.
# ------------------------------------------------------------------------
find_yaml() {
  local change_id="$1"
  local nested="specs/${change_id}/.aiit.yaml"
  if [[ -f "$nested" ]]; then
    echo "$nested"
    return
  fi
  # Fallback: search flat layout
  local found
  found=$(find specs -name ".aiit.yaml" -path "*/${change_id}/*" 2>/dev/null | head -1 || true)
  if [[ -n "$found" ]]; then
    echo "$found"
  fi
}

# --- get_yaml_value -----------------------------------------------------
# Read a value from .aiit.yaml using python3.
# Supports dot notation for nested keys.
# ------------------------------------------------------------------------
get_yaml_value() {
  local file="$1"
  local key="$2"
  python3 - "$file" "$key" <<'PYEOF'
import sys, re
file, key = sys.argv[1], sys.argv[2]
parts = key.split('.')
with open(file) as f:
    lines = f.readlines()
if len(parts) == 1:
    # Simple top-level key
    for line in lines:
        m = re.match(rf'^{re.escape(parts[0])}:\s*(.*)$', line)
        if m:
            val = m.group(1).strip()
            # Strip quotes
            if (val.startswith('"') and val.endswith('"')) or (val.startswith("'") and val.endswith("'")):
                val = val[1:-1]
            print(val)
            sys.exit(0)
else:
    # Nested key: find parent, then child
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

# --- set_yaml_value -----------------------------------------------------
# Set a value in .aiit.yaml using python3.
# Creates parent section if needed.
# ------------------------------------------------------------------------
set_yaml_value() {
  local file="$1"
  local key="$2"
  local value="$3"
  python3 - "$file" "$key" "$value" <<'PYEOF'
import sys, re
file, key, value = sys.argv[1], sys.argv[2], sys.argv[3]
parts = key.split('.')
with open(file) as f:
    content = f.read()
    lines = content.split('\n')

# Format value for YAML
if value in ('true', 'false', 'null'):
    yaml_val = value
elif value.isdigit():
    yaml_val = value
else:
    yaml_val = value

if len(parts) == 1:
    # Top-level key
    found = False
    new_lines = []
    for line in lines:
        if re.match(rf'^{re.escape(parts[0])}:\s*', line):
            new_lines.append(f'{parts[0]}: {yaml_val}')
            found = True
        else:
            new_lines.append(line)
    if not found:
        new_lines.append(f'{parts[0]}: {yaml_val}')
else:
    parent, child = parts[0], parts[1]
    found = False
    in_parent = False
    parent_found = False
    new_lines = []
    for i, line in enumerate(lines):
        if re.match(rf'^{re.escape(parent)}:\s*$', line):
            in_parent = True
            parent_found = True
            new_lines.append(line)
            continue
        if in_parent:
            if re.match(r'^[a-z]', line):
                # End of parent section, insert child
                new_lines.append(f'  {child}: {yaml_val}')
                in_parent = False
                found = True
                new_lines.append(line)
                continue
            m = re.match(rf'^(\s+){re.escape(child)}:\s*', line)
            if m:
                indent = m.group(1)
                new_lines.append(f'{indent}{child}: {yaml_val}')
                found = True
                in_parent = False
                continue
        new_lines.append(line)
    if not parent_found:
        new_lines.append(f'{parent}:')
        new_lines.append(f'  {child}: {yaml_val}')
    elif in_parent and not found:
        new_lines.append(f'  {child}: {yaml_val}')

with open(file, 'w') as f:
    f.write('\n'.join(new_lines))
PYEOF
}

# --- cmd_init -----------------------------------------------------------
# Create a new .aiit.yaml for a change_id.
# Usage: cmd_init <change_id> [workflow] [initial_phase]
# ------------------------------------------------------------------------
cmd_init() {
  local change_id="$1"
  local workflow="${2:-full}"
  local initial_phase="${3:-discover}"
  local yaml_dir="specs/${change_id}"

  # Create directory if needed
  mkdir -p "$yaml_dir"

  local yaml_file="${yaml_dir}/.aiit.yaml"
  local now
  now=$(date -u +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || date +"%Y-%m-%dT%H:%M:%SZ")

  cat > "$yaml_file" <<EOF
change_id: "${change_id}"
workflow: ${workflow}
phase: ${initial_phase}
phase_started_at: "${now}"

execute:
  tasks_total: 0
  tasks_completed: 0
  current_task: ""
  build_mode: sequential
  isolation: worktree

verify:
  result: pending
  report: ""

archived: false
pause_point: null

migration:
  deliverables: []
  key_decisions: []
  lessons: []
  files_changed: 0
  tests_added: 0
EOF

  echo "[OK] Initialized state: $yaml_file"
}

# --- resolve_yaml -------------------------------------------------------
# Resolve .aiit.yaml path. If first arg looks like a change_id (doesn't
# match a known field name), use it; otherwise auto-detect.
# Usage: resolve_yaml [change_id]
# Prints the yaml path or exits with error.
# ------------------------------------------------------------------------
resolve_yaml() {
  local arg="${1:-}"
  local yaml_file=""

  # Known field names (top-level and nested parents)
  local field_names="phase phase_started_at workflow archived pause_point execute verify migration"

  if [[ -n "$arg" ]] && ! echo "$field_names" | grep -qw "$arg"; then
    # arg is a change_id
    yaml_file=$(find_yaml "$arg")
    if [[ -z "$yaml_file" ]]; then
      echo "[ERROR] No .aiit.yaml found for change_id: $arg"
      exit 1
    fi
  else
    yaml_file=$(find_yaml_active)
    if [[ -z "$yaml_file" ]]; then
      echo "[ERROR] No active .aiit.yaml found. Run 'init' first."
      exit 1
    fi
  fi

  echo "$yaml_file"
}

# --- cmd_set ------------------------------------------------------------
# Set a field value.
# Usage: cmd_set [change_id] <key> <value>
# ------------------------------------------------------------------------
cmd_set() {
  local yaml_file key value

  if [[ $# -eq 3 ]]; then
    # change_id provided: set <change_id> <key> <value>
    yaml_file=$(resolve_yaml "$1")
    key="$2"
    value="$3"
  elif [[ $# -eq 2 ]]; then
    # no change_id: set <key> <value>
    yaml_file=$(resolve_yaml "")
    key="$1"
    value="$2"
  else
    echo "Usage: aiit-state.sh set [change_id] <key> <value>"
    exit 1
  fi

  set_yaml_value "$yaml_file" "$key" "$value"

  # If setting phase, also update phase_started_at
  if [[ "$key" == "phase" ]]; then
    local now
    now=$(date -u +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || date +"%Y-%m-%dT%H:%M:%SZ")
    set_yaml_value "$yaml_file" "phase_started_at" "\"$now\""
  fi

  echo "[OK] Set ${key}=${value}"
}

# --- cmd_get ------------------------------------------------------------
# Read a field value.
# Usage: cmd_get [change_id] <key>
# ------------------------------------------------------------------------
cmd_get() {
  local yaml_file key

  if [[ $# -eq 2 ]]; then
    yaml_file=$(resolve_yaml "$1")
    key="$2"
  elif [[ $# -eq 1 ]]; then
    yaml_file=$(resolve_yaml "")
    key="$1"
  else
    echo "Usage: aiit-state.sh get [change_id] <key>"
    exit 1
  fi

  get_yaml_value "$yaml_file" "$key"
}

# --- cmd_check ----------------------------------------------------------
# Check a condition. Returns 0 if true, 1 if false.
# Usage: cmd_check [change_id] <condition> <expected>
# Conditions:
#   phase_is <phase>
#   workflow_is <workflow>
#   archived_is <true|false>
# ------------------------------------------------------------------------
cmd_check() {
  local yaml_file condition expected

  if [[ $# -eq 3 ]]; then
    yaml_file=$(resolve_yaml "$1")
    condition="$2"
    expected="$3"
  elif [[ $# -eq 2 ]]; then
    yaml_file=$(resolve_yaml "")
    condition="$1"
    expected="$2"
  else
    echo "Usage: aiit-state.sh check [change_id] <condition> <expected>"
    exit 1
  fi

  local key actual
  case "$condition" in
    phase_is)
      key="phase"
      ;;
    workflow_is)
      key="workflow"
      ;;
    archived_is)
      key="archived"
      ;;
    *)
      echo "[ERROR] Unknown condition: $condition"
      exit 1
      ;;
  esac

  actual=$(get_yaml_value "$yaml_file" "$key")
  if [[ "$actual" == "$expected" ]]; then
    echo "[OK] ${condition} ${expected}: true"
    exit 0
  else
    echo "[FAIL] ${condition} ${expected}: false (actual: ${actual})"
    exit 1
  fi
}

# --- cmd_list -----------------------------------------------------------
# List all active changes with their state summary.
# ------------------------------------------------------------------------
cmd_list() {
  local found=0
  echo "Active changes:"
  echo ""
  for yaml_file in $(find specs -name ".aiit.yaml" 2>/dev/null | sort); do
    local change_id workflow phase archived
    change_id=$(get_yaml_value "$yaml_file" "change_id" 2>/dev/null || echo "unknown")
    workflow=$(get_yaml_value "$yaml_file" "workflow" 2>/dev/null || echo "?")
    phase=$(get_yaml_value "$yaml_file" "phase" 2>/dev/null || echo "?")
    archived=$(get_yaml_value "$yaml_file" "archived" 2>/dev/null || echo "?")

    if [[ "$archived" != "true" ]]; then
      echo "  ${change_id}"
      echo "    workflow: ${workflow}"
      echo "    phase: ${phase}"
      echo "    archived: ${archived}"
      echo "    file: ${yaml_file}"
      echo ""
      found=1
    fi
  done

  if [[ $found -eq 0 ]]; then
    echo "  (none)"
  fi
}

# --- find_yaml_active ---------------------------------------------------
# Find the active (non-archived) .aiit.yaml.
# If only one active change exists, return it.
# If multiple, error out (user must specify).
# ------------------------------------------------------------------------
find_yaml_active() {
  local active_files=()
  for yaml_file in $(find specs -name ".aiit.yaml" 2>/dev/null | sort); do
    local archived
    archived=$(get_yaml_value "$yaml_file" "archived" 2>/dev/null || echo "true")
    if [[ "$archived" != "true" ]]; then
      active_files+=("$yaml_file")
    fi
  done

  if [[ ${#active_files[@]} -eq 0 ]]; then
    echo ""
  elif [[ ${#active_files[@]} -eq 1 ]]; then
    echo "${active_files[0]}"
  else
    # Multiple active - return the most recently modified
    local latest=""
    local latest_time=0
    for f in "${active_files[@]}"; do
      local mod_time
      mod_time=$(stat -f %m "$f" 2>/dev/null || stat -c %Y "$f" 2>/dev/null || echo "0")
      if [[ $mod_time -gt $latest_time ]]; then
        latest="$f"
        latest_time=$mod_time
      fi
    done
    echo "$latest"
  fi
}

# --- Main ---------------------------------------------------------------
main() {
  local cmd="${1:-help}"
  shift || true

  case "$cmd" in
    init)
      cmd_init "$@"
      ;;
    set)
      cmd_set "$@"
      ;;
    get)
      cmd_get "$@"
      ;;
    check)
      cmd_check "$@"
      ;;
    list)
      cmd_list
      ;;
    help|*)
      echo "Usage: aiit-state.sh <command> [args]"
      echo ""
      echo "Commands:"
      echo "  init <change_id> [workflow] [phase]  Create .aiit.yaml (phase defaults to discover)"
      echo "  set [change_id] <key> <value>        Set a field (supports dot notation)"
      echo "  get [change_id] <key>                Read a field"
      echo "  check [change_id] <condition> <val>  Check condition (phase_is, workflow_is, archived_is)"
      echo "  list                                 List all active changes"
      echo ""
      echo "When change_id is omitted, auto-detects the active (non-archived) change."
      ;;
  esac
}

main "$@"
