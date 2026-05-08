# /diagnose [symptom]

Investigate an issue without making changes — analysis only.

## Usage
```
/diagnose Why is the API returning 500 when user has no avatar?
/diagnose Check why build is failing on CI but passes locally
```

## What happens
1. Activates `systematic-debugging` in diagnostic mode
2. Reads logs, traces code paths, checks recent changes
3. Outputs root cause analysis + recommended fix approach
4. Does NOT modify any files

## After /diagnose
- If emergency → `/hotfix`
- If feature/change → `/discover` to create a proper PRD
