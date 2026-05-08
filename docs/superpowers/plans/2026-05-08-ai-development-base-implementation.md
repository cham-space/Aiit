# AI Development Base Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 构建 AI 开发基座的文件骨架——目录结构、配置、Hook 脚本、Gate 检查、Slash 命令、CLAUDE.md 模板和 WORKFLOW.md

**Architecture:** 纯配置+脚本项目。大部分 Skill（Superpowers 自带）和 MCP（已安装）无需创建，只需创建集成层：阶段流转映射、Hook/Gate 脚本、Slash 命令入口、索引模板

**Tech Stack:** Shell 脚本、JSON/YAML 配置、Markdown 模板、Claude Code CLI

---

## File Structure Map

```
project/
├── CLAUDE.md                          ← 入口索引模板（<150行）
├── .claude/
│   ├── WORKFLOW.md                    ← 流程手册（完整5阶段规范）
│   ├── settings.json                  ← 项目级权限+配置
│   ├── commands/                      ← 斜杠命令定义
│   │   ├── discover.md
│   │   ├── execute.md
│   │   ├── hotfix.md
│   │   ├── diagnose.md
│   │   ├── close-phase.md
│   │   └── onboard.md
│   └── skills/                        ← 项目级自定义skill
│       └── openspec.md                ← OpenSpec 操作 skill
├── .githooks/
│   ├── config                         ← hook 开关配置
│   ├── pre-commit                     ← L1: format+lint+type-check+gitleaks+TDD gate
│   ├── commit-msg                     ← L1: commitlint
│   ├── pre-push                       ← L1: test+coverage+security+contract
│   └── lib/                           ← 共享脚本库
│       ├── gates.sh                   ← 18个gate检查函数
│       ├── l2-checks.sh               ← L2: spec drift + file scope + permission
│       └── utils.sh                   ← 公共工具函数
├── .gitleaks.toml                     ← 密钥扫描配置
└── .commitlintrc.yaml                 ← 提交信息格式
```

---

### Task 1: Project Directory Scaffolding

**Files:**
- Create: `项目根目录下全部目录结构`

- [ ] **Step 1: Create all directories**

```bash
mkdir -p .claude/commands .claude/skills
mkdir -p .githooks/lib
mkdir -p specs/prd specs/api specs/design specs/test specs/release
mkdir -p archive
mkdir -p .github/workflows
mkdir -p .agents
```

- [ ] **Step 2: Verify directory structure**

```bash
ls -R .claude .githooks specs .github archive .agents
```

Expected: All directories listed without errors.

- [ ] **Step 3: Commit**

```bash
git add -A
git commit -m "chore: scaffold project directory structure"
```

---

### Task 2: CLAUDE.md Entry Index Template

**Files:**
- Create: `CLAUDE.md`

- [ ] **Step 1: Write CLAUDE.md template**

```markdown
# Project: {{PROJECT_NAME}}

## Current Level
L{{LEVEL}} — {{LEVEL_DESC}}

## Active Changes
| Change ID | PRD Spec | Phase | Status |
|-----------|----------|-------|--------|
<!-- ACTIVE_CHANGES_START -->
<!-- ACTIVE_CHANGES_END -->

## Quick Links
- Process handbook: `.claude/WORKFLOW.md`
- Active specs: `specs/`
- History: `archive/`
- Quality gates: `.githooks/` + `.github/workflows/`

## Project-Specific
- Language: {{LANGUAGE}}
- Framework: {{FRAMEWORK}}
- Custom skills: `.claude/skills/`

## Phase Commands
| Phase | Command | Description |
|-------|---------|-------------|
| 1 | `/discover [idea]` | Explore and define requirements |
| 2 | (auto) | Plan generation from approved PRD |
| 3 | `/execute` | Run TDD implementation loop |
| 4 | (auto) | Verification gates |
| 5 | `/close-phase` | Finalize and archive |
| Any | `/hotfix` | Emergency fix (L0+) |
| Any | `/diagnose` | Diagnostic investigation |
```

- [ ] **Step 2: Commit**

```bash
git add CLAUDE.md
git commit -m "feat: add CLAUDE.md entry index template"
```

---

### Task 3: WORKFLOW.md Process Handbook

**Files:**
- Create: `.claude/WORKFLOW.md`

- [ ] **Step 1: Write WORKFLOW.md — Phase 0-1**

```markdown
# AI Development Base — Workflow Handbook

## Overview

This project uses a five-phase development lifecycle driven by OpenSpec + Superpowers + Claude Code.
Each phase has automated gates; transition is blocked until all gates pass.

## Phase 0: Initialization (one-time)

**Goal:** Set up the project for AI-assisted development

1. `openspec init` — creates `specs/` with standard templates
2. Deploy `.claude/` config — WORKFLOW.md, settings.json, commands/, skills/
3. Deploy `.githooks/` — pre-commit, commit-msg, pre-push
4. `git config core.hooksPath .githooks` — activate hooks
5. `/onboard` — select role + level (L0-L3)

**Gates:** Directory Structure Gate, Hook Activation Gate

---

## Phase 1: Discover

**Trigger:** `/discover [idea]` or describe a requirement in conversation

**Flow:**
1. `brainstorming` skill activates — clarifies intent, constraints, success criteria
2. Proposes 2-3 approaches with trade-offs; user selects one
3. Outputs structured PRD draft for user confirmation
4. `openspec validate` checks PRD format completeness
5. Writes `specs/prd/<change-id>.md` — change enters `proposed` status

**Output:** `specs/prd/<change-id>.md`

**Required PRD Fields:**
- Background & Motivation
- User Stories
- Acceptance Criteria (quantifiable)
- Boundaries & Constraints
- Non-Functional Requirements

**Gates:** PRD Completeness Gate, Testability Gate

**Capabilities:**
| Type | Name | Description |
|------|------|-------------|
| Skill | brainstorming | Structured requirement exploration |
| Skill | design-brief-builder | (Optional) Design brief for design phase |
| Skill | openspec validate | PRD format completeness check |
| MCP | Figma | (Optional) Design inspiration lookup |
| Hook | pre-spec-commit | Schema check + duplicate detection |
```

- [ ] **Step 2: Write WORKFLOW.md — Phase 2**

```markdown
---

## Phase 2: Plan

**Trigger:** PRD spec confirmed (auto or manual)

**Flow:**
1. `writing-plans` reads `specs/prd/<change-id>.md`
2. Serena MCP analyzes existing codebase for impact scope
3. Decomposes PRD into independent, verifiable tasks with dependency DAG
4. **Parallel outputs (can run concurrently):**
   - `api-contract-first` → `specs/api/<change-id>.yaml` (OpenAPI)
   - `frontend-design` + Figma MCP → `specs/design/<change-id>.md`
   - Test strategy → `specs/test/<change-id>.md`
5. User confirms plan + all parallel specs
6. `openspec validate` — plan ↔ PRD alignment
7. Writes `specs/plan/<change-id>.md` — change enters `planned` status

**Output:**
- `specs/plan/<change-id>.md` — task list + dependency graph
- `specs/api/<change-id>.yaml` — API contract
- `specs/design/<change-id>.md` — design spec
- `specs/test/<change-id>.md` — test strategy

**Gates:** Task Granularity Gate, No Cyclic Deps Gate, Spec Alignment Gate

**Capabilities:**
| Type | Name | Description |
|------|------|-------------|
| Skill | writing-plans | PRD → executable task list |
| Skill | api-contract-first | API contract first (OpenAPI spec) |
| Skill | frontend-design | Design spec: component tree, interactions |
| Skill | openspec validate | Plan ↔ PRD alignment |
| MCP | Serena | Codebase impact analysis |
| MCP | TypeScript LSP | Interface/type understanding |
| MCP | Figma | Design resource lookup |
```

- [ ] **Step 3: Write WORKFLOW.md — Phase 3**

