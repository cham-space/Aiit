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
