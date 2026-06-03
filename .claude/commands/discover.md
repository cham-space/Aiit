---
description: "Transform an idea into a structured OpenSpec PRD spec, tracked as a change lifecycle entry"
argument-hint: "[brief idea or requirement description]"
---

# /discover: Start Phase 1 -- From Idea to OpenSpec PRD Spec

## Mission

Transform a vague idea, feature request, or problem statement into a concrete, reviewable OpenSpec PRD spec at `specs/prd/<change-id>.md`. This command is the single entry point for Phase 1 (Discover). It ensures every change begins life as a properly structured spec tracked by the OpenSpec change lifecycle, with mandatory gates proving it is complete and testable before it advances.

## Core Principle

**No spec, no code.** Every code change -- from a one-line fix to a new feature -- must originate from a PRD spec that passes completeness and testability gates. Verbal descriptions, chat history, and issue titles are not specs. The PRD file is the source of truth for what must be built and why.

## Process

### Step 0: Entry Gate -- Determine Path

Before any brainstorming, check which path applies:

**Path A -- Existing PRD Spec Found**
- Condition: `specs/prd/<change-id>.md` already exists and is in `proposed` status.
- Action: Validate the existing PRD against current requirements (does it still match the ask?). If aligned, proceed directly to Step 4 (Gates). If stale, treat as Path B with the existing spec as context.

**Path B -- New Idea (default)**
- Condition: No existing PRD, or user provides a fresh idea.
- Action: Execute the full discovery flow starting from Step 1.

### Step 1: Brainstorming (Skill: `brainstorming`)

Activate the `brainstorming` skill. This is a structured conversation, not a free-form chat. It must elicit:

1. **Problem & Motivation** -- What problem are we solving? Why now? Who benefits?
2. **Success Criteria** -- What does "done" look like? What measurable outcome defines success?
3. **Constraints & Boundaries** -- What is explicitly in scope? What is explicitly out of scope? Technical constraints? Time constraints? Dependency constraints?
4. **User Stories** -- At least 2 user stories in the format: "As a [role], I want [goal], so that [reason]."
5. **Edge Cases & Failure Modes** -- What happens when things go wrong? Empty state? Error state? Rate limit exceeded? Concurrent access?
6. **Non-Functional Requirements** -- Performance targets, security considerations, accessibility requirements, browser/device support.

### Step 2: Propose Approaches

Based on the elicited requirements, propose 2-3 implementation approaches with:
- A one-paragraph summary of each approach
- Trade-offs table (complexity vs. flexibility, build vs. buy, timeline impact)
- Recommended approach with justification

User must explicitly select or reject each approach. Do not proceed until the user confirms one.

### Step 3: Write the PRD Spec

Write `specs/prd/<change-id>.md` with ALL of the following mandatory sections:

1. **Overview & Background** -- What problem this solves, why it matters, context.
2. **Goals & Non-Goals** -- Bulleted lists. Goals are concrete deliverable outcomes. Non-goals are things explicitly excluded to prevent scope creep.
3. **User Stories** -- Minimum 2, each with acceptance criteria that contain quantifiable elements (numbers, percentages, time thresholds, specific states).
4. **Technical Constraints & Dependencies** -- Technology choices, library versions, API dependencies, upstream/downstream systems affected.
5. **Success Metrics** -- How we will measure success after deployment (e.g., "p99 latency < 200ms", "error rate < 0.1%", "user completion rate > 90%").
6. **Acceptance Criteria** -- A dedicated section with a numbered checklist of quantifiable, testable pass/fail conditions extracted from the user stories.
7. **Change Metadata** -- `change-id`, `status: proposed`, `created-at`, `author`.

The `<change-id>` format: `YYYYMMDD-<kebab-case-slug>` (e.g., `20260507-user-oauth2-login`).

### Step 4: Run Phase 1 Gates

Execute `run_phase_gates 1 "<change-id>"` from `.githooks/lib/gates.sh`. This runs:

| Gate | What It Checks |
|------|----------------|
| `gate_prd_completeness` | All 5 required section patterns present (Overview, Goals, User Stories, Constraints, Success Metrics) |
| `gate_testability` | Acceptance criteria contain quantifiable elements (numbers, percentages, durations, thresholds) |

If either gate fails, return to Step 3 and rewrite the missing sections. Do NOT skip gates. Do NOT override them from this command.

### Step 5: Commit the PRD

Once all Phase 1 gates pass:
```
git add specs/prd/<change-id>.md
git commit -m "spec: add PRD for <change-id> -- <brief summary>"
```

The commit-msg hook (`conventional commit` format) will validate the message. The change is now in `proposed` status.

### Step 6: Initialize State Tracking

After the PRD is committed, initialize the state tracking file for this change:

```bash
# Initialize .aiit.yaml for this change
bash .claude/scripts/aiit-state.sh init "<change-id>"
```

This creates `specs/<change-id>/.aiit.yaml` with:
- `phase: discover`
- `workflow: full`
- `archived: false`

Verify the state was initialized:
```bash
bash .claude/scripts/aiit-state.sh list
```

Commit the state file:
```bash
git add specs/<change-id>/.aiit.yaml
git commit -m "chore: initialize state tracking for <change-id>"
```

## Hard Gate

Both `gate_prd_completeness` and `gate_testability` must return PASS before this command considers itself complete. The change must be committed with status `proposed`. If the PRD has fewer than 2 user stories with quantifiable acceptance criteria, or if any mandatory section is missing, the command is not done. Do not hand off to Phase 2 (Plan) until these conditions are satisfied.

## Output

```
specs/prd/<change-id>.md
```

A complete, committed PRD spec with status `proposed`, containing:
- All 7 mandatory sections (Overview, Goals & Non-Goals, User Stories, Constraints, Success Metrics, Acceptance Criteria, Metadata)
- Minimum 2 user stories with quantifiable acceptance criteria
- Phase 1 gate results: PRD Completeness PASS, Testability PASS