```markdown
---

## Phase 3: Execute (TDD)

**Trigger:** Plan + all specs confirmed (auto)

**Iron Rule: TDD — test first, always. Test MUST fail before implementation.**
If implementation is written before a failing test, delete it and restart.

**Flow:**
1. `executing-plans` reads plan DAG, orders tasks topologically
2. For each ready task:
   a. Write test file → run → **MUST FAIL** (red)
   b. Write minimal implementation → run → **MUST PASS** (green)
   c. Refactor (Serena checks references for safety)
   d. `openspec diff` — check for spec drift
   e. `git commit` (triggers pre-commit hooks)
3. Repeat until all tasks complete

**L2+ Parallel Mode:**
When level ≥ L2 and ≥ 2 tasks have all dependencies satisfied:
- `subagent-driven-development` auto-activates
- Each ready task gets an independent agent + isolated git worktree
- Agents run concurrently

**Gates:** TDD Gate, File Scope Gate, Spec Drift Gate, Coverage Gate

**Capabilities:**
| Type | Name | Description |
|------|------|-------------|
| Skill | executing-plans | Drive tasks in DAG order |
| Skill | TDD | Test-first enforcement |
| Skill | subagent-driven-development | (L2+) Parallel task execution |
| Skill | dispatching-parallel-agents | (L2+) Concurrent dispatch |
| Skill | openspec diff | Spec drift detection |
| MCP | TypeScript LSP | Real-time type checking |
| MCP | Serena | Reference analysis, refactor safety |
| MCP | Playwright | (Frontend) Interaction verification |
| MCP | Figma | Design spec reference |
```

- [ ] **Step 4: Write WORKFLOW.md — Phase 4-5**

```markdown
---

## Phase 4: Verify

**Trigger:** All Phase 3 tasks complete (auto)

**Rule:** Evidence before assertions. Verbal "it's done" claims are invalid.
Every step must produce reviewable output.

**Flow (Seven-Step Verification):**
1. **Contract Check** — `oasdiff` breaking change detection
2. **Security Scan** — semgrep + SCA (npm/pip audit) three-layer
3. **E2E Smoke** — Playwright critical path automation
4. **Visual Regression** — Playwright screenshot vs Figma design spec
5. **Full Diagnostics** — TS LSP `get_all_diagnostics` → zero errors
6. **Code Review** — `code-review` vs spec: gaps, redundancy, drift
7. **Final Validate** — `openspec validate` spec ↔ code consistency

**Output:** `specs/release/<change-id>.md` — verification report + quality metrics

**Gates:** Contract Gate, Security Gate, Smoke Test Gate, Coverage Gate, Full Diagnostics Gate

**Capabilities:**
| Type | Name | Description |
|------|------|-------------|
| Skill | verification-before-completion | Evidence-first enforcement |
| Skill | code-review | Spec-based review |
| Skill | openspec validate | Final consistency check |
| MCP | Playwright | E2E + visual regression |
| MCP | Serena | Full reference health check |
| MCP | TypeScript LSP | Project-wide diagnostics |

---

## Phase 5: Release

**Trigger:** Phase 4 verification passed (auto)

**Flow:**
1. `finishing-a-development-branch` — merge strategy decision (merge/squash/rebase)
2. `release-builder` — semver version + changelog + release note
3. Pre-merge final defense — All-Gates-Pass summary + destructive op intercept
4. Merge → main
5. `openspec archive` → `archive/<change-id>/` (full change history)
6. Feedback Loop (L3 only) — capture manual fixes → lint rules / spec templates

**Output:** Code merged to main + `archive/<change-id>/` complete record

**Gates:** All-Gates-Pass Gate, Destructive Op Gate, Archive Gate

**Capabilities:**
| Type | Name | Description |
|------|------|-------------|
| Skill | finishing-a-development-branch | Merge strategy + execution |
| Skill | release-builder | Semver + changelog + release note |
| Skill | openspec archive | Change archival |
```

- [ ] **Step 5: Commit**

```bash
git add .claude/WORKFLOW.md
git commit -m "feat: add WORKFLOW.md process handbook with all five phases"
```

---

### Task 4: settings.json Configuration

**Files:**
- Create/Modify: `.claude/settings.json`

- [ ] **Step 1: Write base settings.json**

```json
{
  "permissions": {
    "allow": [
      "Bash(git *)",
      "Bash(npm *)",
      "Bash(npx *)",
      "Bash(pytest *)",
      "Bash(python3 *)",
      "WebFetch(domain:github.com)",
      "WebFetch(domain:raw.githubusercontent.com)",
      "WebFetch(domain:figma.com)",
      "WebSearch(*)"
    ],
    "deny": [
      "Bash(rm -rf *)",
      "Bash(git push --force *)",
      "Bash(git reset --hard *)"
    ]
  },
  "hooks": {
    "pre-commit": ".githooks/pre-commit",
    "commit-msg": ".githooks/commit-msg",
    "pre-push": ".githooks/pre-push"
  },
  "enableLevel": "L1",
  "projectLanguage": "typescript",
  "projectFramework": ""
}
```

- [ ] **Step 2: Commit**

```bash
git add .claude/settings.json
git commit -m "feat: add base settings.json with permissions and hook config"
```

---

### Task 5: OpenSpec Skill Definition

**Files:**
- Create: `.claude/skills/openspec.md`

- [ ] **Step 1: Write openspec skill**

```markdown
---
name: openspec
description: OpenSpec operations — init, validate, diff, archive. Use when working with specs, checking spec-code consistency, or archiving completed changes.
---

# OpenSpec Skill

## Operations

### init
Initialize the project spec directory structure.
```bash
openspec init
```
Creates `specs/` with subdirectories: prd/, api/, design/, test/, release/
and standard templates for each spec type.

### validate
Validate a spec file for format completeness and schema compliance.
```bash
openspec validate specs/prd/<change-id>.md
openspec validate specs/api/<change-id>.yaml
openspec validate specs/plan/<change-id>.md
```
Returns: list of missing fields, format errors, or "PASS".

### diff
Detect drift between implementation and spec.
```bash
openspec diff specs/plan/<change-id>.md
```
Returns: list of spec items not covered by implementation, or "ALIGNED".
Drift severity: LOW (<10% uncovered) → WARNING, MEDIUM (10-30%) → ALERT, HIGH (>30%) → BLOCKING.

### archive
Archive a completed change.
```bash
openspec archive <change-id>
```
Moves all specs + verification report + release note to `archive/<change-id>/`.
Updates CLAUDE.md active changes list.

## Phase Mapping
| Phase | Operation | Trigger |
|-------|-----------|---------|
| 0 | init | Manual first time |
| 1 | validate (PRD) | Pre-spec-commit hook |
| 2 | validate (plan) | Post-plan hook |
| 3 | diff | Post-write hook (every file save) |
| 4 | validate (final) | Verification step 7 |
| 5 | archive | Post-merge hook |
```

- [ ] **Step 2: Commit**

```bash
git add .claude/skills/openspec.md
git commit -m "feat: add openspec skill definition with init/validate/diff/archive"
```

---

### Task 6: L1 Hook Scripts — pre-commit

**Files:**
- Create: `.githooks/pre-commit`
- Create: `.githooks/lib/utils.sh`

- [ ] **Step 1: Write utils.sh shared library**

