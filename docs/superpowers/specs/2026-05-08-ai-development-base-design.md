# AI Development Base: OpenSpec + Superpowers + Claude Code Workflow Design

## Metadata

- **Created:** 2026-05-08
- **Status:** Design Approved
- **Version:** 1.0.0

---

## 1. Overview

### 1.1 Purpose

构建一个面向产研团队的 AI 开发基座（AI Development Base），融合 OpenSpec（规格标准 + 变更管理）、Superpowers（流程骨架）和 Claude Code（执行引擎），为产品经理、设计师、开发者、测试人员提供标准化的研发工作流。

### 1.2 Design Principles

- **渐进式启用（L0-L3）**：从零配置到企业全量，用户按需选级别
- **模块化可插拔**：Skill / MCP / Hook / Gate 在每个级别均可独立插拔
- **自动触发**：阶段流转、Hook 触发、Gate 检查全部自动，无需人工干预
- **证据先于断言**：禁止口头声称完成，必须运行验证命令并确认输出
- **Spec 即约束**：OpenSpec 不是阶段快照文档，而是贯穿全流程的持续约束

---

## 2. Architecture

### 2.1 Four-Layer Architecture

```
第一层 — OpenSpec Core（大脑 + 操作 Skill）
┌──────────────────────────────────────────────────┐
│  规格标准：PRD · API · Design · Test · Release    │
│  变更管理：propose → review → implement → archive │
│  操作 Skill：init / validate / diff / archive     │
└──────────────────────────────────────────────────┘
                        │
                        ▼
第二层 — Superpowers 流程骨架（脊椎）
┌──────────────────────────────────────────────────┐
│  Discover → Plan → Execute → Verify → Release    │
└──────────────────────────────────────────────────┘
                        │
                        ▼
第三层 — 可插拔能力模块
┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐
│  Skill   │ │   MCP    │ │  Hook    │ │  Gate    │
│          │ │          │ │          │ │          │
│ openspec │ │ Playwright│ │ L1 代码  │ │ TDD      │
│ brain-   │ │ Figma    │ │ L2 AI   │ │ Smoke    │
│ storming │ │ Serena   │ │ L3 演化  │ │ Security │
│ writing- │ │ TS LSP   │ │          │ │ Contract │
│ plans    │ │ ...      │ │          │ │ Coverage │
│ exec-    │ │          │ │          │ │          │
│ plans    │ │          │ │          │ │          │
│ TDD      │ │          │ │          │ │          │
│ code-    │ │          │ │          │ │          │
│ review   │ │          │ │          │ │          │
│ frontend │ │          │ │          │ │          │
│ -design  │ │          │ │          │ │          │
│ api-     │ │          │ │          │ │          │
│ contract │ │          │ │          │ │          │
└──────────┘ └──────────┘ └──────────┘ └──────────┘

第四层 — Agent 执行层（隔离环境）
┌──────────────────────────────────────────────────┐
│  并行调度  ·  Git Worktree 隔离  ·  会话独立      │
│  (dispatching-parallel-agents / subagent-driven- │
│   development / using-git-worktrees)              │
└──────────────────────────────────────────────────┘
```

### 2.2 Enablement Levels (L0-L3)

| Level | Target Users | Capabilities |
|-------|-------------|--------------|
| **L0 急救** | Anyone | Single skill `/hotfix`, zero config |
| **L1 轻量** | Individual dev | Core skills, local gates |
| **L2 标准** | Product + dev teams | Full skill chain + MCP + CI gates + parallel agents |
| **L3 全量** | Enterprise | All modules + multi-MCP + full hooks + metrics + evolution |

---

## 3. Five-Phase Lifecycle

### Phase 0: Project Initialization

**Trigger:** New project or existing project integrating the base

```
    ┌──────────┐     ┌──────────────┐     ┌──────────────┐
    │ openspec │────▶│  .claude/    │────▶│  .githooks/  │
    │  init    │     │  config      │     │  activation  │
    └──────────┘     └──────────────┘     └──────────────┘
         │                 │                     │
         ▼                 ▼                     ▼
    specs/           commands/            git config
    ├── prd/         skills/              core.hooksPath
    ├── api/         settings.json        .githooks
    ├── design/      WORKFLOW.md
    ├── test/
    └── release/
```

**Steps:**

