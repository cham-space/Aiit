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
