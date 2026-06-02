---
description: "Interactive progressive setup from zero to configured -- role-aware routing, openspec init, .claude/CLAUDE.md auto-generation"
argument-hint: "[no arguments -- interactive flow]"
---

# /onboard: Interactive Project Setup -- Role, Level, and Config Generation

## Mission

Guide a new user (or re-configure an existing user) through a progressive, role-aware, three-question onboarding flow that sets up the AI Development Base from scratch or reconfigures an existing project. This command runs `openspec init` to create the spec directory scaffold, deploys the `.claude/` configuration (settings, commands, skills), generates a custom `.claude/CLAUDE.md` tailored to the user's role and level, activates git hooks via `git config core.hooksPath .githooks`, and finishes with an automatic `/diagnose` validation run to confirm everything is healthy.

## Core Principle

**Progressive disclosure with role-aware routing.** Not every user needs every capability. The four-question flow (Language -> Role -> Project State -> Level) deterministically routes each user to the exact setup path they need -- no more and no less. All subsequent prompts, commands, and generated files adapt to the chosen language. `.claude/CLAUDE.md` is generated dynamically from the answers, guided by `.claude/templates/CLAUDE.md.template`.

## Process

### Step 0: Language Selection (MANDATORY — always first)

Before any other questions, present Language Selection:

> **Choose your language / 请选择语言：**
>
> 1. **English** — All prompts, command output, and generated documentation will be in English.
> 2. **中文** — 所有提示、命令输出和生成的文档将使用中文。

Capture the answer as `$LANG`. Set all subsequent prompts to use `$LANG`.

**Effect:** Every question from this point on is displayed in `$LANG`. Generated `.claude/CLAUDE.md` section headers, WORKFLOW.md references, command descriptions, and error messages all adapt to `$LANG`. The README.md and README.zh.md / README.en.md guide files already exist in both languages — reference the appropriate one based on `$LANG`.

### Step 1: Entry -- Identify Role

Present Question (in `$LANG`):

> **EN:** What is your primary role on this project?
> **ZH:** 你在这个项目中的主要角色是什么？
>
> 1. **Product Manager / Designer (产品经理/设计师)** — Define requirements, write PRD specs, create design briefs. Work in Discover phase (Phase 1). Hand off specs to developers.
> 2. **Developer (开发工程师)** — Receive PRD specs and plans, execute (TDD), verify, release. Work across Plan → Execute → Verify → Release phases (Phase 2-5).
> 3. **Full-stack Independent (全栈独立)** — Do everything end-to-end. Full pipeline across all 5 phases.
> 4. **Maintenance / On-call (维护/值班)** — Fix things via hotfix and diagnostics. Work at L0-L1.

Capture the answer as `$ROLE`.

### Step 2: Identify Project State

Present Question (in `$LANG`):

> **EN:** What is the current state of this project?
> **ZH:** 当前项目处于什么状态？
>
> 1. **Brand new project (全新项目)** — Empty directory or newly cloned. Need full initialization: `openspec init`, config deployment, `.claude/CLAUDE.md` generation.
> 2. **Existing project without AI Dev Base (已有项目，未接入基座)** — Has code but no `.claude/`, `specs/`, or `.githooks/`. Need to retrofit the base structure.
> 3. **Existing project with AI Dev Base (已有项目，已接入基座)** — Already has `.claude/`, `specs/`, `.githooks/`. Need to reconfigure role, level, or regenerate `.claude/CLAUDE.md`.

Capture the answer as `$PROJECT_STATE`.

### Step 3: Identify Enablement Level

Present Question (in `$LANG`):

> **EN:** What level of automation do you want?
> **ZH:** 你希望启用哪个自动化级别？
>
> | Level | Capabilities / 能力范围 |
> |-------|------------------------|
> | **L0 Hotfix (急救)** | Zero config. `/hotfix` and `/diagnose` only. Secret scan + format on commit. No TDD requirement. No MCPs. |
> | **L1 Light (轻量)** | Individual developer. Core skills (TDD, code-review, verification). Pre-commit hooks (format, lint, type-check, secret-scan). TypeScript LSP and Serena MCPs. No parallel agents. |
> | **L2 Standard (标准，推荐)** | Team workflow (RECOMMENDED). Full skill chain. All pre-commit and pre-push hooks. All 4 MCPs. Parallel agents. Full gate enforcement. |
> | **L3 Full (全量)** | Enterprise. Everything in L2 plus: quality metrics collection, feedback loop (auto-evolve rules/templates), auto-archive. |