| Step | Action | Output |
|------|--------|--------|
| 1 | `openspec init` | `specs/` directory + standard templates |
| 2 | Deploy `.claude/` config | commands, skills, settings, WORKFLOW.md |
| 3 | Deploy `.githooks/` + `.gitleaks.toml` + `.commitlintrc.yaml` | L1 hooks in place |
| 4 | `git config core.hooksPath .githooks` | Hooks activated |
| 5 | `/onboard` select role + level | L0-L3 scope confirmed |

**Resulting structure:**

```
project/
├── specs/
│   ├── prd/
│   ├── api/
│   ├── design/
│   ├── test/
│   └── release/
├── .claude/
│   ├── commands/
│   ├── skills/
│   ├── settings.json
│   └── WORKFLOW.md
├── .githooks/
│   ├── pre-commit
│   ├── commit-msg
│   ├── pre-push
│   └── config
├── .github/workflows/
├── .gitleaks.toml
└── .commitlintrc.yaml
```

**Capabilities:**

| Type | Name | Description |
|------|------|-------------|
| Skill | `openspec init` | Initialize specs/ directory + standard templates |
| Skill | `skill-creator` | (Optional) Create project-level custom skills |
| MCP | Serena | Project onboarding, codebase indexing |
| MCP | TypeScript LSP | Language intelligence (if TypeScript) |
| Hook | post-init | Verify specs/, .claude/, .githooks/ exist |
| Hook | post-init | Confirm `git config core.hooksPath .githooks` |
| Gate | Directory Structure | All three directories must exist |
| Gate | Hook Activation | hooksPath must point to .githooks |

---

### Phase 1: Discover

**Trigger:** `/discover [idea]` or describe requirement in conversation

**Goal:** Turn vague ideas into reviewable PRD spec

```
    ┌─────────┐      ┌──────────────┐      ┌──────────────┐
    │ Idea    │─────▶│ brainstorming │─────▶│  PRD spec    │
    │ Input   │      │ exploration  │      │ → specs/     │
    └─────────┘      └──────────────┘      └──────────────┘
                         │                      │
                         ▼                      ▼
                Clarify intent        Reviewable, verifiable
                Explore approaches    spec document
```

**Steps:**

| Step | Action | Output |
|------|--------|--------|
| 1 | Input idea, activate `brainstorming` | Clarify intent → constraints → success criteria |
| 2 | brainstorming proposes 2-3 approaches, user selects | Direction confirmed |
| 3 | Output structured PRD draft, user confirms | Content locked |
| 4 | `openspec validate` format check | Schema compliant |
| 5 | Write `specs/prd/<change-id>.md` | Change enters `proposed` status |
| 6 | (Optional) `design-brief-builder` | Bridge to design phase |

**Capabilities:**

| Type | Name | Description |
|------|------|-------------|
| Skill | `brainstorming` | Structured dialogue: intent, constraints, success criteria, approaches |
| Skill | `design-brief-builder` | (Optional) Generate design brief |
| Skill | `openspec validate` | PRD spec format validation |
| MCP | Figma | (Optional) Design inspiration / competitor reference |
| Hook | pre-spec-commit | OpenSpec schema check (required fields, format) |
| Hook | pre-spec-commit | Duplicate spec detection (unique change-id) |
| Gate | PRD Completeness | Background, user stories, acceptance criteria, boundaries, NFRs all required |
| Gate | Testability | Acceptance criteria must be quantifiable / automatable |
| Output | `specs/prd/<change-id>.md` | Change enters `proposed` status |

---

### Phase 2: Plan

**Trigger:** Phase 1 PRD spec confirmed, auto or manual entry

**Goal:** Decompose PRD spec into executable, verifiable tasks; parallel produce API/Design/Test specs

```
    ┌──────────┐      ┌──────────────┐      ┌──────────────┐
    │ PRD spec │─────▶│ writing-plans │─────▶│  Task list   │
    │ Input    │      │ decompose     │      │ + dep DAG    │
    └──────────┘      └──────────────┘      └──────────────┘
                                                  │
                    ┌─────────────────────────────┤
                    │                             │
                    ▼                             ▼
             ┌──────────────┐            ┌──────────────┐
             │ Parallel spec│            │ User confirm  │
             │ api/design/  │            │ plan + spec   │
             │ test         │            │              │
             └──────────────┘            └──────────────┘
                    │                             │
                    ▼                             ▼
                                             Gate checks:
                                             · Task granularity
                                             · No cyclic deps
                                             · Spec alignment
                                                  │
                                                  ▼
                                            → Phase 3
```

**Steps:**

