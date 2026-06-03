# AI Development Base — User Guide

> OpenSpec + Superpowers + Claude Code — AI-Native R&D Workflow Base

[中文指南](README.zh.md) | [语言切换](README.md)

---

## What Is This

The AI Development Base is a **standardized AI development infrastructure for product and engineering teams**. It fuses OpenSpec (spec standard + change management), Superpowers (process skeleton), and Claude Code (execution engine) into a complete R&D workflow covering the full lifecycle from requirements to delivery.

**Core philosophy**: Every feature change is an OpenSpec Change, passing through five phases — Discover → Plan → Execute → Verify → Release — with automated Gates at each phase. No skipping.

---

## Architecture Overview

```
Layer 1 — OpenSpec Core (Brain)
  Spec standard: PRD · API · Design · Test · Release
  Change lifecycle: propose → review → implement → verify → archive

Layer 2 — Superpowers Process Skeleton (Spine)
  Discover → Plan → Execute → Verify → Release

Layer 3 — Pluggable Capability Modules
  Skill / MCP / Hook / Gate

Layer 4 — Agent Execution Layer
  Parallel dispatch · Git Worktree isolation · Independent sessions
```

---

## Quick Start

### Prerequisites

The base depends on the following components. Some require prior installation:

| Component | Purpose | Required Level | Installation |
|-----------|---------|---------------|--------------|
| **Claude Code** | AI execution engine | All | `npm install -g @anthropic-ai/claude-code` |
| **OpenSpec CLI** | Spec management | L1+ | `npm install -g @fission-ai/openspec` |
| **Superpowers Plugin** | Process skills (brainstorming/writing-plans/TDD, etc.) | L1+ | In Claude Code: `/plugin install superpowers@claude-plugins-official` |
| **Figma Plugin** | Design file reading | L2+ | `/plugin install figma@claude-plugins-official` |
| **TypeScript LSP MCP** | TS type checking & diagnostics | L1+ | `npm install -g ts-language-mcp && claude mcp add --scope user typescript-lsp -- npx -y ts-language-mcp` |
| **Serena MCP** | Semantic codebase analysis | L1+ | `uv tool install -p 3.13 serena-agent@latest --prerelease=allow && serena setup claude-code` |
| **Playwright MCP** | E2E testing & browser automation | L2+ | `claude mcp add --scope user playwright -- npx @playwright/mcp@latest` |
| **Pencil MCP** | Prototyping (alternative) | L2+ (optional) | Install the Pencil extension in VS Code |
| **gitleaks** | Secret leak scanning | L3 | `brew install gitleaks` |
| **semgrep** | Static security analysis | L3 | `pip install semgrep` |
| **oasdiff** | API contract change detection | L2+ | `go install github.com/tufin/oasdiff/cmd/oasdiff@latest` |

> **Tip**: Not sure what you need? Just run `/onboard` — it will give you a targeted install checklist based on your role and level.

### Getting Started

**Option 1: New project**

Copy this repository into your project directory, then type in Claude Code:

```
/onboard
```

Interactive flow: choose language → role → project state → enablement level (L0-L3). The base auto-configures everything.

**Option 2: Existing project**

Copy these directories into your project root:

```bash
cp -r .claude/ .githooks/ .gitleaks.toml specs/ /path/to/your/project/
```

Then run `/onboard` in Claude Code from the project directory.

---

## Role-Based Entry Points

| Role | Primary Work | Entry Command | Phases |
|------|-------------|--------------|--------|
| **PM / Designer** | Define requirements, produce PRD spec | `/discover [idea]` | Phase 1 |
| **Developer** | Implement, TDD development | `/execute` | Phase 2-5 |
| **Full-stack Independent** | End-to-end ownership | `/onboard` → `/discover` | Phase 1-5 |
| **Maintenance / On-call** | Emergency fixes, diagnostics | `/hotfix` or `/diagnose` | L0-L1 |

---

## Enablement Levels (L0-L3)

| Level | For Whom | Capabilities |
|-------|----------|-------------|
| **L0 Hotfix** | Anyone | `/hotfix` + `/diagnose`, zero config, no Gates |
| **L1 Light** | Individual devs | Core skills (TDD, code-review, verification), pre-commit hooks, TS LSP + Serena |
| **L2 Standard** (recommended) | Product + dev teams | Full skill chain + 4 MCPs + CI gates + parallel agents |
| **L3 Full** | Enterprise | L2 plus: quality metrics M1-M5 + Feedback Loop for experience accumulation |

