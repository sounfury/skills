---
name: debug-spec-first
description: "Spec-first debugging workflow for software projects. Use when users ask to debug bugs, regressions, or behavior mismatches and the project has system analysis/specification documents (usually in spec/). Enforce this order: read spec first, map requirement to code, propose at least two fix plans with file-level impact and scope, wait for user selection, implement on a new branch from the current development branch, validate, then write accepted changes back to spec docs. Treat spec docs as the highest source of truth."
---

# Debug Spec First

Follow this workflow strictly and in order.

## 1) Read Spec Docs First

- Locate system analysis/spec docs, usually under `spec/`.
- Extract architecture boundaries, module responsibilities, and expected behavior.
- Treat spec docs as the highest source of truth.
- Stop implementation and ask for clarification if spec docs are missing or contradictory.

## 2) Analyze Requirement and Read Relevant Code

- Restate the user-reported issue and expected behavior according to spec.
- Read only relevant code paths first: entrypoint, core logic, data boundary, and tests.
- Identify likely root causes, unknowns, and verification targets.

## 3) Provide At Least Two Debug Plans

Before coding, present a numbered option menu (`1`, `2`, ...).  
For each plan, include:

- Core idea.
- File-level change list (`path` + planned change).
- Scope assessment (`small` / `medium` / `large`).
- Risk and regression surface.
- Validation approach.

Then provide one recommended plan and explain why.

## 4) Wait for User Choice, Then Implement on a New Branch

- Do not code before the user selects a plan.
- Before any implementation, sync the latest remote development branch code (`git fetch` + fast-forward pull/rebase of the development branch) and confirm local base is up to date.
- Detect current development branch.
- Create and switch to a new branch from that up-to-date development branch.
- Implement the chosen plan with minimal, spec-aligned changes.

## 5) Validate and Write Back to Spec Docs

- Run required checks/tests and verify the target bug path end-to-end.
- After acceptance, update spec docs with the final behavior and impacted modules.
- Keep code and spec consistent at all times.

## Response Template

Use this output structure for debugging tasks:

1. `Spec Summary`
2. `Code Path Analysis`
3. `Plan 1`
4. `Plan 2`
5. `Recommendation`
6. `Choose Plan`

After user selection:

1. `Implementation Branch`
2. `Code Changes`
3. `Validation`
4. `Spec Updates`
