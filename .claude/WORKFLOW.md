# AI Development Base — Workflow Handbook

## Overview

This project uses a five-phase development lifecycle driven by OpenSpec + Superpowers + Claude Code. Each phase has automated gates; transition is blocked until all gates pass.

---

## Phase 0: Initialization (one-time)

**Goal:** Set up the project for AI-assisted development

**Steps:**
1. `openspec init` — creates `specs/` with standard templates
2. Deploy `.claude/` config — WORKFLOW.md, settings.json, commands/, skills/
3. Deploy `.githooks/` — pre-commit, commit-msg, pre-push
4. `git config core.hooksPath .githooks` — activate hooks
5. `/onboard` — select role + level (L0-L3)

**Gates:** Directory Structure Gate, Hook Activation Gate

**Capabilities:**
| Type | Name | Description |
|------|------|-------------|
| Skill | openspec init | Initialize specs/ directory + standard templates |
| Skill | skill-creator | (Optional) Create project-level custom skills |
| MCP | Serena | Project onboarding, codebase indexing |
| MCP | TypeScript LSP | Language intelligence (if TypeScript) |
| Hook | post-init | Verify specs/, .claude/, .githooks/ exist |
| Hook | post-init | Confirm `git config core.hooksPath .githooks` |
| Gate | Directory Structure | All three directories must exist |
| Gate | Hook Activation | hooksPath must point to .githooks |

---

## Phase 1: Discover

**Trigger:** `/discover [idea]` or describe a requirement in conversation

**Goal:** Turn vague ideas into reviewable PRD spec

**Flow:**
1. `brainstorming` skill activates — clarifies intent, constraints, success criteria
2. Proposes 2-3 approaches with trade-offs; user selects one
3. Outputs structured PRD draft for user confirmation
4. `openspec validate` checks PRD format completeness
5. Writes `specs/prd/<change-id>.md` — change enters `proposed` status
6. (Optional) `design-brief-builder` generates design brief for design phase

**Output:** `specs/prd/<change-id>.md`

**Required PRD Fields:**
- Background & Motivation — why, what problem
- User Stories — As a [role], I want [goal], so that [reason]
- Acceptance Criteria — quantifiable, testable
- Boundaries & Constraints — in scope / out of scope
- Non-Functional Requirements — performance, security, accessibility

**Gates:** PRD Completeness Gate, Testability Gate

**Capabilities:**
| Type | Name | Description |
|------|------|-------------|
| Skill | brainstorming | Structured requirement exploration |
| Skill | design-brief-builder | (Optional) Design brief for design phase |
| Skill | openspec validate | PRD format completeness check |
| MCP | Figma | (Optional) Design inspiration lookup |
| Hook | pre-spec-commit | Schema check + duplicate detection |

---

## Phase 2: Plan

**Trigger:** Phase 1 PRD spec confirmed (auto or manual)

**Goal:** Decompose PRD spec into executable, verifiable tasks; parallel produce API/Design/Test specs

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
- `specs/design/<change-id>.md` — design spec (component tree, interaction states, responsive)
- `specs/test/<change-id>.md` — test strategy (scope, critical paths, boundary cases)

**Gates:** Task Granularity Gate, No Cyclic Deps Gate, Spec Alignment Gate

**Capabilities:**
| Type | Name | Description |
|------|------|-------------|
| Skill | writing-plans | PRD → executable task list |
| Skill | api-contract-first | API contract first (OpenAPI spec) |
| Skill | frontend-design | Design spec: component tree, interactions, responsive |
| Skill | openspec validate | Plan ↔ PRD alignment |
| MCP | Serena | Codebase impact analysis |
| MCP | TypeScript LSP | Interface/type understanding |
| MCP | Figma | Design resource lookup |

---

## Phase 3: Execute (TDD)

**Trigger:** Phase 2 plan + all specs confirmed (auto)

**Iron Rule: TDD — test first, always. Test MUST fail before implementation.**
If implementation is written before a failing test, delete it and restart.

**Flow:**
1. `executing-plans` reads plan DAG, orders tasks topologically
2. For each ready task:
   a. Write test file → run → **MUST FAIL** (red)
   b. Write minimal implementation → run → **MUST PASS** (green)
   c. Refactor (Serena checks references for safety)
   d. `openspec diff` — check for spec drift
   e. `git commit` (triggers pre-commit + commit-msg hooks)
3. Repeat until all tasks complete

**L2+ Parallel Mode:**
When level ≥ L2 and ≥ 2 tasks have all dependencies satisfied:
- `subagent-driven-development` auto-activates
- Each ready task gets an independent agent + isolated git worktree
- Agents run concurrently

**Gates:** TDD Gate, File Scope Gate, Spec Drift Gate, Coverage Gate

**Hooks active during this phase:**
- `pre-commit`: format → lint → type-check → gitleaks → TDD Gate
- `commit-msg`: conventional commit format
- Post-write: spec drift check + file scope check + permission boundary
- `pre-push`: unit tests + coverage threshold

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

---

## Phase 4: Verify

**Trigger:** Phase 3 all tasks complete (auto)