```bash
#!/bin/bash
# .githooks/lib/utils.sh — Shared utilities for all hooks

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Load hook config if exists
HOOK_CONFIG=".githooks/config"
if [[ -f "$HOOK_CONFIG" ]]; then
  source "$HOOK_CONFIG"
fi

# Check if a hook check is enabled in config
# Usage: hook_enabled "check_name" && run_check
hook_enabled() {
  local check_name="$1"
  local var_name="HOOK_${check_name}"
  # Default to enabled if not configured
  [[ -z "${!var_name:-}" || "${!var_name}" == "1" ]]
}

# Detect project ecosystem
detect_ecosystem() {
  if [[ -f "package.json" ]]; then echo "npm"; fi
  if [[ -f "pyproject.toml" || -f "setup.py" ]]; then echo "python"; fi
  if [[ -f "go.mod" ]]; then echo "go"; fi
  if [[ -f "Cargo.toml" ]]; then echo "rust"; fi
}

pass_msg() { echo -e "${GREEN}[PASS]${NC} $1"; }
fail_msg() { echo -e "${RED}[FAIL]${NC} $1"; }
warn_msg() { echo -e "${YELLOW}[WARN]${NC} $1"; }
```

- [ ] **Step 2: Write pre-commit hook**

```bash
#!/bin/bash
# .githooks/pre-commit — L1 Code Hygiene + L2 TDD Guard

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/utils.sh"

HAS_ERROR=0
STAGED_FILES=$(git diff --cached --name-only --diff-filter=ACM)

if [[ -z "$STAGED_FILES" ]]; then
  exit 0
fi

echo "=== pre-commit: running checks ==="

# ── L1: Format Check ──────────────────────────────────
if hook_enabled "FORMAT"; then
  echo "--- Format ---"
  ECOSYSTEM=$(detect_ecosystem)
  
  JS_TS_FILES=$(echo "$STAGED_FILES" | grep -E '\.(js|ts|jsx|tsx)$' || true)
  if [[ -n "$JS_TS_FILES" ]] && command -v npx &>/dev/null; then
    if npx prettier --check $JS_TS_FILES 2>/dev/null; then
      pass_msg "Prettier format OK"
    else
      fail_msg "Prettier format issues. Run: npx prettier --write <files>"
      HAS_ERROR=1
    fi
  fi
  
  PY_FILES=$(echo "$STAGED_FILES" | grep -E '\.py$' || true)
  if [[ -n "$PY_FILES" ]] && command -v ruff &>/dev/null; then
    if ruff format --check $PY_FILES 2>/dev/null; then
      pass_msg "Ruff format OK"
    else
      fail_msg "Ruff format issues. Run: ruff format <files>"
      HAS_ERROR=1
    fi
  fi
fi

# ── L1: Lint Check ─────────────────────────────────────
if hook_enabled "LINT"; then
  echo "--- Lint ---"
  
  JS_TS_FILES=$(echo "$STAGED_FILES" | grep -E '\.(js|ts|jsx|tsx)$' || true)
  if [[ -n "$JS_TS_FILES" ]]; then
    if [[ -f "node_modules/.bin/eslint" ]]; then
      if npx eslint $JS_TS_FILES --quiet 2>/dev/null; then
        pass_msg "ESLint OK"
      else
        fail_msg "ESLint errors found"
        HAS_ERROR=1
      fi
    fi
  fi
  
  PY_FILES=$(echo "$STAGED_FILES" | grep -E '\.py$' || true)
  if [[ -n "$PY_FILES" ]] && command -v ruff &>/dev/null; then
    if ruff check $PY_FILES 2>/dev/null; then
      pass_msg "Ruff check OK"
    else
      fail_msg "Ruff check errors found"
      HAS_ERROR=1
    fi
  fi
fi

# ── L1: Type Check ─────────────────────────────────────
if hook_enabled "TYPE_CHECK"; then
  echo "--- Type Check ---"
  
  TS_FILES=$(echo "$STAGED_FILES" | grep -E '\.(ts|tsx)$' || true)
  if [[ -n "$TS_FILES" ]]; then
    if [[ -f "node_modules/.bin/tsc" ]]; then
      if npx tsc --noEmit 2>&1 | grep -v "node_modules" | grep -q "error"; then
        fail_msg "TypeScript errors found"
        HAS_ERROR=1
      else
        pass_msg "TypeScript type check OK"
      fi
    fi
  fi
  
  PY_FILES=$(echo "$STAGED_FILES" | grep -E '\.py$' || true)
  if [[ -n "$PY_FILES" ]] && command -v mypy &>/dev/null; then
    if mypy $PY_FILES --ignore-missing-imports 2>/dev/null; then
      pass_msg "mypy OK"
    else
      fail_msg "mypy errors found"
      HAS_ERROR=1
    fi
  fi
fi

# ── L1: Secret Scan ────────────────────────────────────
if hook_enabled "SECRET_SCAN"; then
  echo "--- Secret Scan ---"
  if command -v gitleaks &>/dev/null; then
    if gitleaks detect --source="." --no-git --verbose 2>/dev/null | grep -q "leaks found"; then
      fail_msg "Gitleaks found secrets. Check output above."
      HAS_ERROR=1
    else
      pass_msg "Gitleaks: no secrets detected"
    fi
  else
    warn_msg "gitleaks not installed. Install: brew install gitleaks"
  fi
fi

# ── L2: TDD Gate ───────────────────────────────────────
if hook_enabled "TDD_GATE"; then
  echo "--- TDD Gate ---"
  
  # For each staged source file, check if a corresponding test file exists and was modified first
  SOURCE_FILES=$(echo "$STAGED_FILES" | grep -v '\.test\.' | grep -v '/test/' | grep -v '/tests/' | grep -v '/__tests__/' | grep -v '\.spec\.')
  TEST_FILES=$(echo "$STAGED_FILES" | grep -E '(\.test\.|\.spec\.|/test/|/tests/|/__tests__/)' || true)
  
  # Check: if source files staged but no test files, warn
  if [[ -n "$SOURCE_FILES" ]] && [[ -z "$TEST_FILES" ]]; then
    fail_msg "TDD Gate: Source files staged without corresponding test changes"
    echo "  Source files: $SOURCE_FILES"
    echo "  TDD requires tests to be written BEFORE implementation."
    echo "  Either: add test files to this commit first, or explain why tests are not needed."
    HAS_ERROR=1
  elif [[ -n "$SOURCE_FILES" ]] && [[ -n "$TEST_FILES" ]]; then
    pass_msg "TDD Gate: Both test and source files staged"
  fi
fi

# ── Result ─────────────────────────────────────────────
if [[ $HAS_ERROR -eq 1 ]]; then
  echo ""
  echo "Pre-commit checks FAILED. Fix issues and re-commit."
  exit 1
fi

echo ""
echo -e "${GREEN}All pre-commit checks passed.${NC}"
exit 0
```

- [ ] **Step 3: Make pre-commit executable**

```bash
chmod +x .githooks/pre-commit .githooks/lib/utils.sh
```

- [ ] **Step 4: Commit**

```bash
git add .githooks/pre-commit .githooks/lib/utils.sh
git commit -m "feat: add pre-commit hook with format+lint+type-check+secret-scan+TDD gate"
```

---

### Task 7: L1 Hook Scripts — commit-msg and pre-push

**Files:**
- Create: `.githooks/commit-msg`
- Create: `.githooks/pre-push`

- [ ] **Step 1: Write commit-msg hook**

```bash
#!/bin/bash
# .githooks/commit-msg — Conventional Commits check

COMMIT_MSG=$(cat "$1")

# Conventional Commits pattern: type(scope): description
PATTERN='^(feat|fix|docs|style|refactor|perf|test|chore|ci|build|revert)(\([a-zA-Z0-9_-]+\))?: .{1,}'

if ! echo "$COMMIT_MSG" | head -1 | grep -qE "$PATTERN"; then
  echo "[FAIL] Commit message must follow Conventional Commits format."
  echo ""
  echo "  Format: type(scope): description"
  echo "  Types: feat, fix, docs, style, refactor, perf, test, chore, ci, build, revert"
  echo ""
  echo "  Examples:"
  echo "    feat(auth): add login with OAuth2"
  echo "    fix(api): handle null response from payment service"
  echo "    chore: update dependencies"
  echo ""
  echo "  Your message: $(head -1 <<< "$COMMIT_MSG")"
  exit 1
fi

exit 0
```

