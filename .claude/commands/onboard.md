---
description: "Interactive progressive setup from zero to configured -- role-aware routing, openspec init, CLAUDE.md auto-generation"
argument-hint: "[no arguments -- interactive flow]"
---

# /onboard: Interactive Project Setup -- Role, Level, and Config Generation

## Mission

Guide a new user (or re-configure an existing user) through a progressive, role-aware, three-question onboarding flow that sets up the AI Development Base from scratch or reconfigures an existing project. This command runs `openspec init` to create the spec directory scaffold, deploys the `.claude/` configuration (settings, commands, skills), generates a custom CLAUDE.md tailored to the user's role and level, activates git hooks via `git config core.hooksPath .githooks`, and finishes with an automatic `/diagnose` validation run to confirm everything is healthy.

## Core Principle

**Progressive disclosure with role-aware routing.** Not every user needs every capability. The three-question flow (Role -> Project State -> Level) deterministically routes each user to the exact setup path they need -- no more and no less. CLAUDE.md is generated dynamically from the answers, not copied from a static template. The result is a personalized AI context that reflects the specific developer, their role, and their access level.

## Process

### Step 1: Entry -- Identify Role

Present Question 1:

> **What is your primary role on this project?**
>
> 1. **Product Manager / Designer** -- You define what gets built. You work in Discover phase: brainstorm requirements, write PRD specs, create design briefs. You hand off specs to developers for implementation.
> 2. **Developer** -- You build it. You receive PRD specs and plans, then execute (TDD), verify, and release. You work across Plan -> Execute -> Verify -> Release phases.
> 3. **Full-stack Independent** -- You do everything end-to-end. You discover, plan, execute, verify, and release. Full pipeline access across all 5 phases.
> 4. **Maintenance / On-call** -- You fix things. You use hotfix and diagnostic tools. You work at L0-L1: targeted fixes and health checks.

Capture the answer as `$ROLE`.

### Step 2: Identify Project State

Present Question 2:

> **What is the current state of this project?**
>
> 1. **Brand new project** -- Empty directory or newly cloned. Need full initialization: `openspec init`, config deployment, CLAUDE.md generation.
> 2. **Existing project without AI Dev Base** -- Has code but no `.claude/`, `specs/`, or `.githooks/`. Need to retrofit the base structure.
> 3. **Existing project with AI Dev Base** -- Already has `.claude/`, `specs/`, `.githooks/`. Need to reconfigure role, level, or regenerate CLAUDE.md.

Capture the answer as `$PROJECT_STATE`.

### Step 3: Identify Enablement Level

Present Question 3:

> **What level of automation do you want?**
>
> | Level | What You Get |
> |-------|-------------|
> | **L0 Hotfix** | Zero config. `/hotfix` and `/diagnose` only. Secret scan + format on commit. No TDD requirement. No MCPs. |
> | **L1 Light** | Individual developer. Core skills (TDD, code-review, verification). Pre-commit hooks (format, lint, type-check, secret-scan). TypeScript LSP and Serena MCPs. No parallel agents. |
> | **L2 Standard** | Team workflow (RECOMMENDED). Full skill chain (brainstorming, writing-plans, executing-plans, TDD, subagent, code-review, verification, release). All pre-commit and pre-push hooks. All 4 MCPs (Playwright, Figma, Serena, TS LSP). Parallel agents. Full gate enforcement. |
> | **L3 Full** | Enterprise. Everything in L2 plus: design-brief-builder skill, quality metrics collection, feedback loop (capture manual fixes -> evolve rules/templates), auto-archive. |

Capture the answer as `$LEVEL`.

### Step 4: Routing Table -- Execute Setup

Based on `$ROLE` + `$PROJECT_STATE` + `$LEVEL`, execute the appropriate setup path:

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
2. Regenerating CLAUDE.md
3. Re-running Phase 0 gates to confirm everything is still healthy

### Step 5: Generate CLAUDE.md

Based on `$ROLE` + `$LEVEL`, generate `.claude/CLAUDE.md` dynamically. Do not copy a static template. The file must include:

```markdown
# Project: <project-name>

## Overview
<Auto-detected from package.json / pyproject.toml / go.mod, or user-supplied>

## Role & Level
- Role: <$ROLE>
- Level: <$LEVEL> (<level-name>)
- Setup Date: <timestamp>

## Commands I Can Use
<Available commands per level from settings.json>

## Build & Test
<Auto-detected or user-supplied: npm test, pytest, go test, etc.>

## Active Changes
<Scanned from specs/ -- list of change-id with status>

## Architecture
<Auto-detected: language, framework, key directories>

## Constraints
- NEVER skip gates
- TDD required: <yes/no per level>
- Parallel agents: <yes/no per level>
- File scope enforcement: <yes/no>
- Spec drift detection: <yes/no>

## MCP Servers Available
<List from settings.json level config>

## Skills Available
<List from settings.json level config>
```

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

- CLAUDE.md is present and well-structured
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
- CLAUDE.md MUST be generated and committed
- `/diagnose` MUST run and produce a pass/fail report (failures must include remediation steps)
- Git hooks MUST be active (`git config core.hooksPath` = `.githooks`)

## Key Differences from Other Base Systems

AICAM and similar bases copy a static CLAUDE.md template and require manual config file editing. THIS `/onboard`:

- Runs **`openspec init`** to create the spec directory scaffold (not a manual mkdir)
- **Generates CLAUDE.md dynamically** from the user's role, level, and project state -- it is always customized
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