Capture the answer as `$LEVEL`.

### Step 4: Routing Table -- Execute Setup

Based on `$LANG` + `$ROLE` + `$PROJECT_STATE` + `$LEVEL`, execute the appropriate setup path.

#### Step 4.0: Prerequisite Check & Installation Guide

Before deploying config files, check which required components are available for the selected `$LEVEL`. Display the results in `$LANG`:

| Component | How to Check | L0 | L1 | L2 | L3 |
|-----------|-------------|----|----|----|----|
| Claude Code | `claude --version` | ✓ | ✓ | ✓ | ✓ |
| OpenSpec CLI | `openspec --version` | — | ✓ | ✓ | ✓ |
| Superpowers plugin | Check `~/.claude/plugins/installed_plugins.json` for `superpowers` | — | ✓ | ✓ | ✓ |
| Figma plugin | Check `installed_plugins.json` for `figma` | — | — | ✓ | ✓ |
| TS LSP MCP | `claude mcp list` shows `typescript-lsp` | — | ✓ | ✓ | ✓ |
| Serena MCP | `claude mcp list` shows `serena` | — | ✓ | ✓ | ✓ |
| Playwright MCP | `claude mcp list` shows `playwright` | — | — | ✓ | ✓ |
| gitleaks | `command -v gitleaks` | — | — | — | ✓ |
| semgrep | `command -v semgrep` | — | — | — | ✓ |
| oasdiff | `command -v oasdiff` | — | — | ✓ | ✓ |

For each missing required component, output the installation command in `$LANG`:
- **EN:** "Missing: `<component>`. Install: `<command>`"
- **ZH:** "缺失：`<component>`。安装方式：`<command>`"

After displaying all missing items, apply the following blocking rules based on component type:

**HARD BLOCK (must install before proceeding, no override):**
- **OpenSpec CLI** is missing and level is L1+: Stop immediately. Output:
  - EN: "❌ BLOCKED: OpenSpec CLI is required for L1+. Install it first: `npm install -g @fission-ai/openspec`. Re-run `/onboard` after installation."
  - ZH: "❌ 已阻断：L1+ 必须安装 OpenSpec CLI。请先执行：`npm install -g @fission-ai/openspec`，安装后重新运行 `/onboard`。"
  - Do NOT proceed. Do NOT deploy any config files. Exit the command.

**SOFT WARN (optional, user may continue with degraded functionality):**
- Missing MCPs (Serena, TypeScript LSP, Figma, Playwright): warn, offer install commands, allow user to continue.
- Missing gitleaks / semgrep / oasdiff: warn, allow user to continue.

After soft-warn items, ask:
- **EN:** "Install optional components now, or continue with limited functionality?"
- **ZH:** "现在安装可选组件，还是以受限功能继续？"

#### Path: Project Init (PROJECT_STATE = "brand new" or "existing without base")

**4a. Run `openspec init`**

```
openspec init
```

This creates:
- `specs/` directory with standard OpenSpec templates
- `specs/prd/` -- PRD spec directory
- `specs/plan/` -- implementation plan directory
- `specs/api/` -- API contract directory
- `specs/design/` -- design spec directory
- `specs/test/` -- test strategy directory
- `specs/release/` -- release/verification report directory

**4b. Deploy `.claude/` Configuration**

If the `.claude/` directory does not exist or is incomplete:

1. Ensure `.claude/commands/` contains all 6 command files: `discover.md`, `execute.md`, `hotfix.md`, `diagnose.md`, `close-phase.md`, `onboard.md`
2. Ensure `.claude/settings.json` exists with the standard permission baseline and hook configuration
3. Ensure `.claude/WORKFLOW.md` is present as the project handbook reference
4. Ensure `.claude/skills/` directory exists (custom skills, if any)