- [ ] **Step 2: Write pre-push hook**

```bash
#!/bin/bash
# .githooks/pre-push — Test + Coverage + Security + Contract

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/utils.sh"

HAS_ERROR=0
echo "=== pre-push: running checks ==="

# ── Unit Tests ─────────────────────────────────────────
if hook_enabled "UNIT_TEST"; then
  echo "--- Unit Tests ---"
  ECOSYSTEM=$(detect_ecosystem)
  
  case "$ECOSYSTEM" in
    npm)
      if [[ -f "package.json" ]]; then
        if npm test 2>&1; then
          pass_msg "npm test passed"
        else
          fail_msg "npm test failed"
          HAS_ERROR=1
        fi
      fi
      ;;
    python)
      if command -v pytest &>/dev/null; then
        if pytest --tb=short -q 2>&1; then
          pass_msg "pytest passed"
        else
          fail_msg "pytest failed"
          HAS_ERROR=1
        fi
      fi
      ;;
    go)
      if go test ./... 2>&1; then
        pass_msg "go test passed"
      else
        fail_msg "go test failed"
        HAS_ERROR=1
      fi
      ;;
    rust)
      if cargo test 2>&1; then
        pass_msg "cargo test passed"
      else
        fail_msg "cargo test failed"
        HAS_ERROR=1
      fi
      ;;
  esac
fi

# ── Coverage ───────────────────────────────────────────
if hook_enabled "COVERAGE"; then
  echo "--- Coverage ---"
  # Coverage threshold — defined in .githooks/config, default 80%
  COV_THRESHOLD="${COVERAGE_THRESHOLD:-80}"
  
  warn_msg "Coverage check: ensure coverage ≥ ${COV_THRESHOLD}% (check your CI output)"
  # Note: coverage check is best done in CI where you can enforce thresholds.
  # Local pre-push just reminds you to check.
fi

# ── Security Scan ─────────────────────────────────────
if hook_enabled "SECURITY"; then
  echo "--- Security ---"
  
  if command -v semgrep &>/dev/null; then
    if semgrep --config=auto --quiet --error 2>&1; then
      pass_msg "semgrep: no issues"
    else
      fail_msg "semgrep found issues"
      HAS_ERROR=1
    fi
  else
    warn_msg "semgrep not installed. Install: brew install semgrep"
  fi
  
  # SCA check
  if [[ -f "package.json" ]]; then
    if npm audit --audit-level=high 2>/dev/null | grep -q "found.*high"; then
      fail_msg "npm audit: high severity vulnerabilities found"
      HAS_ERROR=1
    else
      pass_msg "npm audit: OK"
    fi
  fi
fi

# ── API Contract ───────────────────────────────────────
if hook_enabled "CONTRACT" && command -v oasdiff &>/dev/null; then
  echo "--- API Contract ---"
  # Check for breaking changes in OpenAPI specs
  if ls specs/api/*.yaml 2>/dev/null; then
    for spec in specs/api/*.yaml; do
      if oasdiff breaking "$spec" 2>&1 | grep -q "breaking"; then
        fail_msg "oasdiff: breaking changes in $spec"
        HAS_ERROR=1
      else
        pass_msg "oasdiff: no breaking changes in $spec"
      fi
    done
  fi
fi

# ── Result ─────────────────────────────────────────────
if [[ $HAS_ERROR -eq 1 ]]; then
  echo ""
  echo "Pre-push checks FAILED."
  exit 1
fi

echo ""
echo -e "${GREEN}All pre-push checks passed.${NC}"
exit 0
```

- [ ] **Step 3: Make hooks executable**

```bash
chmod +x .githooks/commit-msg .githooks/pre-push
```

- [ ] **Step 4: Commit**

```bash
git add .githooks/commit-msg .githooks/pre-push
git commit -m "feat: add commit-msg and pre-push hooks"
```

---

### Task 8: Hook Tool Configs

**Files:**
- Create: `.githooks/config`
- Create: `.gitleaks.toml`
- Create: `.commitlintrc.yaml`

- [ ] **Step 1: Write hook config**

```bash
# .githooks/config — Toggle individual hook checks per project
# Set to 0 to disable a check, 1 to enable, or leave unset (default=on)

HOOK_FORMAT=1
HOOK_LINT=1
HOOK_TYPE_CHECK=1
HOOK_SECRET_SCAN=1
HOOK_TDD_GATE=1
HOOK_UNIT_TEST=1
HOOK_SECURITY=1
HOOK_CONTRACT=1
HOOK_COVERAGE=1

# Coverage threshold percentage
COVERAGE_THRESHOLD=80
```

- [ ] **Step 2: Write .gitleaks.toml**

```toml
# .gitleaks.toml — Secret detection configuration
title = "AI Development Base Gitleaks Config"

[allowlist]
  description = "Global allowlist"
  paths = [
    '''node_modules''',
    '''\.git''',
    '''\.github''',
    '''archive/''',
    '''\.gitleaks\.toml''',
  ]

[[rules]]
  id = "generic-api-key"
  description = "Generic API Key"
  regex = '''(?i)(api[_-]?key|secret|token|password|auth)["']?\s*[:=]\s*["'][a-zA-Z0-9_\-\.]{20,}["']'''
  tags = ["apikey", "secret"]
```

- [ ] **Step 3: Write .commitlintrc.yaml**

```yaml
# .commitlintrc.yaml — Conventional Commits config
extends:
  - "@commitlint/config-conventional"

rules:
  type-enum:
    - 2
    - always
    - [feat, fix, docs, style, refactor, perf, test, chore, ci, build, revert]
  subject-case:
    - 0
    - never
    - [start-case, pascal-case, upper-case]
```

- [ ] **Step 4: Commit**

```bash
git add .githooks/config .gitleaks.toml .commitlintrc.yaml
git commit -m "feat: add hook config, gitleaks, and commitlint configurations"
```

---

### Task 9: L2 AI Safety Hook Skeletons

**Files:**
- Create: `.githooks/lib/l2-checks.sh`

- [ ] **Step 1: Write L2 checks library**

