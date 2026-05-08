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
