# /onboard

Interactive project setup — configure your role and enablement level.

## Flow

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