**Rule:** Evidence before assertions. Verbal "it's done" claims are invalid. Every step must produce reviewable output.

**Seven-Step Verification:**
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

---

## Quick Reference

### Transition Conditions

| From | To | Condition |
|------|----|-----------|
| Phase 0 | Phase 1 | All Phase 0 gates pass; /onboard complete |
| Phase 1 | Phase 2 | PRD spec committed; PRD Completeness + Testability gates pass |
| Phase 2 | Phase 3 | Plan + specs committed; Task Granularity + No Cyclic Deps + Spec Alignment gates pass |
| Phase 3 | Phase 4 | All tasks marked complete; TDD + File Scope + Spec Drift + Coverage gates pass |
| Phase 4 | Phase 5 | All verify steps complete; Contract + Security + Smoke + Coverage + Diagnostics gates pass |
| Phase 5 | Done | Merge to main; All-Gates-Pass + Destructive Op + Archive gates pass |

### Level Capability Matrix

| Capability | L0 Hotfix | L1 Light | L2 Standard | L3 Full |
|-----------|-----------|----------|-------------|---------|
| openspec init/validate/diff/archive | — | validate only | All | All |
| brainstorming | — | — | Yes | Yes |
| writing-plans | — | — | Yes | Yes |
| api-contract-first | — | Optional | Yes | Yes |
| frontend-design | — | Optional | Yes | Yes |
| TDD | — | Manual | Automatic | Automatic |
| subagent parallel | — | — | Yes | Yes |
| code-review | — | — | Yes | Yes |
| verification-before-completion | — | — | Yes | Yes |
| release-builder | — | — | Yes | Yes |
| L1 hooks | — | pre-commit only | All L1 | All L1 |
| L2 hooks | — | — | All L2 | All L2 |
| L3 hooks | — | — | — | All L3 |
| Git worktree isolation | — | — | Yes | Yes |
| CI gates | — | — | Yes | Yes |
| Quality metrics (M1-M5) | — | — | — | Yes |
| Feedback Loop | — | — | — | Yes |

### Hook Layers

| Layer | Content | Tools |
|-------|---------|-------|
| L1: Code Hygiene | format, lint, type-check, secret scan, commit format, test, security, contract | Prettier, ESLint, tsc, gitleaks, commitlint, semgrep, oasdiff |
| L2: AI Safety | TDD gate, spec drift, file scope, permission boundary, diff review | openspec diff, Claude Code permissions |
| L3: Evolution | quality metrics, feedback loop, frequency-driven rules | Custom scripts |

### Skill Inventory

| Skill | Source | Phase | Description |
|-------|--------|-------|-------------|
| openspec | OpenSpec | 0-5 | init / validate / diff / archive |
| brainstorming | Superpowers | 1 | Structured idea exploration |
| design-brief-builder | Custom | 1 | Design brief generation |
| writing-plans | Superpowers | 2 | PRD → executable task list |
| api-contract-first | Community | 2 | API contract first (OpenAPI) |
| frontend-design | Community | 2 | Design spec (component tree, interactions) |
| executing-plans | Superpowers | 3 | Drive per-task execution |
| TDD | Superpowers | 3 | TDD iron rule enforcement |
| subagent-driven-development | Superpowers | 3 | Multi-agent parallel execution |
| dispatching-parallel-agents | Superpowers | 3 | Parallel task dispatch |
| verification-before-completion | Superpowers | 4 | Evidence before assertions |
| code-review | Superpowers | 4 | Spec-based code review |
| finishing-a-development-branch | Superpowers | 5 | Merge strategy + execution |
| release-builder | Custom | 5 | Semver + changelog + release note |
| skill-creator | Superpowers | 0 | (Optional) Create custom skills |

### MCP Inventory

| MCP | Phase | Description |
|-----|-------|-------------|
| Serena | 0,2,3,4 | Codebase analysis, symbol search, refactoring safety |
| TypeScript LSP | 0,2,3,4 | Type checking, diagnostics, completions |
| Figma | 1,2,3,4 | Design spec reference, visual regression comparison |
| Playwright | 3,4 | E2E testing, smoke tests, screenshot capture |

### Gate Inventory (18 gates)

| Gate | Phase | Layer |
|------|-------|-------|
| Directory Structure | 0 | L1 |
| Hook Activation | 0 | L1 |
| PRD Completeness | 1 | L2 |
| Testability | 1 | L2 |
| Task Granularity | 2 | L2 |
| No Cyclic Deps | 2 | L1 |
| Spec Alignment | 2 | L2 |
| TDD Gate | 3 | L2 |
| File Scope Gate | 3 | L2 |
| Spec Drift Gate | 3 | L2 |
| Coverage Gate | 3,4 | L1 |
| Contract Gate | 4 | L1 |
| Security Gate | 4 | L1 |
| Smoke Test Gate | 4 | L1 |
| Full Diagnostics Gate | 4 | L1 |
| All-Gates-Pass | 5 | L1 |
| Destructive Op Gate | 5 | L1 |
| Archive Gate | 5 | L2 |