| Step | Action | Output |
|------|--------|--------|
| 1 | Read `specs/prd/<change-id>.md` | Full requirement understanding |
| 2 | Serena MCP analyze codebase | Impact scope identified |
| 3 | `writing-plans` decompose into tasks | Task list: single responsibility, independently verifiable, clear dependencies |
| 4 | Parallel: `api-contract-first` | `specs/api/<change-id>.yaml` |
| 5 | Parallel: `frontend-design` + Figma | `specs/design/<change-id>.md` |
| 6 | Parallel: test strategy | `specs/test/<change-id>.md` |
| 7 | User confirms plan + parallel specs | Content locked |
| 8 | `openspec validate` | Plan aligned with PRD spec |
| 9 | Write `specs/plan/<change-id>.md` | Change enters `planned` status |

**Capabilities:**

| Type | Name | Description |
|------|------|-------------|
| Skill | `writing-plans` | PRD → executable task list, each independently verifiable |
| Skill | `api-contract-first` | (Parallel) API contract first, output OpenAPI spec |
| Skill | `frontend-design` | (Parallel) Design spec: component tree, interactions, responsive |
| Skill | `openspec validate` | Plan ↔ PRD alignment check |
| MCP | Serena | Analyze codebase, determine impact scope |
| MCP | TypeScript LSP | Understand existing interfaces, type definitions |
| MCP | Figma | Design spec resource lookup |
| Hook | pre-plan-commit | Task executability check (each task has clear verification) |
| Hook | pre-plan-commit | Dependency legality (no cyclic dependencies) |
| Hook | pre-plan-commit | Scope check (plan tasks within PRD scope) |
| Gate | Task Granularity | Single task ≤ 1 file or 1 clear responsibility |
| Gate | No Cyclic Deps | Dependency graph must be DAG |
| Gate | Spec Alignment | Each task maps to a PRD acceptance criterion |
| Output | `specs/plan/<change-id>.md` + parallel spec family | Change enters `planned` status |

---

### Phase 3: Execute (TDD)

**Trigger:** Phase 2 plan + spec family confirmed, auto entry

**Goal:** Implement tasks in topological order, TDD discipline enforced, full hook coverage

```
    ┌──────────┐      ┌──────────────┐      ┌──────────────┐
    │ plan +   │─────▶│ executing-    │─────▶│ Per-task TDD │
    │ specs    │      │ plans driver  │      │ loop         │
    └──────────┘      └──────────────┘      └──────────────┘
                                                  │
                    ┌─────────────────────────────┤
                    │                             │
                    ▼                             ▼
             ┌──────────────┐            ┌──────────────┐
             │ Single task   │            │ L2+ parallel  │
             │ TDD loop      │            │ subagent mode │
             └──────────────┘            │ multi-task    │
                    │                    └──────────────┘
                    ▼
      ┌─────────────────────────────────────────┐
      │ TDD Iron Rule (unskippable):             │
      │                                          │
      │  Read task → Write test → Run test       │
      │                  │           │           │
      │                  │    ┌──────┴──────┐    │
      │                  │    │ Test fails?  │    │
      │                  │    ├──────┬──────┤    │
      │                  │    │ YES  │ NO   │    │
      │                  │    │ Proceed│Rewrite│  │
      │                  │    └───┬───┘ test  │    │
      │                  │        ▼           │    │
      │                  │  Write minimal     │    │
      │                  │  implementation    │    │
      │                  │        │           │    │
      │                  │        ▼           │    │
      │                  │  Test passes?      │    │
      │                  │  │YES   │NO        │    │
      │                  │  ▼      ▼          │    │
      │                  │ Refactor  Fix      │    │
      │                  │  │                 │    │
      │                  │  ▼                 │    │
      │                  │ openspec diff      │    │
      │                  │  │                 │    │
      │                  │  ▼                 │    │
      │                  │ git commit         │    │
      │                  └────────────────────┘    │
      └─────────────────────────────────────────┘
                    │
                    ▼
            All tasks done → Phase 4
```

**L2+ Parallel Mode Trigger:**

```
    User selected L2+ in Phase 0 /onboard
                  │
                  ▼
    executing-plans reads plan dependency DAG
                  │
                  ▼
    ≥ 2 tasks in "ready" state (all deps satisfied)
                  │
    ┌───── Both conditions met? ─────┐
    │                                │
    ▼ YES                            ▼ NO
┌──────────────┐              ┌──────────────┐
│ subagent     │              │ Sequential   │
│ parallel     │              │ per-task TDD │
└──────────────┘              └──────────────┘
```

**Steps:**