**4c. Deploy `.githooks/` and Activate**

1. Ensure `.githooks/` directory exists with: `pre-commit`, `commit-msg`, `pre-push`, `config`, `lib/gates.sh`, `lib/l2-checks.sh`, `lib/utils.sh`
2. Make all hook scripts executable:
   ```
   chmod +x .githooks/pre-commit .githooks/commit-msg .githooks/pre-push .githooks/lib/*.sh
   ```
3. Activate hooks:
   ```
   git config core.hooksPath .githooks
   ```

**4d. Run Phase 0 Gates**

```
run_phase_gates 0 ""
```

Verify:
- `gate_directory_structure` -- `specs/`, `.claude/`, `.githooks/` all exist
- `gate_hook_activation` -- `core.hooksPath` is `.githooks`, hook scripts are executable

#### Path: Reconfigure (PROJECT_STATE = "existing with base")

Skip `openspec init` and hook deployment. Focus on:
1. Updating `settings.json` with the new role and level
2. Regenerating `.claude/CLAUDE.md`
3. Re-running Phase 0 gates to confirm everything is still healthy

### Step 5: Generate .claude/CLAUDE.md

Read the generation rules from `.claude/templates/CLAUDE.md.template`, then based on `$LANG` + `$ROLE` + `$LEVEL`, generate `.claude/CLAUDE.md` dynamically.

**Core principle**: `.claude/CLAUDE.md` is a **project knowledge file**. It tells Claude what this project IS — its tech stack, build commands, architecture, code patterns, and testing rules. Aiit toolchain metadata (commands, MCP servers, skills, gate constraints) MUST NOT appear — Claude already perceives these through system prompts and `settings.json`.

The file MUST include these sections:

```markdown
# <project-name>

## Project Overview
<One paragraph describing the project — auto-detected from ecosystem files or user-supplied>

## Tech Stack
| Technology | Purpose |
|------------|---------|
| {framework} | {why it's used} |
<!-- FRAMEWORKS only, not individual libraries -->

## Build & Test Commands
\`\`\`bash
# Build
{build-command}
# Test
{test-command}
# Lint (if applicable)
{lint-command}
\`\`\`

## Project Structure
<!-- ≤15 lines tree format, key directories only -->
\`\`\`
{root}/
├── {dir}/     # {description}
└── {dir}/     # {description}
\`\`\`

## Architecture
<!-- 1-2 paragraphs: architecture style + key data flow -->

## Code Patterns
### Naming
- {convention}
### Error Handling
- {approach summary}
### Simplicity First
- Write minimum code for current spec — no speculative features
- No abstractions unless reused in ≥2 places
### Surgical Changes
- Touch only what the request requires — match existing style
- Remove imports/variables made unused by YOUR changes only

## Testing
- **Unit tests**: `{unit-test-command}`
- **Integration tests**: `{integration-test-command}`
- **Single file**: `{targeted-test-command}`

### Phase Testing Gates (MANDATORY)
| Gate | Trigger | Requirement |
|------|---------|-------------|
| Unit Tests | New logic added | Min 1 test per non-trivial function |
| Zero Regression | Always | Full test suite passes |
<!-- Add project-specific gates as needed -->

## Key Files
| File | Purpose |
|------|---------|
| `{path}` | {1-line description} |
<!-- ≤10 entries, only files defining the project's shape -->

## Active Changes
<!-- Scanned from specs/prd/ — list change-id with status -->

## On-Demand Context
| Topic | File | When to Read |
|-------|------|-------------|
| Spec drift guide | .claude/reference/spec-drift-guide.md | openspec diff shows drift |
| Test strategies | .claude/reference/test-strategies/ | Writing tests |
<!-- Only include files that actually exist -->

## Safety Rules
### Secrets & Credentials
- Never commit `.env*`, `*.key`, `*.pem`, credential files
### Git Operations
- Confirm before `git push`; avoid destructive commands
### Data & Schema
- Summarize migration impact before running; wait for confirmation
### Dependencies
- Explain reason + breaking-change risk before adding/upgrading

## Known Issues & Deferred Risks
| ID | Description | Source | Archive Ref | Status |
|----|-------------|--------|-------------|--------|
```