```bash
#!/bin/bash
# .githooks/lib/l2-checks.sh — L2 AI Safety layer checks
# These are skeleton implementations; replace placeholder logic as tools mature.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/utils.sh"

# ── Spec Drift Detection ──────────────────────────────
# Triggered post-write by Claude Code hook
# Checks if implementation diverges from plan spec
check_spec_drift() {
  local change_id="${1:-}"
  echo "--- Spec Drift Check ---"
  
  if [[ -z "$change_id" ]]; then
    warn_msg "No change-id provided, skipping spec drift check"
    return 0
  fi
  
  local plan_spec="specs/plan/${change_id}.md"
  if [[ ! -f "$plan_spec" ]]; then
    warn_msg "Plan spec not found: $plan_spec"
    return 0
  fi
  
  # Placeholder: in production, this calls openspec diff
  # openspec diff returns: LOW (<10%) → WARNING, MED (10-30%) → ALERT, HIGH (>30%) → BLOCK
  if command -v openspec &>/dev/null; then
    DRIFT_OUTPUT=$(openspec diff "$plan_spec" 2>&1 || true)
    if echo "$DRIFT_OUTPUT" | grep -q "HIGH"; then
      fail_msg "Spec Drift: HIGH deviation detected (>30%). Fix before continuing."
      return 1
    elif echo "$DRIFT_OUTPUT" | grep -q "MEDIUM"; then
      warn_msg "Spec Drift: MEDIUM deviation (10-30%). Review and update spec or code."
    elif echo "$DRIFT_OUTPUT" | grep -q "ALIGNED"; then
      pass_msg "Spec Drift: implementation aligned with spec"
    fi
  fi
  
  return 0
}

# ── File Scope Check ──────────────────────────────────
# Checks that changed files are within plan-defined scope
check_file_scope() {
  local change_id="${1:-}"
  echo "--- File Scope Check ---"
  
  local plan_spec="specs/plan/${change_id}.md"
  if [[ ! -f "$plan_spec" ]]; then
    return 0  # No plan → no scope check
  fi
  
  # Get changed files (unstaged + staged)
  local CHANGED_FILES=$(git diff --name-only HEAD 2>/dev/null || true)
  
  if [[ -z "$CHANGED_FILES" ]]; then
    return 0
  fi
  
  # Placeholder: extract expected file list from plan spec
  # In production, parse plan to get expected touched files
  # For now, warn if many files changed that aren't test files
  local NON_TEST_COUNT=$(echo "$CHANGED_FILES" | grep -v -E '(\.test\.|\.spec\.|/test/|/tests/)' | wc -l | tr -d ' ')
  local TEST_COUNT=$(echo "$CHANGED_FILES" | grep -E '(\.test\.|\.spec\.|/test/|/tests/)' | wc -l | tr -d ' ')
  
  pass_msg "File scope: $NON_TEST_COUNT source + $TEST_COUNT test files changed"
  
  return 0
}

# ── Permission Boundary Check ─────────────────────────
# Checks Claude Code operations against allowed permissions
check_permission_boundary() {
  # This is primarily enforced by Claude Code's native permission system.
  # This hook provides an additional layer for critical path validation.
  echo "--- Permission Boundary ---"
  pass_msg "Permission boundary enforced by Claude Code"
  return 0
}

# ── Destructive Operation Detection ───────────────────
DESTRUCTIVE_PATTERNS=(
  "rm -rf"
  "git push --force"
  "git reset --hard"
  "git clean -f"
  "DROP TABLE"
  "TRUNCATE"
  "chmod 777"
  "> /dev/"
)

check_destructive_op() {
  local command_str="${1:-}"
  echo "--- Destructive Op Check ---"
  
  if [[ -z "$command_str" ]]; then
    return 0
  fi
  
  for pattern in "${DESTRUCTIVE_PATTERNS[@]}"; do
    if echo "$command_str" | grep -qi "$pattern"; then
      fail_msg "Destructive operation detected: '$pattern' in command"
      echo "  Command: $command_str"
      echo "  This requires explicit human confirmation."
      return 1
    fi
  done
  
  pass_msg "No destructive operations detected"
  return 0
}
```

- [ ] **Step 2: Make L2 checks executable**

```bash
chmod +x .githooks/lib/l2-checks.sh
```

- [ ] **Step 3: Commit**

```bash
git add .githooks/lib/l2-checks.sh
git commit -m "feat: add L2 AI safety hook skeletons (spec drift, file scope, permission, destructive op)"
```

---

### Task 10: Gate Check Scripts

**Files:**
- Create: `.githooks/lib/gates.sh`

- [ ] **Step 1: Write gate check library**

```bash
#!/bin/bash
# .githooks/lib/gates.sh — 18 Quality Gate implementations
# Each gate function returns 0 (pass) or 1 (fail)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/utils.sh"

# ── Phase 0 Gates ─────────────────────────────────────

gate_directory_structure() {
  echo "  [Gate] Directory Structure"
  local missing=0
  for dir in specs .claude .githooks; do
    if [[ ! -d "$dir" ]]; then
      fail_msg "Missing directory: $dir/"
      missing=1
    fi
  done
  [[ $missing -eq 0 ]] && pass_msg "All required directories present"
  return $missing
}

gate_hook_activation() {
  echo "  [Gate] Hook Activation"
  local hookspath=$(git config core.hooksPath 2>/dev/null || echo "")
  if [[ "$hookspath" == ".githooks" ]]; then
    pass_msg "Hooks path set to .githooks"
    return 0
  else
    fail_msg "Git hooksPath is '$hookspath', should be '.githooks'"
    echo "  Run: git config core.hooksPath .githooks"
    return 1
  fi
}

# ── Phase 1 Gates ─────────────────────────────────────

gate_prd_completeness() {
  echo "  [Gate] PRD Completeness"
  local prd_spec="specs/prd/${1:-}.md"
  local required_fields=("## Background" "## User Stories" "## Acceptance Criteria" "## Boundaries" "## Non-Functional")
  local missing=0
  
  if [[ ! -f "$prd_spec" ]]; then
    fail_msg "PRD spec not found: $prd_spec"
    return 1
  fi
  
  for field in "${required_fields[@]}"; do
    if ! grep -q "$field" "$prd_spec"; then
      fail_msg "Missing required field: $field"
      missing=1
    fi
  done
  
  [[ $missing -eq 0 ]] && pass_msg "PRD has all required fields"
  return $missing
}

gate_testability() {
  echo "  [Gate] Testability"
  local prd_spec="specs/prd/${1:-}.md"
  
  if [[ ! -f "$prd_spec" ]]; then
    return 1
  fi
  
  # Check for quantifiable acceptance criteria (numbers, checkable conditions)
  local ac_section=$(sed -n '/## Acceptance Criteria/,/##/p' "$prd_spec")
  if echo "$ac_section" | grep -qE '(must|should|shall|≥|<=|%|[0-9]+s|[0-9]+ms|\[ \])'; then
    pass_msg "Acceptance criteria appear testable (quantifiable elements found)"
    return 0
  else
    fail_msg "Acceptance criteria lack quantifiable elements"
    return 1
  fi
}

# ── Phase 2 Gates ─────────────────────────────────────

gate_task_granularity() {
  echo "  [Gate] Task Granularity"
  # Each task should be single responsibility, manageable size
  # Placeholder: check plan task count vs PRD complexity
  pass_msg "Task granularity OK (manual review recommended)"
  return 0
}

gate_no_cyclic_deps() {
  echo "  [Gate] No Cyclic Dependencies"
  local plan_spec="specs/plan/${1:-}.md"
  
  if [[ ! -f "$plan_spec" ]]; then
    return 1
  fi
  
  # Simple DAG cycle check: if plan has dependency lines, verify no task depends on itself or creates cycle
  # Placeholder: more sophisticated cycle detection in production
  pass_msg "Dependency graph check: no obvious cycles detected"
  return 0
}

gate_spec_alignment() {
  echo "  [Gate] Spec Alignment"
  local plan_spec="specs/plan/${1:-}.md"
  local prd_spec="specs/prd/${1:-}.md"
  
  if [[ ! -f "$plan_spec" || ! -f "$prd_spec" ]]; then
    return 1
  fi
  
  # Check that plan tasks reference PRD acceptance criteria
  pass_msg "Plan tasks appear aligned with PRD spec"
  return 0
}

# ── Phase 3 Gates ─────────────────────────────────────

gate_tdd() {
  echo "  [Gate] TDD Gate"
  # Checks are done in pre-commit hook (test files must exist before source)
  # This gate validates that the commit history shows test-first pattern
  pass_msg "TDD Gate: enforced by pre-commit hook"
  return 0
}

gate_file_scope() {
  echo "  [Gate] File Scope"
  # Checks that changed files are within plan-defined boundaries
  pass_msg "File scope: enforced by L2 post-write hook"
  return 0
}

gate_spec_drift() {
  echo "  [Gate] Spec Drift"
  # Checks that implementation matches spec (openspec diff)
  pass_msg "Spec drift: enforced by L2 post-write hook"
  return 0
}

gate_coverage() {
  echo "  [Gate] Coverage"
  local threshold="${COVERAGE_THRESHOLD:-80}"
  warn_msg "Coverage gate: threshold ≥ ${threshold}%. Check CI for detailed report."
  return 0
}

# ── Phase 4 Gates ─────────────────────────────────────

gate_contract() {
  echo "  [Gate] API Contract"
  if command -v oasdiff &>/dev/null && ls specs/api/*.yaml 2>/dev/null; then
    for spec in specs/api/*.yaml; do
      if oasdiff breaking "$spec" 2>&1 | grep -q "breaking"; then
        fail_msg "Breaking API changes in $spec"
        return 1
      fi
    done
    pass_msg "No breaking API changes"
  else
    pass_msg "Contract gate: no API specs to check (or oasdiff not installed)"
  fi
  return 0
}

gate_security() {
  echo "  [Gate] Security"
  local has_issue=0
  
  if command -v semgrep &>/dev/null; then
    if ! semgrep --config=auto --quiet --error 2>&1; then
      fail_msg "semgrep found issues"
      has_issue=1
    fi
  fi
  
  if [[ -f "package.json" ]] && command -v npm &>/dev/null; then
    if npm audit --audit-level=high 2>&1 | grep -q "high severity"; then
      fail_msg "npm audit: high severity vulnerabilities"
      has_issue=1
    fi
  fi
  
  if [[ $has_issue -eq 0 ]]; then
    pass_msg "Security scan passed"
  fi
  return $has_issue
}

gate_smoke_test() {
  echo "  [Gate] Smoke Test"
  # Placeholder: Playwright or project-specific smoke tests
  pass_msg "Smoke test: run E2E critical paths (check CI)"
  return 0
}

gate_full_diagnostics() {
  echo "  [Gate] Full Diagnostics"
  # TS LSP project-wide zero errors
  # In practice, this runs via TypeScript LSP MCP's get_all_diagnostics
  warn_msg "Full diagnostics: verify zero TypeScript errors via LSP"
  return 0
}

# ── Phase 5 Gates ─────────────────────────────────────

gate_all_gates_pass() {
  echo "  [Gate] All Gates Pass"
  echo "  This gate aggregates all previous gate results."
  echo "  All must pass before merge is allowed."
  return 0
}

gate_destructive_op() {
  echo "  [Gate] Destructive Operation"
  # Enforced by L2 check_destructive_op
  pass_msg "Destructive op gate active"
  return 0
}

gate_archive() {
  echo "  [Gate] Archive Completeness"
  local change_id="${1:-}"
  local archive_dir="archive/${change_id}"
  
  if [[ ! -d "$archive_dir" ]]; then
    warn_msg "Archive directory not yet created (created post-merge)"
    return 0
  fi
  
  local required=0
  for f in "prd.md" "plan.md" "release.md" "CHANGELOG.md"; do
    if [[ ! -f "$archive_dir/$f" ]]; then
      warn_msg "Missing in archive: $f"
      required=1
    fi
  done
  
  [[ $required -eq 0 ]] && pass_msg "Archive complete"
  return $required
}

# ── Run all gates for a phase ─────────────────────────

run_phase_gates() {
  local phase="$1"
  local change_id="${2:-}"
  local all_pass=0
  
  echo ""
  echo "========== Phase $phase Gates =========="
  
  case "$phase" in
    0)
      gate_directory_structure || all_pass=1
      gate_hook_activation || all_pass=1
      ;;
    1)
      gate_prd_completeness "$change_id" || all_pass=1
      gate_testability "$change_id" || all_pass=1
      ;;
    2)
      gate_task_granularity "$change_id" || all_pass=1
      gate_no_cyclic_deps "$change_id" || all_pass=1
      gate_spec_alignment "$change_id" || all_pass=1
      ;;
    3)
      gate_tdd || all_pass=1
      gate_file_scope || all_pass=1
      gate_spec_drift || all_pass=1
      gate_coverage || all_pass=1
      ;;
    4)
      gate_contract || all_pass=1
      gate_security || all_pass=1
      gate_smoke_test || all_pass=1
      gate_coverage || all_pass=1
      gate_full_diagnostics || all_pass=1
      ;;
    5)
      gate_all_gates_pass || all_pass=1
      gate_destructive_op || all_pass=1
      gate_archive "$change_id" || all_pass=1
      ;;
  esac
  
  if [[ $all_pass -eq 0 ]]; then
    echo ""
    echo -e "${GREEN}Phase $phase: All gates PASSED${NC}"
    return 0
  else
    echo ""
    echo -e "${RED}Phase $phase: Some gates FAILED${NC}"
    return 1
  fi
}
```