| Step | Action | Output |
|------|--------|--------|
| 1 | `executing-plans` reads plan, orders by DAG topology | Execution queue |
| 2 | Take next ready task | — |
| 3 | Write test (BEFORE implementation) | Test file |
| 4 | Run test → MUST FAIL | Red (correct) / Pass (test wrong, go back to step 3) |
| 5 | Write minimal implementation | Source file |
| 6 | Run test → must pass | Green |
| 7 | Refactor (Serena check references) | Clean code |
| 8 | `openspec diff` check spec drift | No drift / fix drift |
| 9 | `git commit` (triggers pre-commit + commit-msg hooks) | Commit record |
| 10 | Mark task complete, back to step 2 | — |
| 11 | All tasks done | → Phase 4 |

**All triggers automatic:**

| Trigger | Mechanism | Condition |
|---------|-----------|-----------|
| Enter Phase 3 | `executing-plans` auto-activates | Phase 2 complete |
| Parallel mode | `subagent-driven-development` auto-activates | Level ≥ L2 + ≥ 2 ready tasks |
| Sequential mode | Auto fallback per-task TDD | Level = L0/L1 or ready tasks < 2 |
| pre-commit | git commit auto-triggers | git native |
| commit-msg | git commit auto-triggers | git native |
| Spec drift check | File write auto-triggers | hook listener |
| File scope check | File write auto-triggers | hook listener |
| Permission check | AI operation auto-triggers | Claude Code native |
| pre-push | git push auto-triggers | git native |

**Capabilities:**

| Type | Name | Description |
|------|------|-------------|
| Skill | `executing-plans` | Drive tasks in topological order, manage task status |
| Skill | `TDD` | Iron rule: test first → must fail → minimal impl → pass → refactor |
| Skill | `subagent-driven-development` | (L2+) Multi-task parallel, independent agents + worktrees |
| Skill | `dispatching-parallel-agents` | (L2+) Concurrent independent task dispatch |
| Skill | `openspec diff` | Post-write spec drift detection |
| MCP | TypeScript LSP | Real-time type checking, completions |
| MCP | Serena | Reference lookup, symbol relations, refactor safety |
| MCP | Playwright | (Frontend) Interaction verification, screenshot comparison |
| MCP | Figma | Design spec reference |
| Hook | `pre-commit` | format → lint → type-check → gitleaks → TDD Gate |
| Hook | `commit-msg` | Conventional commit format |
| Hook | Post-write | Spec drift (openspec diff), alert/block on threshold |
| Hook | Post-write | File scope (changes within plan scope) |
| Hook | Post-write | Permission boundary check |
| Hook | `pre-push` | Full unit tests + coverage threshold |
| Gate | TDD Gate | Test written before impl; test must fail once first |
| Gate | File Scope Gate | Changes exceed plan scope → block |
| Gate | Spec Drift Gate | Drift → warning; drift > threshold → blocking |
| Gate | Coverage Gate | Coverage below threshold → block |
| Output | Implementation + tests | Per task: test file + source + completion marker |

---

### Phase 4: Verify

**Trigger:** Phase 3 all tasks complete, auto entry

**Goal:** Full-chain verification, spec ↔ code consistency, evidence before assertions

```
    ┌──────────┐      ┌──────────────┐      ┌──────────────┐
    │ Impl done│─────▶│ verification- │─────▶│  Seven-step  │
    │ Input    │      │ before-       │      │  verification│
    │          │      │ completion   │      │              │
    └──────────┘      └──────────────┘      └──────────────┘
                                                  │
    ┌─────────────────────────────────────────────┤
    │                                             │
    ▼                                             ▼
┌──────────────┐                          Each step must produce
│ Step 1: Contract │                      reviewable output.
│ oasdiff breaking │                      Verbal claims = invalid.
│ change check     │
└────────┬────────┘
         ▼
┌──────────────┐
│ Step 2: Security│
│ semgrep + SCA   │
└────────┬────────┘
         ▼
┌──────────────┐
│ Step 3: E2E     │
│ Smoke test      │
│ (Playwright)    │
└────────┬────────┘
         ▼
┌──────────────┐
│ Step 4: Visual   │
│ regression       │
│ screenshot vs    │
│ Figma spec       │
└────────┬────────┘
         ▼
┌──────────────┐
│ Step 5: Full     │
│ diagnostics      │
│ TS LSP → 0 errors│
└────────┬────────┘
         ▼
┌──────────────┐
│ Step 6: Code     │
│ Review vs spec   │
│ Gaps/redundancy/ │
│ drift            │
└────────┬────────┘
         ▼
┌──────────────┐
│ Step 7: openspec │
│ validate final   │
│ consistency      │
└────────┬────────┘
         │
         ▼
┌─────────────────────┐
│ Gate summary:        │
│ Contract · Security · Smoke · Coverage · Diagnostics · Spec │
└────────┬────────────┘
         │
         ▼
  Write verification report → Phase 5
```