Re-run `/onboard` anytime to change your level.

---

## Five-Phase Lifecycle

```
Phase 0 ──▶ Phase 1 ──▶ Phase 2 ──▶ Phase 3 ──▶ Phase 4 ──▶ Phase 5
 (Init)     (Discover)   (Plan)     (Execute)   (Verify)   (Release)
    │           │           │           │           │           │
    ▼           ▼           ▼           ▼           ▼           ▼
 openspec    /discover   writing-    /execute   verification  /close-phase
 init        → PRD spec  plans       TDD loop   + 7-step     openspec
 deploy      .md         → plan      per-task   verify       archive
 config                  + parallel  implements  gate checks  → update
 activate                specs                                CLAUDE.md
 hooks
```

### Phase 0: Init

Run `/onboard`. Automatically executes `openspec init`, deploys `.claude/` config, activates `.githooks/`.

### Phase 1: Discover

Type `/discover [idea]`. brainstorming skill activates → outputs PRD spec → `specs/prd/<change-id>.md`.

**Gate:** PRD Completeness + Testability. Both must pass.

### Phase 2: Plan

Auto or manual entry. `writing-plans` reads PRD spec, decomposes into task DAG, parallel-produces API contract, design spec, test strategy.

**Gate:** Task Granularity + No Cyclic Deps + Spec Alignment.

### Phase 3: Execute

Run `/execute`. TDD iron rule per task: write test → RED → minimal impl → GREEN → refactor → `openspec diff` check drift → commit.

L2+: Ready tasks auto-parallelize (independent agents + isolated worktrees).

**Gate:** TDD Gate + File Scope Gate + Spec Drift Gate.

### Phase 4: Verify

Auto entry. Seven-step verification: Contract → Security → Smoke Test → Visual Regression → Full Diagnostics → Code Review → `openspec validate`.

**Gate:** All 5 gates must pass.

### Phase 5: Release

Run `/close-phase`. Pre-conditions verified → Migration Journal extraction → `openspec archive` → update CLAUDE.md → cleanup.

**Output:** `archive/<change-id>/` — complete traceable change history.

---

## Slash Commands Reference

| Command | Description | Level |
|---------|-------------|-------|
| `/discover [idea]` | Phase 1 entry, produce PRD spec | L2+ |
| `/execute` | Phase 3 entry, TDD implementation loop | L1+ |
| `/hotfix [problem]` | Emergency fix (≤3 files, no new API/DB changes) | L0+ |
| `/tweak [description]` | Small change shortcut (≤5 files, skips brainstorming, lightweight plan) | L0+ |
| `/diagnose` | Read-only health audit (10 checks) | L0+ |
| `/close-phase` | Phase 5 archival, knowledge extraction + openspec archive | L1+ |
| `/onboard` | Interactive setup, role + level routing | All |

---

## Skill Shortcut Reference

Beyond the 7 base slash commands, you can directly invoke Superpowers and OpenSpec skills via these shortcuts.

### Superpowers Skills

From the `superpowers` plugin. Format: `/superpowers:<skill-name>`

| Shortcut | Description | Phase |
|----------|-------------|-------|
| `/superpowers:brainstorming` | Structured requirement exploration — use before creating features, components, or modifying behavior | Phase 1 |
| `/superpowers:writing-plans` | PRD → executable task DAG, use before multi-step implementation | Phase 2 |
| `/superpowers:executing-plans` | Execute implementation plan in topological order in a separate session | Phase 3 |
| `/superpowers:test-driven-development` | TDD iron rule — use before implementing any feature or bugfix | Phase 3 |
| `/superpowers:subagent-driven-development` | Multi-agent parallel execution of independent tasks | Phase 3 |
| `/superpowers:dispatching-parallel-agents` | Parallel dispatch for 2+ independent tasks | Phase 3 |
| `/superpowers:using-git-worktrees` | Create isolated Git Worktree workspaces | Phase 3 |
| `/superpowers:systematic-debugging` | Systematic debugging — use when encountering any bug or test failure | Phase 3-4 |
| `/superpowers:verification-before-completion` | Evidence-first — verify before claiming work is complete | Phase 4 |
| `/superpowers:requesting-code-review` | Request code review after completing major features, before merge | Phase 4 |
| `/superpowers:receiving-code-review` | Rigorously evaluate code review feedback before implementing | Phase 4 |
| `/superpowers:finishing-a-development-branch` | Merge strategy decision (merge/squash/rebase) + integration | Phase 5 |
| `/superpowers:writing-skills` | Create, edit, or verify custom Skills | Phase 0 |
| `/superpowers:using-superpowers` | Session startup — establishes skill discovery and usage rules | — |