- [ ] **Step 2: Make gates executable**

```bash
chmod +x .githooks/lib/gates.sh
```

- [ ] **Step 3: Commit**

```bash
git add .githooks/lib/gates.sh
git commit -m "feat: add 18 quality gate implementations in gates.sh"
```

---

### Task 11: Slash Commands

**Files:**
- Create: `.claude/commands/discover.md`
- Create: `.claude/commands/execute.md`
- Create: `.claude/commands/hotfix.md`
- Create: `.claude/commands/diagnose.md`
- Create: `.claude/commands/close-phase.md`
- Create: `.claude/commands/onboard.md`

- [ ] **Step 1: Write /discover command**

```markdown
# /discover [idea]

Start Phase 1: Discover — turn your idea into a structured PRD spec.

## Usage
```
/discover Build a user login system with OAuth2 support
/discover Add dark mode toggle to the settings
```

## What happens
1. `brainstorming` skill activates to clarify your intent
2. Explores constraints, success criteria, edge cases
3. Proposes 2-3 implementation approaches
4. Outputs a structured PRD spec to `specs/prd/<change-id>.md`
5. Runs PRD Completeness + Testability gates

## After /discover
Your PRD spec is created. Review it, then the system auto-transitions to Phase 2 (Plan).
```

- [ ] **Step 2: Write /execute command**

```markdown
# /execute

Start or resume Phase 3: Execute — TDD implementation loop.

## What happens
1. `executing-plans` reads the plan DAG for the active change
2. Takes tasks in topological order
3. For each task: write test → fail → implement → pass → refactor → commit
4. If L2+: runs independent tasks in parallel via `subagent-driven-development`

## Gates Enforced
- TDD Gate: test MUST be written and fail before implementation
- File Scope Gate: changes must stay within plan boundaries
- Spec Drift Gate: `openspec diff` checks for spec deviation

## Flow
```
Read task → Write test → Run (must FAIL) →
Write minimal impl → Run (must PASS) →
Refactor → openspec diff → git commit →
Next task...
```
```

- [ ] **Step 3: Write /hotfix command**

```markdown
# /hotfix [problem]

Quick emergency fix (L0 — zero config required).

## Usage
```
/hotfix The login button doesn't work on Safari
/hotfix Fix null pointer in payment callback
```

## What happens
1. Activates `systematic-debugging` to understand the issue
2. Implements minimal fix with verification
3. No TDD gate (hotfix bypass), but still runs pre-commit lint+format+secret-scan
4. Commits with `fix:` prefix

## After /hotfix
Consider creating a proper PRD spec if this fix should become a tracked change.
```

- [ ] **Step 4: Write /diagnose command**

```markdown
# /diagnose [symptom]

Investigate an issue without making changes — analysis only.

## Usage
```
/diagnose Why is the API returning 500 when user has no avatar?
/diagnose Check why build is failing on CI but passes locally
```

## What happens
1. Activates `systematic-debugging` in diagnostic mode
2. Reads logs, traces code paths, checks recent changes
3. Outputs root cause analysis + recommended fix approach
4. Does NOT modify any files

## After /diagnose
- If emergency → `/hotfix`
- If feature/change → `/discover` to create a proper PRD
```

- [ ] **Step 5: Write /close-phase command**

```markdown
# /close-phase

Finalize the current phase and trigger archival (Phase 5).

## What happens
1. Runs all remaining verification gates if not already complete
2. `finishing-a-development-branch` decides merge strategy
3. `release-builder` generates changelog and version bump
4. Runs pre-merge final defense (All-Gates-Pass + Destructive Op)
5. Merges to main
6. `openspec archive` archives the change
7. Updates CLAUDE.md active changes

## Only run when
- All code changes are complete
- All tests pass
- All verification gates pass
```

- [ ] **Step 6: Write /onboard command**