**Steps:**

| Step | Action | Output |
|------|--------|--------|
| 1 | `verification-before-completion` activates | "Evidence first" mode locked |
| 2 | oasdiff breaking change detection | Contract Gate pass/fail |
| 3 | semgrep + SCA three-layer security scan | Security Gate pass/fail |
| 4 | Playwright E2E smoke test | Smoke Gate pass/fail |
| 5 | Playwright screenshot vs Figma design spec | Visual regression report |
| 6 | TS LSP `get_all_diagnostics` → zero errors | Diagnostics Gate pass/fail |
| 7 | `code-review` vs spec: gaps, redundancy, drift | Review findings |
| 8 | `openspec validate` final spec ↔ code consistency | Consistency report |
| 9 | Aggregate all gates + generate verification report | `specs/release/<change-id>.md` |

**All triggers automatic:**

| Trigger | Mechanism | Condition |
|---------|-----------|-----------|
| Enter Phase 4 | `verification-before-completion` auto-activates | Phase 3 complete |
| oasdiff | `pre-push` hook auto | git push |
| Security scan | `pre-push` hook auto | git push |
| E2E smoke | Auto-run Playwright | Enter Phase 4 |
| Visual compare | Playwright screenshot auto | Frontend project |
| Full diagnostics | TS LSP auto | TypeScript project |
| code-review | `code-review` skill auto | Prior steps complete |
| openspec validate | Auto trigger | code-review complete |
| Metrics collection | Hook auto | verify complete |

**Capabilities:**

| Type | Name | Description |
|------|------|-------------|
| Skill | `verification-before-completion` | Evidence before assertion: run all verify commands, confirm output |
| Skill | `code-review` | Spec review: gaps, redundancy, design drift |
| Skill | `openspec validate` | Final spec ↔ code consistency |
| MCP | Playwright | E2E smoke test + screenshot vs design spec |
| MCP | Serena | Full reference check: no dead code, no breaking ref changes |
| MCP | TypeScript LSP | `get_all_diagnostics` project-wide |
| Hook | `pre-push` | Full tests + coverage + semgrep + SCA + oasdiff |
| Hook | Post-verify | Quality metrics (M1-M5), alert below threshold |
| Hook | Post-verify | Visual regression archive |
| Hook | Post-verify | Auto-generate verification report |
| Gate | Contract Gate | oasdiff breaking change → block |
| Gate | Security Gate | semgrep + SCA, fail any → block |
| Gate | Smoke Test Gate | E2E critical path fail → block |
| Gate | Coverage Gate | Below threshold → block |
| Gate | Full Diagnostics Gate | TS LSP errors > 0 → block |
| Output | `specs/release/<change-id>.md` | Verification report + quality metrics; change → `verified` |

---

### Phase 5: Release

**Trigger:** Phase 4 verification passed, auto entry

**Goal:** Safe merge to main + knowledge archival

```
    ┌──────────┐      ┌──────────────┐      ┌──────────────┐
    │Verified  │─────▶│ finishing-a-  │─────▶│  Merge       │
    │Input     │      │ development-  │      │  strategy    │
    │          │      │ branch        │      │  decision    │
    └──────────┘      └──────────────┘      └──────────────┘
                                                  │
                    ┌─────────────────────────────┤
                    │                             │
                    ▼                             ▼
             ┌──────────────┐            ┌──────────────┐
             │ release-      │            │ pre-merge     │
             │ builder       │            │ final defense │
             └──────────────┘            └──────────────┘
                    │                             │
                    ▼                             ▼
             · semver version              · All-Gates-Pass
             · changelog                  · Destructive Op
             · release note                     │
                    │                             │
                    └─────────────┬───────────────┘
                                  │
                                  ▼
                           ┌──────────┐
                           │  merge   │
                           │ → main   │
                           └──────────┘
                                  │
                    ┌─────────────┼─────────────┐
                    │                           │
                    ▼                           ▼
             ┌──────────────┐            ┌──────────────┐
             │ openspec      │            │ Feedback Loop │
             │ archive       │            │ Capture fixes │
             └──────────────┘            └──────────────┘
                    │                           │
                    ▼                           ▼
             archive/                     lint rule +
             <change-id>/                 spec template
             full history                 optimization
```

**Steps:**

