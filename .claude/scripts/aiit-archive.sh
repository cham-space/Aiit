#!/bin/bash
# ============================================================
# AI Development Base — One-Command Archive
# .claude/scripts/aiit-archive.sh
#
# Automates the archive flow:
#   1. Validate entry state (phase=release, archived=false)
#   2. Call openspec archive (or manual copy)
#   3. Update .aiit.yaml archived=true
#
# Usage:
#   aiit-archive.sh <change_id>              # Archive
#   aiit-archive.sh <change_id> --dry-run    # Preview only
# ============================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/aiit-env.sh"

DRY_RUN=0

# --- cmd_archive --------------------------------------------------------
# Archive a completed change.
# ------------------------------------------------------------------------
cmd_archive() {
  local change_id="$1"

  echo ""
  echo "=============================================="
  echo "  Archive: ${change_id}"
  echo "=============================================="
  echo ""

  # --- Validate entry state ---
  local phase archived
  phase=$("$AIIT_STATE" get phase 2>/dev/null || echo "")
  archived=$("$AIIT_STATE" get archived 2>/dev/null || echo "false")

  if [[ -z "$phase" ]]; then
    echo "  [FAIL] No .aiit.yaml found for ${change_id}"
    echo "    Run 'aiit-state.sh init ${change_id}' first."
    exit 1
  fi

  if [[ "$archived" == "true" ]]; then
    echo "  [WARN] Change ${change_id} is already archived"
    exit 0
  fi

  if [[ "$phase" != "release" && "$phase" != "archived" ]]; then
    echo "  [WARN] Current phase is '${phase}', not 'release'"
    echo "    Consider running verification first."
    echo "    Proceeding anyway..."
  fi

  # --- Determine source directories ---
  local src_dirs=()
  local src_files=()

  # Nested layout: specs/<change_id>/
  if [[ -d "specs/${change_id}" ]]; then
    src_dirs+=("specs/${change_id}")
  fi

  # Flat layout: specs/<subdir>/<change_id>.md
  for subdir in prd plan api design test release; do
    if [[ -f "specs/${subdir}/${change_id}.md" ]]; then
      src_files+=("specs/${subdir}/${change_id}.md")
    elif [[ -f "specs/${subdir}/${change_id}.yaml" ]]; then
      src_files+=("specs/${subdir}/${change_id}.yaml")
    fi
  done

  if [[ ${#src_dirs[@]} -eq 0 && ${#src_files[@]:-0} -eq 0 ]]; then
    echo "  [FAIL] No source artifacts found for ${change_id}"
    exit 1
  fi

  # --- Determine archive destination ---
  local archive_dir="archive/${change_id}"

  if [[ $DRY_RUN -eq 1 ]]; then
    echo "  [DRY RUN] Would archive to: ${archive_dir}"
    echo ""
    echo "  Source directories:"
    for d in "${src_dirs[@]:-}"; do
      [[ -n "$d" ]] && echo "    - ${d}/"
    done
    echo "  Source files:"
    for f in "${src_files[@]:-}"; do
      [[ -n "$f" ]] && echo "    - ${f}"
    done
    echo ""
    echo "  [DRY RUN] Would update .aiit.yaml: archived=true"
    exit 0
  fi

  # --- Try openspec archive first ---
  if command -v openspec &>/dev/null; then
    echo "  Running: openspec archive ${change_id}"
    if openspec archive "$change_id" 2>&1; then
      echo "  [OK] openspec archive completed"
    else
      echo "  [WARN] openspec archive failed, falling back to manual copy"
    fi
  fi

  # --- Manual copy fallback ---
  if [[ ! -d "$archive_dir" ]]; then
    echo "  Creating: ${archive_dir}/"
    mkdir -p "$archive_dir"
  fi

  # Copy nested layout
  for d in "${src_dirs[@]:-}"; do
    [[ -n "$d" && -d "$d" ]] && {
      echo "  Copying: ${d}/ -> ${archive_dir}/"
      cp -r "$d"/* "$archive_dir/" 2>/dev/null || true
    }
  done

  # Copy flat layout
  for f in "${src_files[@]:-}"; do
    [[ -n "$f" && -f "$f" ]] && {
      echo "  Copying: ${f} -> ${archive_dir}/"
      cp "$f" "$archive_dir/" 2>/dev/null || true
    }
  done

  # --- Update .aiit.yaml ---
  echo "  Updating .aiit.yaml: archived=true"
  "$AIIT_STATE" set archived true

  # --- Cleanup source (optional) ---
  echo ""
  echo "  Archive complete: ${archive_dir}/"
  echo ""
  echo "  Source artifacts remain in specs/ for reference."
  echo "  To remove them manually:"
  for d in "${src_dirs[@]:-}"; do
    [[ -n "$d" ]] && echo "    rm -rf ${d}/"
  done
  for f in "${src_files[@]:-}"; do
    [[ -n "$f" ]] && echo "    rm ${f}"
  done
  echo ""

  echo "=============================================="
  echo "  [OK] Archive complete"
  echo "=============================================="
  echo ""
}

# --- Main ---------------------------------------------------------------
main() {
  local change_id=""

  for arg in "$@"; do
    case "$arg" in
      --dry-run) DRY_RUN=1 ;;
      *) change_id="$arg" ;;
    esac
  done

  if [[ -z "$change_id" ]]; then
    echo "Usage: aiit-archive.sh <change_id> [--dry-run]"
    exit 1
  fi

  cmd_archive "$change_id"
}

main "$@"
