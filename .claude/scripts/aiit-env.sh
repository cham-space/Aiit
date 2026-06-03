#!/bin/bash
# ============================================================
# AI Development Base — Script Discovery Helper
# .claude/scripts/aiit-env.sh
#
# Exports environment variables pointing to the bundled
# script paths.  Other scripts and hooks source this file
# to locate the aiit toolchain.
#
# Usage:
#   source .claude/scripts/aiit-env.sh
#   echo "$AIIT_STATE"   # path to aiit-state.sh
# ============================================================

# Resolve this script's directory (works even when sourced)
_AIIT_ENV_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

export AIIT_SCRIPTS_DIR="$_AIIT_ENV_DIR"
export AIIT_STATE="$_AIIT_ENV_DIR/aiit-state.sh"
export AIIT_GUARD="$_AIIT_ENV_DIR/aiit-guard.sh"
export AIIT_ARCHIVE="$_AIIT_ENV_DIR/aiit-archive.sh"
export AIIT_VALIDATE="$_AIIT_ENV_DIR/aiit-yaml-validate.sh"