| Step | Action | Output |
|------|--------|--------|
| 1 | `finishing-a-development-branch` activates, reads all gate status | Merge decision: merge/squash/rebase |
| 2 | `release-builder` analyzes commits (feat/fix/refactor) | Changelog |
| 3 | `release-builder` semver decision (major/minor/patch) | Version number |
| 4 | `release-builder` generates release note | Release notes |
| 5 | pre-merge final defense: all gates + destructive op check | Pass / Block |
| 6 | merge → main | Code merged |
| 7 | `openspec archive` auto-archives | `archive/<change-id>/` |
| 8 | Feedback Loop: capture manual fixes → rules | lint rule / spec template update |

**All triggers automatic:**

| Trigger | Mechanism | Condition |
|---------|-----------|-----------|
| Enter Phase 5 | `finishing-a-development-branch` auto-activates | Phase 4 complete |
| release-builder | Auto-activates | finishing-branch complete |
| pre-merge gate | git merge auto-triggers | merge operation |
| archive | post-merge hook auto | merge success |
| Feedback Loop | post-merge hook auto | L3 level + manual fixes detected |

**Capabilities:**

| Type | Name | Description |
|------|------|-------------|
| Skill | `finishing-a-development-branch` | Merge strategy + execute merge or create PR |
| Skill | `release-builder` | Semver + changelog + release note generation |
| Skill | `openspec archive` | Full change archival to `archive/<change-id>/` |
| MCP | (None) | — |
| Hook | `pre-merge` | All gates passed summary; block if any failed |
| Hook | `pre-merge` | Destructive operation intercept (`rm -rf`, `force push`, `reset --hard`) |
| Hook | post-merge | spec → archive auto-archival |
| Hook | post-merge | Feedback Loop: manual fixes → lint rule / spec template |
| Gate | All-Gates-Pass | Iterate all Phase 0-5 gates, all must pass |
| Gate | Destructive Op | Dangerous command match → block + human confirm |
| Gate | Archive Gate | Archive completeness (specs + report + release note) |
| Output | Merged to main + `archive/<change-id>/` | Traceable full change history |

---

## 4. Hook System

### 4.1 Three-Layer Hook Model

| Layer | Content | Maturity |
|-------|---------|----------|
| **L1: Code Hygiene** | pre-commit → lint/format/secret-scan/type-check; commit-msg; pre-push → test/security-scan/oasdiff | Mature, ready to use |
| **L2: AI Safety** | Spec Drift Detection, Diff Review, Permission Boundary, TDD Gate | Maturing fast |
| **L3: Intelligence Evolution** | Frequency-driven rule upgrade, Feedback Loop, Post-mortem archive | Cutting edge, needs data |

### 4.2 Hook Inventory by Phase

**Phase 0 (Init):**

| Hook | Tool | Layer |
|------|------|-------|
| Post-init: verify directory structure | Shell script | L1 |
| Post-init: confirm hooksPath | Shell script | L1 |

**Phase 1 (Discover):**

| Hook | Tool | Layer |
|------|------|-------|
| Pre-spec-commit: OpenSpec schema check | OpenSpec CLI | L2 |
| Pre-spec-commit: duplicate spec detection | Script | L3 |

**Phase 2 (Plan):**

| Hook | Tool | Layer |
|------|------|-------|
| Pre-plan-commit: task executability | Script | L2 |
| Pre-plan-commit: no cyclic deps | Script | L1 |
| Pre-plan-commit: scope check | Script | L2 |

**Phase 3 (Execute):**

| Hook | Tool | Layer |
|------|------|-------|
| pre-commit: format | Prettier/Black | L1 |
| pre-commit: lint | ESLint/Ruff | L1 |
| pre-commit: type-check | tsc/mypy | L1 |
| pre-commit: secret scan | gitleaks | L1 |
| pre-commit: TDD Gate | git diff order | L2 |
| commit-msg: format | commitlint | L1 |
| Post-write: spec drift check | openspec diff | L2 |
| Post-write: file scope check | Script | L2 |
| Post-write: permission boundary | Claude Code | L2 |
| pre-push: unit tests + coverage | Test runner | L1 |

**Phase 4 (Verify):**

| Hook | Tool | Layer |
|------|------|-------|
| pre-push: oasdiff | oasdiff CLI | L1 |
| pre-push: security scan | semgrep + SCA | L1 |
| Post-verify: quality metrics | Custom | L3 |
| Post-verify: visual regression archive | Playwright | L2 |
| Post-verify: verification report | Auto-gen | L2 |

