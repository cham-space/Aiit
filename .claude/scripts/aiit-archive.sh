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
#   aiit-archive.sh <change_id>                      # Archive
#   aiit-archive.sh <change_id> --dry-run            # Preview only
#   aiit-archive.sh <change_id> --generate-journal   # Archive + generate Migration Journal
#   aiit-archive.sh <change_id> --journal-only       # Generate journal only (no archive)
# ============================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/aiit-env.sh"

DRY_RUN=0
GENERATE_JOURNAL=0
JOURNAL_ONLY=0

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
  phase=$("$AIIT_STATE" get "$change_id" phase 2>/dev/null || echo "")
  archived=$("$AIIT_STATE" get "$change_id" archived 2>/dev/null || echo "false")

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

  # --- Create archive directory ---
  if [[ ! -d "$archive_dir" ]]; then
    echo "  Creating: ${archive_dir}/"
    mkdir -p "$archive_dir"
  fi

  # --- Journal only mode: generate journal and exit ---
  if [[ $JOURNAL_ONLY -eq 1 ]]; then
    generate_journal "$change_id" "$archive_dir"
    echo "  [OK] Journal generated. Review it before running final archive."
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
  "$AIIT_STATE" set "$change_id" archived true

  # --- Generate Migration Journal ---
  if [[ $GENERATE_JOURNAL -eq 1 ]]; then
    generate_journal "$change_id" "$archive_dir"
  fi

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

# --- generate_journal ---------------------------------------------------
# Generate Migration Journal from plan tasks, git diff, and commits.
# ------------------------------------------------------------------------
generate_journal() {
  local change_id="$1"
  local archive_dir="$2"

  echo ""
  echo "  Generating Migration Journal..."

  local journal_file="${archive_dir}/MIGRATION.md"

  # --- Extract problem statement from PRD ---
  local prd_file=""
  if [[ -f "specs/prd/${change_id}.md" ]]; then
    prd_file="specs/prd/${change_id}.md"
  elif [[ -f "specs/${change_id}/prd.md" ]]; then
    prd_file="specs/${change_id}/prd.md"
  fi

  local problem="Not documented"
  if [[ -n "$prd_file" ]]; then
    # Extract first paragraph after "## Overview" or "## Background"
    problem=$(awk '/^## (Overview|Background|动机)/ {found=1; next} found && /^## / {exit} found && /^$/ {next} found {print; exit}' "$prd_file" 2>/dev/null || echo "Not documented")
  fi

  # --- Extract deliverables from plan tasks ---
  local deliverables=""
  local tasks_file=""
  if [[ -f "specs/plan/${change_id}.md" ]]; then
    tasks_file="specs/plan/${change_id}.md"
  elif [[ -f "specs/${change_id}/plan.md" ]]; then
    tasks_file="specs/${change_id}/plan.md"
  fi

  if [[ -n "$tasks_file" ]]; then
    # Extract task titles (lines starting with ## Task or ### Task)
    deliverables=$(grep -E '^#{2,3}\s+Task' "$tasks_file" 2>/dev/null | sed 's/^#* Task[[:space:]]*[0-9]*[:.]*[[:space:]]*//' | head -10 || echo "")
  fi

  # --- Count files changed and tests added from git log ---
  local files_changed=0
  local tests_added=0
  local first_commit=""

  # Find the first commit for this change (look for change_id in commit message)
  first_commit=$(git log --all --grep="${change_id}" --format="%H" --reverse 2>/dev/null | head -1 || echo "")

  if [[ -n "$first_commit" ]]; then
    # Count files changed since first commit
    files_changed=$(git diff --stat "${first_commit}^..HEAD" 2>/dev/null | tail -1 | grep -oE '[0-9]+ file' | grep -oE '[0-9]+' || echo "0")

    # Count test files added
    tests_added=$(git diff --name-only "${first_commit}^..HEAD" 2>/dev/null | grep -E '(test|spec)' | wc -l | tr -d ' ' || echo "0")
  fi

  # --- Extract key decisions from commit messages ---
  local decisions=""
  if [[ -n "$first_commit" ]]; then
    decisions=$(git log --format="%s" "${first_commit}^..HEAD" 2>/dev/null | grep -vE '^(feat|fix|docs|style|refactor|perf|test|chore|ci|build|revert)\(' | head -5 || echo "")
  fi

  # --- Generate journal markdown ---
  cat > "$journal_file" <<JOURNAL
# Migration Journal: ${change_id}

**Archived:** $(date -u +"%Y-%m-%dT%H:%M:%SZ")
**Status:** archived

---

## Problem Solved

${problem}

## What Was Built

$(if [[ -n "$deliverables" ]]; then
    echo "$deliverables" | while read -r line; do
      [[ -n "$line" ]] && echo "- ${line}"
    done
  else
    echo "- Not documented"
  fi)

## Key Decisions

$(if [[ -n "$decisions" ]]; then
    echo "$decisions" | while read -r line; do
      [[ -n "$line" ]] && echo "- ${line}"
    done
  else
    echo "- No explicit decisions documented"
  fi)

## Metrics

- **Files changed:** ${files_changed}
- **Tests added:** ${tests_added}

## Lessons Learned

_(To be filled by the team during archive review)_

---

## Artifact Manifest

| File | Phase | Description |
|------|-------|-------------|
| prd.md | 1 | Original PRD spec |
| plan.md | 2 | Task plan + DAG |
| .aiit.yaml | all | Workflow state tracking |
JOURNAL

  echo "  [OK] Journal generated: ${journal_file}"
  echo ""
  echo "  Please review and complete:"
  echo "    - Verify 'Problem Solved' is accurate"
  echo "    - Review 'What Was Built' deliverables"
  echo "    - Add 'Lessons Learned' from the team"
  echo ""
}

# --- Main ---------------------------------------------------------------
main() {
  local change_id=""

  for arg in "$@"; do
    case "$arg" in
      --dry-run) DRY_RUN=1 ;;
      --generate-journal) GENERATE_JOURNAL=1 ;;
      --journal-only) JOURNAL_ONLY=1 ;;
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