### OpenSpec Skills

Project-level skill, defined in `.claude/skills/openspec.md`. Format: `/openspec:<operation>`

| Shortcut | Description | Phase |
|----------|-------------|-------|
| `/openspec:init` | Initialize `specs/` directory structure with standard templates | Phase 0 |
| `/openspec:validate` | Validate spec file format completeness and schema compliance | Phase 1-4 |
| `/openspec:diff` | Detect drift between implementation code and spec (LOW/MEDIUM/HIGH) | Phase 3 |
| `/openspec:archive` | Archive completed change to `archive/<change-id>/` | Phase 5 |

> **Tip**: These skills can also be auto-activated by Claude when context matches. Manual invocation is useful when you want to force a specific workflow.

---

## Hook System

| Layer | Content | Tools | Maturity |
|-------|---------|-------|----------|
| **L1 Code Hygiene** | format · lint · type-check · secret scan · test · security · contract | Prettier/ESLint/tsc/gitleaks/semgrep/oasdiff | Mature |
| **L2 AI Safety** | TDD gate · spec drift · file scope · permission boundary | openspec diff / Claude Code native | Maturing fast |
| **L3 Intelligence Evolution** | Quality metrics · Feedback Loop · frequency-driven rule upgrade | Custom | Cutting edge |

---

## File Inventory

### Core Base Files

| File/Dir | Type | Description |
|----------|------|-------------|
| `.claude/WORKFLOW.md` | Process handbook | Complete five-phase process docs, Gate inventory, Skill/MCP mappings |
| `.claude/settings.json` | Config | Permission declarations, L0-L3 level definitions, phase→skill→gate mappings |
| `.claude/skills/openspec.md` | Skill definition | OpenSpec operations skill (init/validate/diff/archive) |
| `.claude/commands/` | Command definitions | 6 slash commands (discover/execute/hotfix/diagnose/close-phase/onboard) |
| `.claude/reference/` | Reference docs | On-demand reading: spec-drift-guide + 6 test-strategies |
| `.githooks/` | Git hooks | pre-commit / commit-msg / pre-push + shared script libraries |
| `.githooks/lib/gates.sh` | Gate engine | 17 quality Gate functions + run_phase_gates dispatcher |
| `.githooks/lib/l2-checks.sh` | AI safety layer | spec drift / file scope / permission / destructive op detection |
| `.gitleaks.toml` | Security config | Secret scanning rules and allowlists |
| `specs/` | Spec templates | OpenSpec templates for PRD / API / Plan / Design / Test / Release |

### Non-Base Files (Reference Only)

| File/Dir | Type | Description |
|----------|------|-------------|
| `README.md` | Documentation | Language switch entry point (CN/EN) |
| `README.zh.md` | Documentation | Chinese user guide (this file's Chinese counterpart) |
| `README.en.md` | Documentation | English user guide (this file) |
| `docs/superpowers/specs/` | Design docs | Design specification for this base (archival reference) |
| `docs/superpowers/plans/` | Implementation plans | Implementation plan for this base (archival reference) |
| `archive/` | History archive | Complete records of finished changes, auto-written by `/close-phase` |
| `.gitignore` | Git config | Ignore rules |

---

## FAQ

**Q: I already have a project. Will integrating the base affect my existing code?**
No. Integration only adds `.claude/`, `.githooks/`, `specs/` directories. It does not modify any of your source code.

**Q: Can I use only part of the functionality?**
Yes. Choose L1 for core hooks + a few skills only. L0 has zero Gates. Re-run `/onboard` to adjust.

**Q: How does multi-person collaboration work?**
Each person deploys the base files locally. OpenSpec changes share the same lifecycle as Git branches. Spec files are committed alongside code — the whole team shares them.

**Q: What if I haven't installed all the skills/MCPs?**
Run `/diagnose` to see what's missing and get install commands. Installed skills continue working normally regardless.

---

## Version

v1.0.0 — 2026-05-08