**Phase 5 (Release):**

| Hook | Tool | Layer |
|------|------|-------|
| pre-merge: all gates summary | Gate adapter | L1 |
| pre-merge: destructive op intercept | Pattern match | L1 |
| post-merge: auto archive | openspec archive | L2 |
| post-merge: Feedback Loop | Capture + rules | L3 |

**Global (All Phases):**

| Hook | Tool | Layer |
|------|------|-------|
| AI write operations: Diff Review | Claude Code | L2 |
| CLI operations: Sandbox safety | Claude Code | L2 |
| Periodic: hook hit frequency stats | Stats engine | L3 |

---

## 5. Skill Inventory

| Skill | Source | Phase | Description |
|-------|--------|-------|-------------|
| `openspec` | OpenSpec | 0,1,2,3,4,5 | init / validate / diff / archive |
| `brainstorming` | Superpowers | 1 | Structured idea exploration |
| `design-brief-builder` | Custom | 1 | Design brief generation |
| `writing-plans` | Superpowers | 2 | PRD → executable task list |
| `api-contract-first` | Community | 2 | API contract first (OpenAPI) |
| `frontend-design` | Community | 2 | Design spec (component tree, interactions) |
| `executing-plans` | Superpowers | 3 | Drive per-task execution |
| `TDD` | Superpowers | 3 | TDD iron rule enforcement |
| `subagent-driven-development` | Superpowers | 3 | Multi-agent parallel execution |
| `dispatching-parallel-agents` | Superpowers | 3 | Parallel task dispatch |
| `verification-before-completion` | Superpowers | 4 | Evidence before assertions |
| `code-review` | Superpowers | 4 | Spec-based code review |
| `finishing-a-development-branch` | Superpowers | 5 | Merge strategy + execution |
| `release-builder` | Custom | 5 | Semver + changelog + release note |
| `skill-creator` | Superpowers | 0 | (Optional) Create custom skills |

---

## 6. MCP Inventory

| MCP | Phase | Description |
|-----|-------|-------------|
| Serena | 0,2,3,4 | Codebase analysis, symbol search, refactoring safety |
| TypeScript LSP | 0,2,3,4 | Type checking, diagnostics, completions |
| Figma | 1,2,3,4 | Design spec reference, visual regression comparison |
| Playwright | 3,4 | E2E testing, smoke tests, screenshot capture |

---

## 7. Gate Inventory

| Gate | Phase | Layer | Description |
|------|-------|-------|-------------|
| Directory Structure | 0 | L1 | specs/, .claude/, .githooks/ must exist |
| Hook Activation | 0 | L1 | hooksPath → .githooks |
| PRD Completeness | 1 | L2 | 5 required fields non-empty |
| Testability | 1 | L2 | Acceptance criteria quantifiable |
| Task Granularity | 2 | L2 | Task ≤ 1 file / 1 responsibility |
| No Cyclic Deps | 2 | L1 | Task DAG must be valid |
| Spec Alignment | 2 | L2 | Each task maps to acceptance criterion |
| TDD Gate | 3 | L2 | Test first, test must fail once |
| File Scope Gate | 3 | L2 | Changes within plan scope |
| Spec Drift Gate | 3 | L2 | Drift > threshold → block |
| Coverage Gate | 3,4 | L1 | Coverage below threshold → block |
| Contract Gate | 4 | L1 | No breaking API changes |
| Security Gate | 4 | L1 | semgrep + SCA all pass |
| Smoke Test Gate | 4 | L1 | E2E critical path pass |
| Full Diagnostics Gate | 4 | L1 | Zero TS errors |
| All-Gates-Pass | 5 | L1 | All gates aggregated, all passed |
| Destructive Op Gate | 5 | L1 | Dangerous commands blocked |
| Archive Gate | 5 | L2 | Archive completeness check |

---

## 8. Transition Conditions

| From | To | Condition |
|------|----|-----------|
| Phase 0 | Phase 1 | All Phase 0 gates pass; /onboard complete |
| Phase 1 | Phase 2 | PRD spec committed; PRD Completeness + Testability gates pass |
| Phase 2 | Phase 3 | Plan + specs committed; Task Granularity + No Cyclic Deps + Spec Alignment gates pass |
| Phase 3 | Phase 4 | All tasks marked complete; TDD + File Scope + Spec Drift + Coverage gates pass |
| Phase 4 | Phase 5 | All verify steps complete; Contract + Security + Smoke + Coverage + Diagnostics gates pass |
| Phase 5 | Done | Merge to main; All-Gates-Pass + Destructive Op + Archive gates pass |