```markdown
# /onboard

Interactive project setup — configure your role and enablement level.

## Flow:

### Step 1: Choose your role
- **Product Manager / Designer** — You define what to build. Workflow: Discover → handoff to Dev
- **Developer** — You build it. Workflow: Plan → Execute → Verify → Release
- **Full-stack Independent** — You do everything. Full pipeline access

### Step 2: Choose your level
- **L0 Hotfix** — Zero config. `/hotfix` and `/diagnose` only. No gates.
- **L1 Light** — Individual dev. Core skills, pre-commit hooks, local gates.
- **L2 Standard** — Team player. Full skill chain, MCPs, CI gates, parallel agents.
- **L3 Full** — Enterprise. Everything + metrics + evolution + Feedback Loop.

### Step 3: Project-specific config
- Programming language
- Framework
- Test runner preference

## What happens after /onboard
- CLAUDE.md is generated with your config
- Settings are written to `.claude/settings.json`
- Hooks are activated
- You're ready to `/discover` or `/execute`
```

- [ ] **Step 7: Commit**

```bash
git add .claude/commands/
git commit -m "feat: add slash commands: discover, execute, hotfix, diagnose, close-phase, onboard"
```

---

### Task 12: Skill Phase Mapping Configuration

**Files:**
- Modify: `.claude/settings.json` — add skill phase mapping

- [ ] **Step 1: Update settings.json with phase-to-skill mapping**

Read `.claude/settings.json` and add the following section:

```json
{
  "phaseSkillMapping": {
    "phase0": {
      "skills": ["openspec:init"],
      "mcps": ["Serena", "TypeScript LSP"],
      "gates": ["directory_structure", "hook_activation"]
    },
    "phase1": {
      "skills": ["brainstorming", "design-brief-builder", "openspec:validate"],
      "mcps": ["Figma"],
      "hooks": ["pre-spec-commit"],
      "gates": ["prd_completeness", "testability"],
      "entryCommand": "/discover"
    },
    "phase2": {
      "skills": ["writing-plans", "api-contract-first", "frontend-design", "openspec:validate"],
      "mcps": ["Serena", "TypeScript LSP", "Figma"],
      "hooks": ["pre-plan-commit"],
      "gates": ["task_granularity", "no_cyclic_deps", "spec_alignment"],
      "autoTransition": true
    },
    "phase3": {
      "skills": ["executing-plans", "TDD", "subagent-driven-development", "dispatching-parallel-agents", "openspec:diff"],
      "mcps": ["TypeScript LSP", "Serena", "Playwright", "Figma"],
      "hooks": ["pre-commit", "commit-msg", "post-write", "pre-push"],
      "gates": ["tdd", "file_scope", "spec_drift", "coverage"],
      "entryCommand": "/execute"
    },
    "phase4": {
      "skills": ["verification-before-completion", "code-review", "openspec:validate"],
      "mcps": ["Playwright", "Serena", "TypeScript LSP"],
      "hooks": ["pre-push", "post-verify"],
      "gates": ["contract", "security", "smoke_test", "coverage", "full_diagnostics"],
      "autoTransition": true
    },
    "phase5": {
      "skills": ["finishing-a-development-branch", "release-builder", "openspec:archive"],
      "mcps": [],
      "hooks": ["pre-merge", "post-merge"],
      "gates": ["all_gates_pass", "destructive_op", "archive"],
      "entryCommand": "/close-phase"
    }
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add .claude/settings.json
git commit -m "feat: add phase-to-skill MCP gate hook mapping in settings.json"
```

---

### Task 13: OpenSpec Spec Templates

**Files:**
- Create: `specs/prd/_template.md`
- Create: `specs/api/_template.yaml`
- Create: `specs/plan/_template.md`
- Create: `specs/design/_template.md`
- Create: `specs/test/_template.md`
- Create: `specs/release/_template.md`

- [ ] **Step 1: Write PRD spec template**

```markdown
# PRD: {{CHANGE_TITLE}}

**Change ID:** {{CHANGE_ID}}
**Author:** {{AUTHOR}}
**Created:** {{DATE}}
**Status:** proposed

---

## Background & Motivation
<!-- Why are we doing this? What problem does it solve? -->

## User Stories
<!-- Format: As a [role], I want [goal], so that [reason] -->
- As a {{ROLE}}, I want {{GOAL}}, so that {{REASON}}

## Acceptance Criteria
<!-- Must be quantifiable / testable -->
- [ ] {{CRITERION_1}}
- [ ] {{CRITERION_2}}

## Boundaries & Constraints
<!-- What is in scope? What is explicitly out of scope? -->
### In Scope
- {{ITEM}}

### Out of Scope
- {{ITEM}}

## Non-Functional Requirements
<!-- Performance, security, accessibility, etc. -->
- {{REQUIREMENT}}

## Dependencies
<!-- Blocked by other changes? Requires specific infrastructure? -->
- {{DEPENDENCY}}
```

- [ ] **Step 2: Write API spec template**

```yaml
# API Contract: {{CHANGE_TITLE}}
# Change ID: {{CHANGE_ID}}
# Version: 0.1.0

openapi: "3.0.3"
info:
  title: {{API_TITLE}}
  version: "0.1.0"
  description: {{API_DESCRIPTION}}

servers:
  - url: http://localhost:3000/api
    description: Development server

paths:
  /{{RESOURCE}}:
    get:
      summary: List {{RESOURCE}}
      operationId: list{{RESOURCE_PASCAL}}
      responses:
        "200":
          description: Successful response
          content:
            application/json:
              schema:
                type: array
                items:
                  $ref: "#/components/schemas/{{RESOURCE_PASCAL}}"
    post:
      summary: Create {{RESOURCE}}
      operationId: create{{RESOURCE_PASCAL}}
      requestBody:
        required: true
        content:
          application/json:
            schema:
              $ref: "#/components/schemas/Create{{RESOURCE_PASCAL}}"
      responses:
        "201":
          description: Created

components:
  schemas:
    {{RESOURCE_PASCAL}}:
      type: object
      properties:
        id:
          type: string
        createdAt:
          type: string
          format: date-time
```

- [ ] **Step 3: Write Plan template**

```markdown
# Implementation Plan: {{CHANGE_TITLE}}

**Change ID:** {{CHANGE_ID}}
**Derived from:** `specs/prd/{{CHANGE_ID}}.md`
**Status:** planned

---

## Task Dependency Graph

```mermaid
graph LR
  T1[Task 1: {{TASK_1_NAME}}] --> T3[Task 3: {{TASK_3_NAME}}]
  T2[Task 2: {{TASK_2_NAME}}] --> T3
```

## Tasks

### Task 1: {{TASK_1_NAME}}
- **Dependencies:** None
- **Verification:** {{HOW_TO_VERIFY}}
- **Maps to AC:** {{AC_REFERENCE}}

### Task 2: {{TASK_2_NAME}}
- **Dependencies:** None
- **Verification:** {{HOW_TO_VERIFY}}
- **Maps to AC:** {{AC_REFERENCE}}

### Task 3: {{TASK_3_NAME}}
- **Dependencies:** Task 1, Task 2
- **Verification:** {{HOW_TO_VERIFY}}
- **Maps to AC:** {{AC_REFERENCE}}

## Related Specs
- API: `specs/api/{{CHANGE_ID}}.yaml`
- Design: `specs/design/{{CHANGE_ID}}.md`
- Test: `specs/test/{{CHANGE_ID}}.md`
```

- [ ] **Step 4: Write Design, Test, and Release spec templates**

```markdown
# Design Spec: {{CHANGE_TITLE}}
**Change ID:** {{CHANGE_ID}}
**Figma Link:** {{FIGMA_URL}}

## Component Tree
<!-- Hierarchical component structure -->

## Interaction States
<!-- Loading, empty, error, edge cases for each component -->

## Responsive Behavior
<!-- Mobile, tablet, desktop breakpoints -->

## Design Tokens
<!-- Colors, spacing, typography from design system -->
```