The file MUST NOT include:
- Role & Level (stored in settings.json)
- Available Commands (`/discover`, `/execute`, etc. — auto-discovered by Claude)
- Constraints / Gate rules (enforced by settings.json + hooks)
- Available MCP Servers (auto-discovered by Claude)
- Available Skills (auto-discovered by Claude)

### Step 6: Update settings.json

Write the selected role and level into `.claude/settings.json`:

```json
{
  "enableLevel": "<L0/L1/L2/L3>",
  "role": "<pm-design/dev/full-stack/maintenance>",
  "projectLanguage": "<detected or user-supplied>",
  "projectFramework": "<detected or user-supplied>"
}
```

Merge with existing settings (do not overwrite permissions or hooks).

### Step 7: Commit Onboarding Artifacts

```
git add .claude/CLAUDE.md
git add .claude/settings.json
git add specs/
git commit -m "chore: onboarding -- role=<$ROLE>, level=<$LEVEL>"
```

### Step 8: Auto-Run /diagnose

After setup is complete, automatically invoke `/diagnose` to produce a health report validating that:

- `.claude/CLAUDE.md` is present and well-structured
- All 3 required directories exist
- Git hooks are active
- Security tooling is available (or installation instructions are provided)
- MCP servers are reachable
- Skills inventory is complete
- Phase 0 gates all pass

Present the diagnostic summary. If any checks fail, provide remediation steps.

## Role-Specific Post-Setup Instructions

After `/diagnose` passes, provide role-specific next-step instructions:

**Product Manager / Designer:**
```
You're all set. To create a new spec:
  /discover "Describe your feature idea here"

Your PRD specs will be written to specs/prd/<change-id>.md.
Developers on this project can then plan and execute from your spec.
```

**Developer:**
```
You're all set. To start implementing a planned change:
  /execute <change-id>

If this is a new project with no specs yet, coordinate with your
PM/Designer to create a PRD spec first via /discover.
```

**Full-stack Independent:**
```
You're all set. Your full pipeline:
  /discover "Your idea"  -->  PRD spec
  (Phase 2 auto-transitions to plan)
  /execute <change-id>   -->  TDD implementation
  /close-phase <change-id> --> archive

Start with /discover to create your first spec.
```

**Maintenance / On-call:**
```
You're all set. Your toolkit:
  /diagnose  -- check system health
  /hotfix "bug description"  -- emergency fix

For anything larger, suggest /discover to the team.
```

## Hard Gate

Before this command reports success:
- `openspec init` MUST complete (for new projects)
- `run_phase_gates 0` MUST return all PASS (Directory Structure + Hook Activation)
- `.claude/CLAUDE.md` MUST be generated and committed
- `/diagnose` MUST run and produce a pass/fail report (failures must include remediation steps)
- Git hooks MUST be active (`git config core.hooksPath` = `.githooks`)

## Key Differences from Other Base Systems

AICAM and similar bases copy a static CLAUDE.md template and require manual config file editing. THIS `/onboard`:

- Reads generation rules from **`.claude/templates/CLAUDE.md.template`** (not auto-loaded by Claude Code)
- Runs **`openspec init`** to create the spec directory scaffold (not a manual mkdir)
- **Generates `.claude/CLAUDE.md` dynamically** from the user's role, level, and project state -- it is always customized
- **Deploys `.claude/` config** as part of the flow, not as a separate pre-requisite
- **Auto-runs `/diagnose`** as a post-setup validation step, surfacing issues immediately
- Uses **3-question progressive routing** (Role -> State -> Level) rather than a flat config form

## Output

```
## Onboarding Complete

### Configuration
- Role: <$ROLE>
- Level: <$LEVEL>
- Project State: <$PROJECT_STATE>

### Generated Files
- .claude/CLAUDE.md (custom generated)
- .claude/settings.json (updated)
- specs/ (OpenSpec scaffold via openspec init)

### Gates Passed
- Phase 0: <gate_directory_structure: PASS, gate_hook_activation: PASS>

### Diagnostic Summary
<Abbreviated /diagnose output>

### Next Steps
<Role-specific instructions as described in Step 8>
```
