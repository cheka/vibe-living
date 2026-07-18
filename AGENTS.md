# Repository guidance

## Spec-first development

- Before implementing any new requirement, update the relevant specification under `docs/specs/`.
- Define scope, non-goals, acceptance criteria, and verification before editing implementation code.
- If implementation discoveries change expected behavior, update the specification first, then continue coding.
- Run the local Harness and relevant checks before handing off a change.
- Commit every completed modification before handoff; use a focused Conventional Commit and leave the worktree clean unless the user explicitly requests otherwise.

## Product boundaries

- Keep Vibe Living local-first and offline by default.
- Do not read prompts, transcripts, tool inputs, tool outputs, or repository files.
- Do not add telemetry without an explicit public design discussion and opt-in consent.
- Treat movement copy as optional general activity guidance, never medical advice or a health-outcome claim.
- Keep movements quiet, low-amplitude, equipment-free, and within one person's desk space; never add jumping, marching, deep squats, fast arm swings, or shared-walkway activities.
- A hook failure must never block or alter an agent action.
- Keep every runtime design asset, published screenshot, and official documentation image in the repository. Declare plugin assets in `plugins/vibe-living/assets/manifest.json`; temporary QA frames must never be referenced by shipped code or documentation.

## Development

- Run `make check` before handing off a change.
- Keep Codex and Claude Code manifest versions aligned.
- Update tests when lifecycle or state behavior changes.
- Update both English and Simplified Chinese user-facing documentation when behavior changes.
- Rebuild the bundled helper after modifying `VibeLiving.swift`.
