---
name: openspec
description: OpenSpec operations — init, validate, diff, archive. Use when working with specs, checking spec-code consistency, or archiving completed changes.
---

# OpenSpec Skill

## Operations

### init
Initialize the project spec directory structure.

```bash
openspec init
```

Creates `specs/` with subdirectories: prd/, api/, design/, test/, release/ and standard templates for each spec type.

### validate
Validate a spec file for format completeness and schema compliance.

```bash
openspec validate specs/prd/<change-id>.md
openspec validate specs/api/<change-id>.yaml
openspec validate specs/plan/<change-id>.md
```

Returns: list of missing fields, format errors, or "PASS".

### diff
Detect drift between implementation and spec.

```bash
openspec diff specs/plan/<change-id>.md
```

Returns: list of spec items not covered by implementation, or "ALIGNED".
Drift severity: LOW (<10% uncovered) → WARNING, MEDIUM (10-30%) → ALERT, HIGH (>30%) → BLOCKING.

### archive
Archive a completed change.

```bash
openspec archive <change-id>
```

Moves all specs + verification report + release note to `archive/<change-id>/`. Updates CLAUDE.md active changes list.

## Phase Mapping

| Phase | Operation | Trigger |
|-------|-----------|---------|
| 0 | init | Manual first time |
| 1 | validate (PRD) | Pre-spec-commit hook |
| 2 | validate (plan) | Post-plan hook |
| 3 | diff | Post-write hook (every file save) |
| 4 | validate (final) | Verification step 7 |
| 5 | archive | Post-merge hook |