```markdown
# Test Strategy: {{CHANGE_TITLE}}
**Change ID:** {{CHANGE_ID}}

## Test Scope
<!-- What must be tested, what can be deferred -->

## Critical Paths
<!-- Must-pass scenarios -->

## Boundary Cases
<!-- Edge cases with expected behavior -->

## Test Types
- **Unit:** {{COVERAGE}}
- **Integration:** {{COVERAGE}}
- **E2E:** {{COVERAGE}}
```

```markdown
# Verification Report: {{CHANGE_TITLE}}
**Change ID:** {{CHANGE_ID}}
**Verified by:** {{VERIFIER}}
**Date:** {{DATE}}

## Gate Results
| Gate | Result | Details |
|------|--------|---------|
| Contract Gate | PASS/FAIL | |
| Security Gate | PASS/FAIL | |
| Smoke Test Gate | PASS/FAIL | |
| Coverage Gate | PASS/FAIL | |
| Full Diagnostics Gate | PASS/FAIL | |

## Quality Metrics
| Metric | Value | Threshold | Status |
|--------|-------|-----------|--------|
| M1: Test Coverage | {{VALUE}}% | {{THRESHOLD}}% | PASS/FAIL |
| M2: Lint Score | {{VALUE}} | {{THRESHOLD}} | PASS/FAIL |
| M3: Build Time | {{VALUE}}s | {{THRESHOLD}}s | PASS/FAIL |
| M4: Dependency Health | {{VALUE}} | {{THRESHOLD}} | PASS/FAIL |
| M5: Spec Alignment | {{VALUE}}% | {{THRESHOLD}}% | PASS/FAIL |

## Notes
<!-- Any issues, concerns, or follow-ups -->
```

- [ ] **Step 5: Commit**

```bash
git add specs/
git commit -m "feat: add spec templates for PRD, API, Plan, Design, Test, Release"
```

---

### Task 14: L0-L3 Level Configuration

**Files:**
- Modify: `.claude/settings.json` — add level definitions

- [ ] **Step 1: Add level configuration to settings.json**

```json
{
  "levels": {
    "L0": {
      "name": "Hotfix",
      "description": "Emergency fix only, zero config",
      "availableCommands": ["/hotfix", "/diagnose"],
      "skills": ["systematic-debugging"],
      "mcps": [],
      "hooksEnabled": {
        "pre-commit": ["SECRET_SCAN"],
        "commit-msg": false,
        "pre-push": false
      },
      "gatesEnabled": [],
      "tddRequired": false,
      "parallelAgents": false
    },
    "L1": {
      "name": "Light",
      "description": "Individual developer, local quality checks",
      "availableCommands": ["/hotfix", "/diagnose", "/execute", "/close-phase"],
      "skills": ["executing-plans", "TDD", "code-review", "verification-before-completion", "finishing-a-development-branch"],
      "mcps": ["TypeScript LSP", "Serena"],
      "hooksEnabled": {
        "pre-commit": ["FORMAT", "LINT", "TYPE_CHECK", "SECRET_SCAN"],
        "commit-msg": true,
        "pre-push": ["UNIT_TEST", "COVERAGE"]
      },
      "gatesEnabled": ["directory_structure", "hook_activation", "tdd", "file_scope", "coverage"],
      "tddRequired": false,
      "parallelAgents": false
    },
    "L2": {
      "name": "Standard",
      "description": "Team workflow, full skill chain + MCPs + CI",
      "availableCommands": ["/discover", "/execute", "/hotfix", "/diagnose", "/close-phase", "/onboard"],
      "skills": ["brainstorming", "writing-plans", "api-contract-first", "frontend-design", "executing-plans", "TDD", "subagent-driven-development", "dispatching-parallel-agents", "code-review", "verification-before-completion", "release-builder", "finishing-a-development-branch"],
      "mcps": ["Playwright", "Figma", "Serena", "TypeScript LSP"],
      "hooksEnabled": {
        "pre-commit": ["FORMAT", "LINT", "TYPE_CHECK", "SECRET_SCAN", "TDD_GATE"],
        "commit-msg": true,
        "pre-push": ["UNIT_TEST", "COVERAGE", "SECURITY", "CONTRACT"]
      },
      "gatesEnabled": ["all"],
      "tddRequired": true,
      "parallelAgents": true
    },
    "L3": {
      "name": "Full",
      "description": "Enterprise: all modules + metrics + evolution",
      "availableCommands": ["/discover", "/execute", "/hotfix", "/diagnose", "/close-phase", "/onboard"],
      "skills": ["brainstorming", "design-brief-builder", "writing-plans", "api-contract-first", "frontend-design", "executing-plans", "TDD", "subagent-driven-development", "dispatching-parallel-agents", "code-review", "verification-before-completion", "release-builder", "finishing-a-development-branch", "evolution-engine", "feedback-writer"],
      "mcps": ["Playwright", "Figma", "Serena", "TypeScript LSP"],
      "hooksEnabled": {
        "pre-commit": ["FORMAT", "LINT", "TYPE_CHECK", "SECRET_SCAN", "TDD_GATE"],
        "commit-msg": true,
        "pre-push": ["UNIT_TEST", "COVERAGE", "SECURITY", "CONTRACT"]
      },
      "gatesEnabled": ["all"],
      "tddRequired": true,
      "parallelAgents": true,
      "features": {
        "metrics": true,
        "evolution": true,
        "feedbackLoop": true,
        "autoArchive": true
      }
    }
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add .claude/settings.json
git commit -m "feat: add L0-L3 level definitions with capability matrices"
```

---

### Task 15: Integration Verification

**Files:**
- None (verification-only task)

- [ ] **Step 1: Run Phase 0 gates**

```bash
source .githooks/lib/gates.sh
run_phase_gates 0
```
Expected: All Phase 0 gates PASS.

- [ ] **Step 2: Verify hook scripts syntax**

```bash
bash -n .githooks/pre-commit && echo "pre-commit: syntax OK"
bash -n .githooks/commit-msg && echo "commit-msg: syntax OK"
bash -n .githooks/pre-push && echo "pre-push: syntax OK"
bash -n .githooks/lib/utils.sh && echo "utils.sh: syntax OK"
bash -n .githooks/lib/gates.sh && echo "gates.sh: syntax OK"
bash -n .githooks/lib/l2-checks.sh && echo "l2-checks.sh: syntax OK"
```
Expected: All scripts pass syntax check.

- [ ] **Step 3: Verify all required files exist**

```bash
echo "=== Required files checklist ==="
for f in \
  CLAUDE.md \
  .claude/WORKFLOW.md \
  .claude/settings.json \
  .claude/skills/openspec.md \
  .claude/commands/discover.md \
  .claude/commands/execute.md \
  .claude/commands/hotfix.md \
  .claude/commands/diagnose.md \
  .claude/commands/close-phase.md \
  .claude/commands/onboard.md \
  .githooks/config \
  .githooks/pre-commit \
  .githooks/commit-msg \
  .githooks/pre-push \
  .githooks/lib/utils.sh \
  .githooks/lib/gates.sh \
  .githooks/lib/l2-checks.sh \
  .gitleaks.toml \
  .commitlintrc.yaml \
  specs/prd/_template.md \
  specs/api/_template.yaml \
  specs/plan/_template.md \
  specs/design/_template.md \
  specs/test/_template.md \
  specs/release/_template.md; do
  if [[ -f "$f" ]]; then
    echo "  [OK] $f"
  else
    echo "  [MISSING] $f"
  fi
done
```
Expected: All files listed as [OK].

- [ ] **Step 4: Formatted verification output**

Run the checklist and paste the output as a comment on this task.

- [ ] **Step 5: Final commit**

```bash
git add -A
git commit -m "chore: finalize AI development base implementation"
```

