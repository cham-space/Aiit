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
