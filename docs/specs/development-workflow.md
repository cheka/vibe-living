# Development workflow specification

## Purpose

Keep product intent, implementation, and verification aligned as Vibe Living evolves.

## Required sequence

Every requirement must follow this order:

1. Inspect the repository and identify the affected specification.
2. Add or update the specification under `docs/specs/`.
3. Define observable acceptance criteria and the verification method.
4. Implement the smallest change that satisfies the specification.
5. Run the Harness and relevant automated checks.
6. Update user-facing documentation and the changelog when behavior changes.
7. Commit the completed change before handing the requirement back.

Implementation must not start before steps 1–3 are complete. A requirement is not complete when only code or only documentation has changed.

## Specification contents

Each behavioral specification must state:

- context and user problem;
- in-scope behavior;
- non-goals and safety boundaries;
- acceptance criteria;
- automated and manual verification expectations.

Small changes may update an existing specification. A new subsystem or independently testable behavior should receive its own file.

## Traceability

- Code and tests should use the same terminology as their specification.
- A pull request must name the affected spec file.
- If acceptance criteria change during implementation, the spec changes first.
- Emergency fixes still require a spec delta that records the intended behavior before the fix is implemented.
- Every completed requirement must end in at least one focused local Git commit.
- Use Conventional Commit-style messages and keep unrelated requirements in separate commits.
- The worktree must be clean at handoff unless the user explicitly asks to leave a change uncommitted.

## Acceptance criteria

- `AGENTS.md` and `CONTRIBUTING.md` require the spec-first sequence.
- The repository provides an index of active specifications.
- `make check` verifies that required specification files exist.
- CI runs the same checks developers run locally.
- Completed modifications are committed locally before handoff.