---

## 9. Phase Outputs Summary

| Phase | Output | Path |
|-------|--------|------|
| **0** | Spec directory structure + .claude/ + .githooks/ + CI workflows | Project root |
| **1** | PRD spec | `specs/prd/<change-id>.md` |
| **2** | Plan (task list + dependency DAG) | `specs/plan/<change-id>.md` |
| **2** | API contract spec | `specs/api/<change-id>.yaml` |
| **2** | Design spec | `specs/design/<change-id>.md` |
| **2** | Test strategy spec | `specs/test/<change-id>.md` |
| **3** | Test files + source code + task completion markers | Project source tree |
| **4** | Verification report + quality metrics | `specs/release/<change-id>.md` |
| **5** | Release note + full archive | `archive/<change-id>/` (all specs + report + release note) |

---

## 10. Quick Index Mechanism

### 10.1 Three-Layer Index Architecture

```
CLAUDE.md（Entry Index, < 150 lines）
  │
  ├── → WORKFLOW.md（Process Manual: full workflow + rules）
  │     └── → Each phase's spec template location
  │
  ├── → specs/（Active changes）
  │     └── <change-id>/ spec family per change
  │
  └── → archive/（Historical archive, indexed by date + change-id）
```

### 10.2 CLAUDE.md Index Example

```markdown
## Active Changes
- [change-id-001] specs/prd/login-feature.md → planned
- [change-id-002] specs/prd/payment-flow.md → proposed

## Quick Links
- Workflow: .claude/WORKFLOW.md
- Active specs: specs/
- Archive: archive/
- Hooks: .githooks/

## Current Level: L2
```

### 10.3 Loading Strategy

Claude Code loads only CLAUDE.md at startup (< 150 lines index), then drills into WORKFLOW.md or specific spec files on demand. This implements progressive context loading — no full spec content loaded until needed.

---

## 11. CLAUDE.md Specification

### 11.1 Constraints

| Constraint | Requirement |
|------------|-------------|
| **Length** | < 150 lines, keep it lean |
| **Responsibility** | Index + current state only, no process details |
| **Excludes** | No spec content, no full workflow steps, no hook scripts |
| **Must Include** | Enabled level (L0-L3), active change list with status, key directory pointers |

### 11.2 File Division of Labor

| File | Purpose | Maintainer | Update Frequency |
|------|---------|------------|-----------------|
| **CLAUDE.md** | Entry index — "where to find it" | Auto + manual | On each change status update |
| **WORKFLOW.md** | Process handbook — "how to do it" | Manual | On process changes |
| **specs/** | Active spec content — "what to build" | Per phase | As phases progress |
| **archive/** | History — "what was built" | Auto-archival | Auto on merge |

### 11.3 CLAUDE.md Template

```markdown
# Project: <project-name>

## Level
Current: L<0-3>

## Active Changes
| Change ID | PRD | Phase | Status |
|-----------|-----|-------|--------|
| <id> | <path> | <N> | <proposed/planned/executing/verified> |

## Directory Map
- Process: .claude/WORKFLOW.md
- Active specs: specs/
- History: archive/
- Quality gates: .githooks/ + .github/workflows/

## Project-Specific Customizations
- Language: <typescript/python/go/rust>
- Framework: <nextjs/fastapi/...>
- Custom skills: .claude/skills/
```

---

## 12. L0-L3 Capability Matrix

| Capability | L0 Hotfix | L1 Light | L2 Standard | L3 Full |
|-----------|-----------|----------|-------------|---------|
| openspec init/validate/diff/archive | — | validate only | All | All |
| brainstorming | — | — | ✓ | ✓ |
| writing-plans | — | — | ✓ | ✓ |
| api-contract-first | — | Optional | ✓ | ✓ |
| frontend-design | — | Optional | ✓ | ✓ |
| TDD | — | Manual | Automatic | Automatic |
| subagent parallel | — | — | ✓ | ✓ |
| code-review | — | — | ✓ | ✓ |
| verification-before-completion | — | — | ✓ | ✓ |
| release-builder | — | — | ✓ | ✓ |
| L1 hooks | — | pre-commit only | All L1 | All L1 |
| L2 hooks | — | — | All L2 | All L2 |
| L3 hooks | — | — | — | All L3 |
| Git worktree isolation | — | — | ✓ | ✓ |
| CI gates | — | — | ✓ | ✓ |
| Quality metrics (M1-M5) | — | — | — | ✓ |
| Feedback Loop | — | — | — | ✓ |
