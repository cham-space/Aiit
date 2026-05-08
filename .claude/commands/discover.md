# /discover [idea]

Start Phase 1: Discover — turn your idea into a structured PRD spec.

## Usage
```
/discover Build a user login system with OAuth2 support
/discover Add dark mode toggle to the settings
```

## What happens
1. `brainstorming` skill activates to clarify your intent
2. Explores constraints, success criteria, edge cases
3. Proposes 2-3 implementation approaches
4. Outputs a structured PRD spec to `specs/prd/<change-id>.md`
5. Runs PRD Completeness + Testability gates

## After /discover
Your PRD spec is created. Review it, then the system auto-transitions to Phase 2 (Plan).
